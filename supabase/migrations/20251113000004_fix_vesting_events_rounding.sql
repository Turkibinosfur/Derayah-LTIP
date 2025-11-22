-- Fix the generate_vesting_events_for_grant function to ensure all shares are allocated
-- by assigning remainder to the last vesting event

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
  v_allocated_shares numeric := 0; -- Track allocated shares
  v_shares_this_period numeric; -- Shares for current period
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
    v_cliff_shares := FLOOR(v_grant.total_shares * 0.25); -- Use FLOOR to get whole shares
    v_shares_per_period := FLOOR((v_grant.total_shares - v_cliff_shares) / v_total_periods); -- Use FLOOR for whole shares
  ELSE
    v_cliff_shares := 0;
    v_shares_per_period := FLOOR(v_grant.total_shares / v_total_periods); -- Use FLOOR for whole shares
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
    v_allocated_shares := v_cliff_shares;
    
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
    
    -- Calculate shares for this period
    IF i = v_total_periods THEN
      -- Last period: assign all remaining shares to ensure total equals grant total
      v_shares_this_period := v_grant.total_shares - v_allocated_shares;
    ELSE
      v_shares_this_period := v_shares_per_period;
    END IF;
    
    v_allocated_shares := v_allocated_shares + v_shares_this_period;
    v_cumulative_shares := v_allocated_shares;
    
    INSERT INTO vesting_events (
      grant_id, employee_id, company_id, event_type, sequence_number,
      vesting_date, shares_to_vest, cumulative_shares_vested,
      exercise_price, total_exercise_cost
    ) VALUES (
      p_grant_id, v_grant.employee_id, v_grant.company_id, 'time_based', v_sequence,
      v_current_date, v_shares_this_period, v_cumulative_shares,
      v_exercise_price,
      CASE WHEN v_exercise_price IS NOT NULL THEN v_shares_this_period * v_exercise_price ELSE NULL END
    );
    
    v_sequence := v_sequence + 1;
    
    -- Stop if we've allocated all shares
    EXIT WHEN v_allocated_shares >= v_grant.total_shares;
  END LOOP;

  RAISE NOTICE 'Generated % vesting events for grant % (total shares: %, allocated: %)', 
    v_sequence - 1, p_grant_id, v_grant.total_shares, v_allocated_shares;
END;
$$;

