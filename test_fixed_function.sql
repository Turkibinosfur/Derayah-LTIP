-- Test the fixed vesting function
-- Run this after running fixed_vesting_function.sql

DO $$
DECLARE
  v_grant_id UUID;
  v_events_before INTEGER;
  v_events_after INTEGER;
BEGIN
  RAISE NOTICE '=== TESTING FIXED VESTING FUNCTION ===';
  
  -- Get first active grant
  SELECT g.id INTO v_grant_id
  FROM grants g
  WHERE g.status = 'active'
  LIMIT 1;
  
  IF v_grant_id IS NULL THEN
    RAISE NOTICE 'No active grants found';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Testing with grant: %', v_grant_id;
  
  -- Count events before
  SELECT COUNT(*) INTO v_events_before FROM vesting_events WHERE grant_id = v_grant_id;
  RAISE NOTICE 'Events before: %', v_events_before;
  
  -- Generate events
  PERFORM generate_vesting_events_for_grant(v_grant_id);
  
  -- Count events after
  SELECT COUNT(*) INTO v_events_after FROM vesting_events WHERE grant_id = v_grant_id;
  RAISE NOTICE 'Events after: %', v_events_after;
  RAISE NOTICE 'Events created: %', v_events_after - v_events_before;
  
  -- Show created events
  IF v_events_after > v_events_before THEN
    RAISE NOTICE '=== CREATED EVENTS ===';
    DECLARE
      event_rec RECORD;
    BEGIN
      FOR event_rec IN
        SELECT 
          vesting_date,
          shares_to_vest,
          event_type,
          status,
          sequence_number
        FROM vesting_events
        WHERE grant_id = v_grant_id
        ORDER BY sequence_number
      LOOP
        RAISE NOTICE 'Event %: % shares on % (%, %)', 
          event_rec.sequence_number,
          event_rec.shares_to_vest,
          event_rec.vesting_date,
          event_rec.event_type,
          event_rec.status;
      END LOOP;
    END;
  END IF;
END $$;

-- Final check: show total vesting events in system
SELECT 
  COUNT(*) as total_events,
  COUNT(DISTINCT grant_id) as grants_with_events
FROM vesting_events;
