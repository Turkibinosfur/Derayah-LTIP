-- Simplified vesting event generation function
-- This version only uses columns that definitely exist in the table

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
  RAISE NOTICE 'Starting vesting event generation for grant: %', p_grant_id;

  -- Check if events already exist for this grant
  IF EXISTS (SELECT 1 FROM vesting_events WHERE grant_id = p_grant_id) THEN
    RAISE NOTICE 'Vesting events already exist for grant %', p_grant_id;
    RETURN;
  END IF;

  -- Get grant details
  SELECT * INTO v_grant FROM grants WHERE id = p_grant_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Grant not found: %', p_grant_id;
  END IF;

  RAISE NOTICE 'Grant found: % shares, status: %, start date: %', 
    v_grant.total_shares, v_grant.status, v_grant.vesting_start_date;

  -- Skip if grant is not active
  IF v_grant.status != 'active' THEN
    RAISE NOTICE 'Grant % is not active (status: %)', p_grant_id, v_grant.status;
    RETURN;
  END IF;

  -- Check if vesting_start_date is set
  IF v_grant.vesting_start_date IS NULL THEN
    RAISE NOTICE 'Grant % has no vesting start date', p_grant_id;
    RETURN;
  END IF;

  -- Get plan details
  SELECT * INTO v_plan FROM incentive_plans WHERE id = v_grant.plan_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Plan not found: %', v_grant.plan_id;
  END IF;

  RAISE NOTICE 'Plan found: %, type: %', v_plan.plan_name_en, v_plan.plan_type;

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
      RAISE NOTICE 'Using template: % months total, % cliff, % frequency', v_total_months, v_cliff_months, v_frequency;
    ELSE
      RAISE NOTICE 'Template not found for ID: %', v_plan.vesting_schedule_template_id;
    END IF;
  END IF;

  -- Fallback to vesting_config
  IF v_template IS NULL THEN
    v_vesting_config := COALESCE(v_plan.vesting_config, '{}'::jsonb);
    v_cliff_months := COALESCE((v_vesting_config->>'cliff_months')::integer, 12);
    v_total_months := COALESCE((v_vesting_config->>'years')::integer * 12, 48);
    v_frequency := COALESCE(v_vesting_config->>'frequency', 'monthly');
    RAISE NOTICE 'Using vesting_config: % months total, % cliff, % frequency', v_total_months, v_cliff_months, v_frequency;
  END IF;

  -- Validate we have proper vesting parameters
  IF v_total_months IS NULL OR v_total_months <= 0 THEN
    RAISE NOTICE 'Invalid total_months: %', v_total_months;
    RETURN;
  END IF;

  -- Calculate frequency in months
  v_frequency_months := CASE v_frequency
    WHEN 'monthly' THEN 1
    WHEN 'quarterly' THEN 3
    WHEN 'annually' THEN 12
    ELSE 1
  END;

  -- Calculate periods and shares
  v_total_periods := CEIL((v_total_months - COALESCE(v_cliff_months, 0))::numeric / v_frequency_months);
  
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

  RAISE NOTICE 'Creating vesting events: % total periods, % shares per period, cliff: % shares', 
    v_total_periods, v_shares_per_period, v_cliff_shares;

  -- Create cliff event if applicable
  IF v_cliff_months > 0 AND v_cliff_shares > 0 THEN
    v_current_date := v_start_date + (v_cliff_months || ' months')::interval;
    v_cumulative_shares := v_cliff_shares;
    
    INSERT INTO vesting_events (
      grant_id, employee_id, company_id, event_type, sequence_number,
      vesting_date, shares_to_vest, cumulative_shares_vested,
      exercise_price, total_exercise_cost,
      status, performance_condition_met
    ) VALUES (
      p_grant_id, v_grant.employee_id, v_grant.company_id, 'cliff', v_sequence,
      v_current_date, v_cliff_shares, v_cumulative_shares,
      v_exercise_price, 
      CASE WHEN v_exercise_price IS NOT NULL THEN v_cliff_shares * v_exercise_price ELSE NULL END,
      CASE WHEN v_current_date <= CURRENT_DATE THEN 'due' ELSE 'pending' END,
      true
    );
    
    v_sequence := v_sequence + 1;
    RAISE NOTICE 'Created cliff event: % shares on %', v_cliff_shares, v_current_date;
  END IF;

  -- Create regular vesting events
  FOR i IN 1..v_total_periods LOOP
    v_current_date := v_start_date + ((COALESCE(v_cliff_months, 0) + i * v_frequency_months) || ' months')::interval;
    v_cumulative_shares := v_cumulative_shares + v_shares_per_period;
    
    -- Ensure we don't exceed total shares due to rounding
    IF v_cumulative_shares > v_grant.total_shares THEN
      v_shares_per_period := v_grant.total_shares - (v_cumulative_shares - v_shares_per_period);
      v_cumulative_shares := v_grant.total_shares;
    END IF;
    
    INSERT INTO vesting_events (
      grant_id, employee_id, company_id, event_type, sequence_number,
      vesting_date, shares_to_vest, cumulative_shares_vested,
      exercise_price, total_exercise_cost,
      status, performance_condition_met
    ) VALUES (
      p_grant_id, v_grant.employee_id, v_grant.company_id, 'time_based', v_sequence,
      v_current_date, v_shares_per_period, v_cumulative_shares,
      v_exercise_price,
      CASE WHEN v_exercise_price IS NOT NULL THEN v_shares_per_period * v_exercise_price ELSE NULL END,
      CASE WHEN v_current_date <= CURRENT_DATE THEN 'due' ELSE 'pending' END,
      true
    );
    
    v_sequence := v_sequence + 1;
    RAISE NOTICE 'Created vesting event %: % shares on %', i, v_shares_per_period, v_current_date;
    
    -- Stop if we've allocated all shares
    EXIT WHEN v_cumulative_shares >= v_grant.total_shares;
  END LOOP;

  RAISE NOTICE 'Successfully generated % vesting events for grant %', v_sequence - 1, p_grant_id;
END;
$$;
