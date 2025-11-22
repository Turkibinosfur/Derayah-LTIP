/*
  # Vesting Events System
  
  This migration creates a comprehensive vesting events system that:
  1. Creates vesting_events table to track individual vesting transactions
  2. Creates triggers to auto-generate vesting events when grants are created
  3. Supports all plan types (LTIP_RSU, LTIP_RSA, ESOP)
  4. Manages vesting status and portfolio transfers
  5. Calculates remaining days for upcoming events
*/

-- Create enums for vesting events
CREATE TYPE vesting_event_status AS ENUM (
  'pending',           -- Event is scheduled but not yet due
  'due',              -- Event is due for processing
  'vested',           -- Shares have vested but not yet transferred/exercised
  'transferred',      -- RSU/RSA shares transferred to portfolio
  'exercised',        -- ESOP options exercised and shares transferred
  'forfeited',        -- Event forfeited due to termination/conditions not met
  'cancelled'         -- Event cancelled due to grant modification
);

CREATE TYPE vesting_event_type AS ENUM (
  'cliff',            -- Cliff vesting event
  'time_based',       -- Regular time-based vesting
  'performance',      -- Performance-based vesting
  'acceleration'      -- Accelerated vesting (change of control, etc.)
);

-- Create vesting_events table
CREATE TABLE vesting_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  grant_id uuid NOT NULL REFERENCES grants(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  
  -- Event details
  event_type vesting_event_type NOT NULL DEFAULT 'time_based',
  sequence_number integer NOT NULL, -- Order of vesting events for this grant
  
  -- Vesting schedule
  vesting_date date NOT NULL,
  shares_to_vest numeric(15,2) NOT NULL CHECK (shares_to_vest > 0),
  cumulative_shares_vested numeric(15,2) NOT NULL DEFAULT 0,
  
  -- Status and processing
  status vesting_event_status NOT NULL DEFAULT 'pending',
  processed_at timestamptz,
  processed_by uuid REFERENCES auth.users(id),
  
  -- Exercise details (for ESOP)
  exercise_price numeric(15,4), -- Price per share for exercise
  fair_market_value numeric(15,4), -- FMV at vesting date
  total_exercise_cost numeric(15,2), -- Total cost to exercise all shares
  
  -- Performance conditions (if applicable)
  performance_condition_met boolean DEFAULT true,
  performance_notes text,
  
  -- Portfolio tracking
  portfolio_transaction_id uuid, -- Link to portfolio transaction when processed
  
  -- Audit fields
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  -- Constraints
  UNIQUE(grant_id, sequence_number)
);

-- Create indexes for performance
CREATE INDEX idx_vesting_events_grant_id ON vesting_events(grant_id);
CREATE INDEX idx_vesting_events_employee_id ON vesting_events(employee_id);
CREATE INDEX idx_vesting_events_company_id ON vesting_events(company_id);
CREATE INDEX idx_vesting_events_vesting_date ON vesting_events(vesting_date);
CREATE INDEX idx_vesting_events_status ON vesting_events(status);
CREATE INDEX idx_vesting_events_due ON vesting_events(vesting_date, status) WHERE status IN ('pending', 'due');

-- Enable RLS
ALTER TABLE vesting_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view vesting events for their company"
  ON vesting_events FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can insert vesting events"
  ON vesting_events FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users 
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  );

CREATE POLICY "Admins can update vesting events"
  ON vesting_events FOR UPDATE
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

