-- Link performance metrics to incentive plans to support multi-plan associations
CREATE TABLE performance_metric_plan_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  performance_metric_id uuid NOT NULL REFERENCES performance_metrics(id) ON DELETE CASCADE,
  plan_id uuid NOT NULL REFERENCES incentive_plans(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (performance_metric_id, plan_id)
);

CREATE INDEX idx_performance_metric_plan_links_metric ON performance_metric_plan_links (performance_metric_id);
CREATE INDEX idx_performance_metric_plan_links_plan ON performance_metric_plan_links (plan_id);

ALTER TABLE performance_metric_plan_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view performance metric plan links"
  ON performance_metric_plan_links FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage performance metric plan links"
  ON performance_metric_plan_links FOR ALL
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

-- Ensure vesting processing enforces linked performance metric confirmation
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

  -- Determine if the linked plan has performance metrics that require confirmation
  SELECT EXISTS (
    SELECT 1
    FROM performance_metric_plan_links pmp
    WHERE pmp.plan_id = v_grant.plan_id
      AND pmp.company_id = v_event.company_id
  ) INTO v_requires_performance;

  -- Prevent vesting if performance conditions are not met for plans with linked metrics
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

