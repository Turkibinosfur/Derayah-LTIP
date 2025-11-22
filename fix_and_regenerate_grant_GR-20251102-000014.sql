-- Fix and regenerate vesting events for grant GR-20251102-000014
-- This script will:
-- 1. Check if the template has milestones
-- 2. If not, generate milestones based on template settings
-- 3. Regenerate vesting events for the grant

DO $$
DECLARE
  v_grant_id uuid;
  v_grant_number text;
  v_template_id uuid;
  v_plan_id uuid;
  v_vesting_start_date date;
  v_total_shares numeric;
  
  v_template_total_months int;
  v_template_cliff_months int;
  v_template_frequency text;
  v_template_type text;
  
  v_milestone_count int;
  v_periods int;
  v_percentage_per_period numeric;
  v_milestone_order int := 0;
  
  v_milestone_row RECORD;
  v_calculated_date date;
  v_shares_by_milestone numeric;
  v_shares_allocated numeric := 0;
  v_cumulative_shares numeric := 0;
  v_event_type text;
  v_shares_to_vest numeric;
BEGIN
  -- Step 1: Get grant details
  RAISE NOTICE 'Step 1: Fetching grant details...';
  
  SELECT 
    id, 
    grant_number, 
    vesting_start_date,
    total_shares,
    plan_id
  INTO 
    v_grant_id, 
    v_grant_number, 
    v_vesting_start_date,
    v_total_shares,
    v_plan_id
  FROM grants
  WHERE grant_number = 'GR-20251102-000014';
  
  IF v_grant_id IS NULL THEN
    RAISE EXCEPTION 'Grant GR-20251102-000014 not found';
  END IF;
  
  RAISE NOTICE '  Found grant: % (ID: %)', v_grant_number, v_grant_id;
  RAISE NOTICE '  Vesting start date: %', v_vesting_start_date;
  RAISE NOTICE '  Total shares: %', v_total_shares;
  
  -- Step 2: Get the template ID from the plan
  SELECT vesting_schedule_template_id
  INTO v_template_id
  FROM incentive_plans
  WHERE id = v_plan_id;
  
  IF v_template_id IS NULL THEN
    RAISE EXCEPTION 'Plan does not have a vesting_schedule_template_id';
  END IF;
  
  RAISE NOTICE '  Template ID: %', v_template_id;
  
  -- Step 3: Get template details
  SELECT 
    total_duration_months,
    cliff_months,
    vesting_frequency,
    schedule_type
  INTO 
    v_template_total_months,
    v_template_cliff_months,
    v_template_frequency,
    v_template_type
  FROM vesting_schedules
  WHERE id = v_template_id AND is_template = true;
  
  IF v_template_total_months IS NULL THEN
    RAISE EXCEPTION 'Template not found or invalid';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE 'Step 2: Template details:';
  RAISE NOTICE '  Total duration: % months', v_template_total_months;
  RAISE NOTICE '  Cliff period: % months', v_template_cliff_months;
  RAISE NOTICE '  Vesting frequency: %', v_template_frequency;
  RAISE NOTICE '  Schedule type: %', v_template_type;
  
  -- Step 4: Check if template has milestones
  SELECT COUNT(*)
  INTO v_milestone_count
  FROM vesting_milestones
  WHERE vesting_schedule_id = v_template_id;
  
  RAISE NOTICE '';
  RAISE NOTICE 'Step 3: Checking existing milestones...';
  RAISE NOTICE '  Existing milestone count: %', v_milestone_count;
  
  -- Step 5: If no milestones, generate them
  IF v_milestone_count = 0 THEN
    RAISE NOTICE '  No milestones found. Generating milestones...';
    
    -- Determine frequency months
    DECLARE
      v_frequency_months int;
    BEGIN
      v_frequency_months := CASE v_template_frequency
        WHEN 'monthly' THEN 1
        WHEN 'quarterly' THEN 3
        WHEN 'annually' THEN 12
        ELSE 3
      END;
      
      -- Generate cliff milestone if cliff_months > 0
      IF v_template_cliff_months > 0 THEN
        INSERT INTO vesting_milestones (
          vesting_schedule_id,
          milestone_type,
          sequence_order,
          vesting_percentage,
          months_from_start,
          performance_metric_id,
          target_value
        ) VALUES (
          v_template_id,
          'time',
          v_milestone_order,
          25,
          v_template_cliff_months,
          NULL,
          NULL
        );
        
        RAISE NOTICE '    Generated cliff milestone: 25% at % months', v_template_cliff_months;
        v_milestone_order := v_milestone_order + 1;
      END IF;
      
      -- Generate periodic milestones
      DECLARE
        v_remaining_months int;
        v_period_count int;
      BEGIN
        v_remaining_months := v_template_total_months - v_template_cliff_months;
        v_period_count := FLOOR(v_remaining_months / v_frequency_months);
        
        IF v_period_count > 0 THEN
          v_percentage_per_period := 75.0 / v_period_count;
          
          FOR i IN 1..v_period_count LOOP
            INSERT INTO vesting_milestones (
              vesting_schedule_id,
              milestone_type,
              sequence_order,
              vesting_percentage,
              months_from_start,
              performance_metric_id,
              target_value
            ) VALUES (
              v_template_id,
              'time',
              v_milestone_order,
              v_percentage_per_period,
              v_template_cliff_months + (i * v_frequency_months),
              NULL,
              NULL
            );
            
            RAISE NOTICE '    Generated periodic milestone: %.2f% at % months', 
              v_percentage_per_period,
              v_template_cliff_months + (i * v_frequency_months);
            v_milestone_order := v_milestone_order + 1;
          END LOOP;
        END IF;
      END;
    END;
    
    RAISE NOTICE '  Milestone generation complete';
  ELSE
    RAISE NOTICE '  Using existing milestones';
  END IF;
  
  -- Step 6: Delete existing vesting events for this grant
  RAISE NOTICE '';
  RAISE NOTICE 'Step 4: Deleting existing vesting events...';
  
  DELETE FROM vesting_events
  WHERE grant_id = v_grant_id;
  
  GET DIAGNOSTICS v_milestone_count = ROW_COUNT;
  RAISE NOTICE '  Deleted % existing events', v_milestone_count;
  
  -- Step 7: Generate new vesting events
  RAISE NOTICE '';
  RAISE NOTICE 'Step 5: Generating new vesting events...';
  
  -- Get all milestones ordered by sequence
  FOR v_milestone_row IN 
    SELECT 
      sequence_order,
      milestone_type,
      vesting_percentage,
      months_from_start,
      id
    FROM vesting_milestones
    WHERE vesting_schedule_id = v_template_id
    ORDER BY sequence_order
  LOOP
    -- Calculate vesting date
    v_calculated_date := v_vesting_start_date + (v_milestone_row.months_from_start || ' months')::interval;
    
    -- Calculate shares (except for last milestone)
    v_shares_to_vest := FLOOR((v_total_shares * v_milestone_row.vesting_percentage) / 100);
    v_shares_allocated := v_shares_allocated + v_shares_to_vest;
    
    -- Determine event type
    v_event_type := CASE v_milestone_row.milestone_type
      WHEN 'time' THEN 'time_based'
      WHEN 'performance' THEN 'performance'
      WHEN 'hybrid' THEN 'hybrid'
      ELSE 'time_based'
    END;
    
    -- Accumulate cumulative shares
    v_cumulative_shares := v_cumulative_shares + v_shares_to_vest;
    
    -- Insert the vesting event
    INSERT INTO vesting_events (
      grant_id,
      employee_id,
      company_id,
      event_type,
      sequence_number,
      vesting_date,
      shares_to_vest,
      cumulative_shares_vested,
      performance_condition_met,
      status,
      created_at
    )
    SELECT 
      v_grant_id,
      employee_id,
      company_id,
      v_event_type,
      v_milestone_row.sequence_order,
      v_calculated_date,
      v_shares_to_vest,
      v_cumulative_shares,
      true,
      'pending',
      NOW()
    FROM grants
    WHERE id = v_grant_id;
    
    RAISE NOTICE '  Event %: % shares (%.2f%%) on %', 
      v_milestone_row.sequence_order,
      v_shares_to_vest,
      v_milestone_row.vesting_percentage,
      v_calculated_date;
  END LOOP;
  
  -- Adjust the last event to include any remainder
  UPDATE vesting_events
  SET shares_to_vest = (
    SELECT v_total_shares - SUM(shares_to_vest) 
    FROM vesting_events 
    WHERE grant_id = v_grant_id AND id != vesting_events.id
  )
  WHERE grant_id = v_grant_id
  AND sequence_number = (
    SELECT MAX(sequence_number) 
    FROM vesting_events 
    WHERE grant_id = v_grant_id
  );
  
  RAISE NOTICE '';
  RAISE NOTICE 'Step 6: Fix complete!';
  RAISE NOTICE '';
  RAISE NOTICE '=== SUMMARY ===';
  RAISE NOTICE 'Grant: %', v_grant_number;
  RAISE NOTICE 'Total shares: %', v_total_shares;
  RAISE NOTICE 'Vesting events generated successfully';
  
END $$;