-- Function to calculate vesting events for a grant
CREATE OR REPLACE FUNCTION generate_vesting_events_for_grant(p_grant_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_grant grants%ROWTYPE;
  v_plan incentive_plans%ROWTYPE;
  v_template vesting_schedules%ROWTYPE;
  v_vesting_config jsonb;
  v_start_date date;
  v_cliff_months integer;
  v_total_months integer;
  v_frequency text;
  v_frequency_months integer;
  v_total_periods integer;
  v_shares_per_period numeric;
  v_cliff_shares numeric;
  v_current_date date;
  v_cumulative_shares numeric := 0;
  v_sequence integer := 1;
  v_exercise_price numeric;
BEGIN
  -- Get grant details
  SELECT * INTO v_grant FROM grants WHERE id = p_grant_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Grant not found: %', p_grant_id;
  END IF;

  -- Get plan details
  SELECT * INTO v_plan FROM incentive_plans WHERE id = v_grant.plan_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Plan not found: %', v_grant.plan_id;
  END IF;

  -- Get vesting schedule details
  v_start_date := v_grant.vesting_start_date;
  
  -- Try to get template details first
  IF v_plan.vesting_schedule_template_id IS NOT NULL THEN
    SELECT * INTO v_template 
    FROM vesting_schedules 
    WHERE id = v_plan.vesting_schedule_template_id AND is_template = true;
    
    IF FOUND THEN
      v_cliff_months := v_template.cliff_months;
      v_total_months := v_template.total_duration_months;
      v_frequency := v_template.vesting_frequency;
    END IF;
  END IF;

  -- Fallback to vesting_config
  IF v_template IS NULL THEN
    v_vesting_config := COALESCE(v_plan.vesting_config, '{}'::jsonb);
    v_cliff_months := COALESCE((v_vesting_config->>'cliff_months')::integer, 12);
    v_total_months := COALESCE((v_vesting_config->>'years')::integer * 12, 48);
    v_frequency := COALESCE(v_vesting_config->>'frequency', 'monthly');
  END IF;

  -- Calculate frequency in months
  v_frequency_months := CASE v_frequency
    WHEN 'monthly' THEN 1
    WHEN 'quarterly' THEN 3
    WHEN 'annually' THEN 12
    ELSE 1
  END;

  -- Calculate periods and shares
  v_total_periods := CEIL((v_total_months - v_cliff_months)::numeric / v_frequency_months);
  
  -- For cliff vesting: 25% at cliff, rest distributed over remaining periods
  IF v_cliff_months > 0 THEN
    v_cliff_shares := v_grant.total_shares * 0.25;
    v_shares_per_period := (v_grant.total_shares - v_cliff_shares) / v_total_periods;
  ELSE
    v_cliff_shares := 0;
    v_shares_per_period := v_grant.total_shares / v_total_periods;
  END IF;

  -- Set exercise price for ESOP plans
  v_exercise_price := CASE 
    WHEN v_plan.plan_type = 'ESOP' THEN COALESCE(v_grant.exercise_price, 1.0)
    ELSE NULL
  END;

  -- Create cliff event if applicable
  IF v_cliff_months > 0 AND v_cliff_shares > 0 THEN
    v_current_date := v_start_date + (v_cliff_months || ' months')::interval;
    v_cumulative_shares := v_cliff_shares;
    
    INSERT INTO vesting_events (
      grant_id, employee_id, company_id, event_type, sequence_number,
      vesting_date, shares_to_vest, cumulative_shares_vested,
      exercise_price, total_exercise_cost
    ) VALUES (
      p_grant_id, v_grant.employee_id, v_grant.company_id, 'cliff', v_sequence,
      v_current_date, v_cliff_shares, v_cumulative_shares,
      v_exercise_price, 
      CASE WHEN v_exercise_price IS NOT NULL THEN v_cliff_shares * v_exercise_price ELSE NULL END
    );
    
    v_sequence := v_sequence + 1;
  END IF;

  -- Create regular vesting events
  FOR i IN 1..v_total_periods LOOP
    v_current_date := v_start_date + ((v_cliff_months + i * v_frequency_months) || ' months')::interval;
    v_cumulative_shares := v_cumulative_shares + v_shares_per_period;
    
    -- Ensure we don't exceed total shares due to rounding
    IF v_cumulative_shares > v_grant.total_shares THEN
      v_shares_per_period := v_grant.total_shares - (v_cumulative_shares - v_shares_per_period);
      v_cumulative_shares := v_grant.total_shares;
    END IF;
    
    INSERT INTO vesting_events (
      grant_id, employee_id, company_id, event_type, sequence_number,
      vesting_date, shares_to_vest, cumulative_shares_vested,
      exercise_price, total_exercise_cost
    ) VALUES (
      p_grant_id, v_grant.employee_id, v_grant.company_id, 'time_based', v_sequence,
      v_current_date, v_shares_per_period, v_cumulative_shares,
      v_exercise_price,
      CASE WHEN v_exercise_price IS NOT NULL THEN v_shares_per_period * v_exercise_price ELSE NULL END
    );
    
    v_sequence := v_sequence + 1;
    
    -- Stop if we've allocated all shares
    EXIT WHEN v_cumulative_shares >= v_grant.total_shares;
  END LOOP;

  RAISE NOTICE 'Generated % vesting events for grant %', v_sequence - 1, p_grant_id;
END;
$$;

-- Trigger function to auto-generate vesting events when a grant is created
CREATE OR REPLACE FUNCTION trigger_generate_vesting_events()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_plan_template_id uuid;
BEGIN
  -- Only generate events for active grants
  IF NEW.status = 'active' THEN
    -- Check if this grant's plan has a vesting schedule template
    -- If it does, skip database generation (JavaScript function will handle it)
    SELECT vesting_schedule_template_id INTO v_plan_template_id
    FROM incentive_plans
    WHERE id = NEW.plan_id;
    
    -- Only generate events if plan does NOT have a template (legacy behavior)
    IF v_plan_template_id IS NULL THEN
      PERFORM generate_vesting_events_for_grant(NEW.id);
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger on grants table
DROP TRIGGER IF EXISTS auto_generate_vesting_events ON grants;
CREATE TRIGGER auto_generate_vesting_events
  AFTER INSERT ON grants
  FOR EACH ROW
  EXECUTE FUNCTION trigger_generate_vesting_events();

-- Function to update vesting event status based on current date
CREATE OR REPLACE FUNCTION update_vesting_event_status()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update pending events that are now due (vesting date is today or in the past)
  UPDATE vesting_events 
  SET 
    status = 'due',
    updated_at = now()
  WHERE 
    status = 'pending' 
    AND vesting_date <= CURRENT_DATE;
    
  -- Update events that were incorrectly marked as due but have future vesting dates
  UPDATE vesting_events 
  SET 
    status = 'pending',
    updated_at = now()
  WHERE 
    status = 'due' 
    AND vesting_date > CURRENT_DATE;
    
  RAISE NOTICE 'Updated vesting event statuses';
END;
$$;

-- Function to process a vesting event (vest shares)
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

  -- Get grant and plan details
  SELECT * INTO v_grant FROM grants WHERE id = v_event.grant_id;
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

-- Create updated_at trigger for vesting_events
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_vesting_events_updated_at 
  BEFORE UPDATE ON vesting_events 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION generate_vesting_events_for_grant(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION update_vesting_event_status() TO authenticated;
GRANT EXECUTE ON FUNCTION process_vesting_event(uuid, uuid, numeric) TO authenticated;

COMMENT ON TABLE vesting_events IS 'Individual vesting events that track when shares vest for each grant';
COMMENT ON FUNCTION generate_vesting_events_for_grant(uuid) IS 'Generates vesting events for a grant based on its vesting schedule';
COMMENT ON FUNCTION process_vesting_event(uuid, uuid, numeric) IS 'Processes a vesting event and updates grant vested shares';
