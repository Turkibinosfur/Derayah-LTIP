-- Link performance metrics directly to grants
CREATE TABLE grant_performance_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  grant_id uuid NOT NULL REFERENCES grants(id) ON DELETE CASCADE,
  performance_metric_id uuid NOT NULL REFERENCES performance_metrics(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (grant_id, performance_metric_id)
);

CREATE INDEX idx_grant_performance_metrics_grant ON grant_performance_metrics (grant_id);
CREATE INDEX idx_grant_performance_metrics_metric ON grant_performance_metrics (performance_metric_id);

ALTER TABLE grant_performance_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view grant performance metrics"
  ON grant_performance_metrics FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage grant performance metrics"
  ON grant_performance_metrics FOR ALL
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  );

-- Optional backfill: copy plan-level links to active grants using those plans
INSERT INTO grant_performance_metrics (company_id, grant_id, performance_metric_id)
SELECT
  g.company_id,
  g.id,
  pmp.performance_metric_id
FROM performance_metric_plan_links pmp
JOIN incentive_plans ip ON ip.id = pmp.plan_id
JOIN grants g ON g.plan_id = ip.id
ON CONFLICT (grant_id, performance_metric_id) DO NOTHING;

-- Update process_vesting_event to validate using grant-level links
CREATE OR REPLACE FUNCTION process_vesting_event(
  p_vesting_event_id uuid,
  p_processed_by uuid DEFAULT auth.uid(),
  p_fair_market_value numeric DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_event vesting_events%ROWTYPE;
  v_grant grants%ROWTYPE;
  v_plan incentive_plans%ROWTYPE;
  v_requires_performance boolean := false;
  v_result jsonb := '{}';
BEGIN
  -- Get vesting event
  SELECT * INTO v_event FROM vesting_events WHERE id = p_vesting_event_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Vesting event not found');
  END IF;

  -- Check if event is due
  IF v_event.status NOT IN ('due', 'pending') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Event is not due for processing');
  END IF;

  -- Get grant
  SELECT * INTO v_grant FROM grants WHERE id = v_event.grant_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Grant not found for vesting event');
  END IF;

  -- Determine if the grant has performance metrics that require confirmation
  SELECT EXISTS (
    SELECT 1
    FROM grant_performance_metrics gpm
    WHERE gpm.grant_id = v_grant.id
      AND gpm.company_id = v_event.company_id
  ) INTO v_requires_performance;

  -- Prevent vesting if performance conditions are not met for grants with linked metrics
  IF v_event.event_type IN ('performance', 'performance_based', 'hybrid')
     AND v_requires_performance
     AND NOT COALESCE(v_event.performance_condition_met, false) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Performance condition not confirmed');
  END IF;

  -- Get plan details for response payloads
  SELECT * INTO v_plan FROM incentive_plans WHERE id = v_grant.plan_id;

  -- Update vesting event status
  UPDATE vesting_events 
  SET 
    status = 'vested',
    processed_at = now(),
    processed_by = p_processed_by,
    fair_market_value = p_fair_market_value,
    updated_at = now()
  WHERE id = p_vesting_event_id;

  -- Update grant vested shares
  UPDATE grants 
  SET 
    vested_shares = vested_shares + v_event.shares_to_vest,
    updated_at = now()
  WHERE id = v_event.grant_id;

  v_result := jsonb_build_object(
    'success', true,
    'event_id', v_event.id,
    'shares_vested', v_event.shares_to_vest,
    'plan_type', v_plan.plan_type,
    'requires_exercise', v_plan.plan_type = 'ESOP'
  );

  RETURN v_result;
END;
$$;

-- Clean up legacy plan-level links if no longer needed
DROP TABLE IF EXISTS performance_metric_plan_links;

