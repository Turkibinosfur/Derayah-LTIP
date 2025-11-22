-- Fix vesting event status logic
-- Events with future vesting dates should not be marked as 'due'

-- Update the function to fix incorrectly marked events
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
    
  RAISE NOTICE 'Updated vesting event statuses - fixed future dates marked as due';
END;
$$;

-- Run the function to fix existing data
SELECT update_vesting_event_status();

-- Show the results
DO $$
DECLARE
    due_count integer;
    pending_count integer;
    future_due_count integer;
BEGIN
    -- Count events that are due (should be today or past)
    SELECT COUNT(*) INTO due_count 
    FROM vesting_events 
    WHERE status = 'due' AND vesting_date <= CURRENT_DATE;
    
    -- Count events that are pending (should be future)
    SELECT COUNT(*) INTO pending_count 
    FROM vesting_events 
    WHERE status = 'pending' AND vesting_date > CURRENT_DATE;
    
    -- Count any remaining incorrectly marked events (should be 0)
    SELECT COUNT(*) INTO future_due_count 
    FROM vesting_events 
    WHERE status = 'due' AND vesting_date > CURRENT_DATE;
    
    RAISE NOTICE 'Status fix results:';
    RAISE NOTICE '- Events correctly marked as due (today/past): %', due_count;
    RAISE NOTICE '- Events correctly marked as pending (future): %', pending_count;
    RAISE NOTICE '- Events incorrectly marked as due (future): %', future_due_count;
    
    IF future_due_count > 0 THEN
        RAISE WARNING 'There are still % events incorrectly marked as due with future dates!', future_due_count;
    ELSE
        RAISE NOTICE '✅ All vesting event statuses are now correct!';
    END IF;
END;
$$;
