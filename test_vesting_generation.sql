-- Test vesting event generation for active grants
-- Run this in Supabase SQL Editor

-- First, let's see the details of one active grant
SELECT 
  g.id,
  g.employee_id,
  g.company_id,
  g.plan_id,
  g.total_shares,
  g.vesting_start_date,
  g.status,
  COALESCE(e.first_name_en, e.first_name_ar, 'Unknown') || ' ' || COALESCE(e.last_name_en, e.last_name_ar, 'Employee') as employee_name,
  p.plan_name_en,
  p.plan_code,
  p.plan_type,
  p.vesting_schedule_template_id,
  p.vesting_config,
  vs.name as template_name,
  vs.total_duration_months,
  vs.cliff_months,
  vs.vesting_frequency
FROM grants g
LEFT JOIN employees e ON g.employee_id = e.id
LEFT JOIN incentive_plans p ON g.plan_id = p.id
LEFT JOIN vesting_schedules vs ON p.vesting_schedule_template_id = vs.id
WHERE g.status = 'active'
ORDER BY g.created_at DESC
LIMIT 1;

-- Now let's test the vesting calculation function manually
-- Replace 'GRANT_ID_HERE' with the actual grant ID from the query above
DO $$
DECLARE
  v_grant_id UUID;
  v_result JSONB;
BEGIN
  -- Get the first active grant ID
  SELECT g.id INTO v_grant_id
  FROM grants g
  WHERE g.status = 'active'
  LIMIT 1;
  
  IF v_grant_id IS NULL THEN
    RAISE NOTICE 'No active grants found';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Testing vesting calculation for grant: %', v_grant_id;
  
  -- Test the calculation function first
  BEGIN
    SELECT calculate_vesting_events_for_grant(v_grant_id) INTO v_result;
    RAISE NOTICE 'Vesting calculation result: %', v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error in calculate_vesting_events_for_grant: %', SQLERRM;
  END;
  
  -- Test the generation function
  BEGIN
    PERFORM generate_vesting_events_for_grant(v_grant_id);
    RAISE NOTICE 'Vesting generation completed successfully';
    
    -- Check if events were created
    DECLARE
      v_events_count INTEGER;
    BEGIN
      SELECT COUNT(*) INTO v_events_count
      FROM vesting_events
      WHERE grant_id = v_grant_id;
      
      RAISE NOTICE 'Vesting events created: %', v_events_count;
      
      -- Show the created events
      IF v_events_count > 0 THEN
        DECLARE
          event_rec RECORD;
        BEGIN
          FOR event_rec IN
            SELECT 
              vesting_date,
              shares_to_vest,
              event_type,
              status,
              requires_exercise,
              exercise_price
            FROM vesting_events
            WHERE grant_id = v_grant_id
            ORDER BY vesting_date
          LOOP
            RAISE NOTICE 'Event: % | % shares | % | %', 
              event_rec.vesting_date,
              event_rec.shares_to_vest,
              event_rec.event_type,
              event_rec.status;
          END LOOP;
        END;
      END IF;
    END;
    
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error in generate_vesting_events_for_grant: %', SQLERRM;
  END;
END $$;
