-- Test vesting event generation for a single grant
-- Run this step by step in Supabase SQL Editor

-- Step 1: Check table structure
SELECT 'Table structure check:' as step;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'vesting_events' 
ORDER BY ordinal_position;

-- Step 2: Get one active grant
SELECT 'Active grant details:' as step;
SELECT 
  g.id,
  g.employee_id,
  g.company_id,
  g.total_shares,
  g.vesting_start_date,
  g.status,
  p.plan_name_en,
  p.plan_type,
  p.vesting_schedule_template_id,
  p.vesting_config
FROM grants g
JOIN incentive_plans p ON g.plan_id = p.id
WHERE g.status = 'active'
LIMIT 1;

-- Step 3: Test the function with one grant
-- REPLACE 'YOUR_GRANT_ID_HERE' with the actual grant ID from step 2
DO $$
DECLARE
  v_grant_id UUID;
  v_events_before INTEGER;
  v_events_after INTEGER;
BEGIN
  -- Get first active grant
  SELECT g.id INTO v_grant_id
  FROM grants g
  WHERE g.status = 'active'
  LIMIT 1;
  
  IF v_grant_id IS NULL THEN
    RAISE NOTICE 'No active grants found';
    RETURN;
  END IF;
  
  -- Count events before
  SELECT COUNT(*) INTO v_events_before FROM vesting_events WHERE grant_id = v_grant_id;
  RAISE NOTICE 'Events before: %', v_events_before;
  
  -- Generate events
  RAISE NOTICE 'Generating events for grant: %', v_grant_id;
  PERFORM generate_vesting_events_for_grant(v_grant_id);
  
  -- Count events after
  SELECT COUNT(*) INTO v_events_after FROM vesting_events WHERE grant_id = v_grant_id;
  RAISE NOTICE 'Events after: %', v_events_after;
  RAISE NOTICE 'Events created: %', v_events_after - v_events_before;
END $$;

-- Step 4: Check if any events were created
SELECT 'Final check:' as step;
SELECT COUNT(*) as total_vesting_events FROM vesting_events;

-- Step 5: Show any created events
SELECT 
  ve.id,
  ve.grant_id,
  ve.vesting_date,
  ve.shares_to_vest,
  ve.event_type,
  ve.status,
  ve.sequence_number
FROM vesting_events ve
ORDER BY ve.created_at DESC
LIMIT 5;
