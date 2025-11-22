-- Diagnose the vesting events issue for grant GR-20251102-000014
-- This will check:
-- 1. The grant details (vesting_start_date)
-- 2. The plan linked to the grant
-- 3. The template linked to the plan
-- 4. The milestones in the template

DO $$
DECLARE
  v_grant_id uuid;
  v_grant_number text;
  v_vesting_start_date date;
  v_template_id uuid;
  v_plan_id uuid;
  v_plan_name text;
  v_template_name text;
  v_milestone_count int;
BEGIN
  -- Find the grant by grant_number
  SELECT id, grant_number, vesting_start_date, plan_id
  INTO v_grant_id, v_grant_number, v_vesting_start_date, v_plan_id
  FROM grants
  WHERE grant_number = 'GR-20251102-000014';
  
  IF v_grant_id IS NULL THEN
    RAISE NOTICE 'Grant GR-20251102-000014 not found';
    RETURN;
  END IF;
  
  RAISE NOTICE '=== GRANT INFORMATION ===';
  RAISE NOTICE 'Grant ID: %', v_grant_id;
  RAISE NOTICE 'Grant Number: %', v_grant_number;
  RAISE NOTICE 'Vesting Start Date: %', v_vesting_start_date;
  RAISE NOTICE 'Plan ID: %', v_plan_id;
  
  -- Get the plan details
  SELECT plan_name_en, vesting_schedule_template_id
  INTO v_plan_name, v_template_id
  FROM incentive_plans
  WHERE id = v_plan_id;
  
  IF v_template_id IS NULL THEN
    RAISE NOTICE 'ERROR: Plan % (%) has no vesting_schedule_template_id', v_plan_name, v_plan_id;
    RETURN;
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '=== PLAN INFORMATION ===';
  RAISE NOTICE 'Plan Name: %', v_plan_name;
  RAISE NOTICE 'Template ID: %', v_template_id;
  
  -- Get the template details
  SELECT name
  INTO v_template_name
  FROM vesting_schedules
  WHERE id = v_template_id AND is_template = true;
  
  IF v_template_name IS NULL THEN
    RAISE NOTICE 'ERROR: Template % not found or not marked as template', v_template_id;
    RETURN;
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '=== TEMPLATE INFORMATION ===';
  RAISE NOTICE 'Template Name: %', v_template_name;
  
  -- Count milestones
  SELECT COUNT(*)
  INTO v_milestone_count
  FROM vesting_milestones
  WHERE vesting_schedule_id = v_template_id;
  
  RAISE NOTICE 'Number of Milestones: %', v_milestone_count;
  
  IF v_milestone_count = 0 THEN
    RAISE NOTICE 'ERROR: Template has NO milestones! This is the problem.';
    RAISE NOTICE 'Need to generate milestones for this template.';
    RETURN;
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '=== MILESTONE DETAILS ===';
  
  -- Show all milestones
  FOR milestone IN 
    SELECT 
      sequence_order,
      milestone_type,
      vesting_percentage,
      months_from_start,
      performance_metric_id,
      target_value
    FROM vesting_milestones
    WHERE vesting_schedule_id = v_template_id
    ORDER BY sequence_order
  LOOP
    RAISE NOTICE '  Milestone %: Type=%, Percentage=%%, Months=%',
      milestone.sequence_order,
      milestone.milestone_type,
      milestone.vesting_percentage,
      milestone.months_from_start;
    
    IF milestone.months_from_start IS NULL THEN
      RAISE NOTICE '    WARNING: months_from_start is NULL for this milestone!';
    END IF;
  END LOOP;
  
  RAISE NOTICE '';
  RAISE NOTICE '=== CURRENT VESTING EVENTS ===';
  
  FOR event IN 
    SELECT 
      sequence_number,
      vesting_date,
      shares_to_vest,
      event_type,
      status
    FROM vesting_events
    WHERE grant_id = v_grant_id
    ORDER BY sequence_number
  LOOP
    RAISE NOTICE '  Event %: Date=%, Shares=%, Type=%, Status=%',
      event.sequence_number,
      event.vesting_date,
      event.shares_to_vest,
      event.event_type,
      event.status;
  END LOOP;
  
  RAISE NOTICE '';
  RAISE NOTICE '=== SUMMARY ===';
  
  -- Check if all dates are the same
  IF (SELECT COUNT(DISTINCT vesting_date) FROM vesting_events WHERE grant_id = v_grant_id) = 1 THEN
    RAISE NOTICE 'ERROR: All vesting events have the SAME date';
    
    IF EXISTS (SELECT 1 FROM vesting_milestones WHERE vesting_schedule_id = v_template_id AND months_from_start IS NULL) THEN
      RAISE NOTICE 'PROBLEM IDENTIFIED: Template has milestones with NULL months_from_start';
      RAISE NOTICE 'SOLUTION: Need to regenerate milestones for the template or regenerate events with fixed milestones';
    ELSIF (SELECT COUNT(DISTINCT months_from_start) FROM vesting_milestones WHERE vesting_schedule_id = v_template_id) = 1 THEN
      RAISE NOTICE 'PROBLEM IDENTIFIED: All milestones have the SAME months_from_start';
      RAISE NOTICE 'SOLUTION: Template milestones need to be corrected in the UI';
    END IF;
  END IF;
  
END $$;

