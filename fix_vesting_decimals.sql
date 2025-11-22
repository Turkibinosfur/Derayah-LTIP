-- Fix vesting events to use integer shares (floor first N-1, remainder to last)
-- This ensures: 12 + 18 + 20 = 50 (not 12.50 + 18.75 + 18.75 = 50)

BEGIN;

-- Create temp table for reporting
CREATE TEMPORARY TABLE IF NOT EXISTS tmp_vesting_fix_report (
  grant_id uuid,
  grant_number text,
  event_id uuid,
  sequence_number int,
  old_shares numeric,
  new_shares bigint
) ON COMMIT DROP;

-- Process each grant individually
DO $$
DECLARE
  grant_record RECORD;
  event_record RECORD;
  total_shares bigint;
  current_total bigint := 0;
  event_count int;
  i int;
  floored_shares bigint;
  remainder_shares bigint;
BEGIN
  -- Loop through each grant
  FOR grant_record IN 
    SELECT id, grant_number, grants.total_shares 
    FROM grants 
    ORDER BY grant_number
  LOOP
    -- Get all events for this grant, ordered by sequence
    SELECT COUNT(*) INTO event_count
    FROM vesting_events 
    WHERE grant_id = grant_record.id;
    
    -- Skip if no events
    IF event_count = 0 THEN
      CONTINUE;
    END IF;
    
    total_shares := grant_record.total_shares;
    current_total := 0;
    
    -- Process each event for this grant
    i := 0;
    FOR event_record IN 
      SELECT id, sequence_number, shares_to_vest
      FROM vesting_events 
      WHERE grant_id = grant_record.id 
      ORDER BY sequence_number
    LOOP
      i := i + 1;
      
      -- Floor all but the last event
      IF i < event_count THEN
        floored_shares := FLOOR(event_record.shares_to_vest);
        current_total := current_total + floored_shares;
        
        -- Update the event
        UPDATE vesting_events 
        SET shares_to_vest = floored_shares,
            updated_at = NOW()
        WHERE id = event_record.id;
        
        -- Log the change
        INSERT INTO tmp_vesting_fix_report (grant_id, grant_number, event_id, sequence_number, old_shares, new_shares)
        VALUES (grant_record.id, grant_record.grant_number, event_record.id, event_record.sequence_number, event_record.shares_to_vest, floored_shares);
        
      ELSE
        -- Last event gets the remainder
        remainder_shares := total_shares - current_total;
        
        -- Update the last event
        UPDATE vesting_events 
        SET shares_to_vest = remainder_shares,
            updated_at = NOW()
        WHERE id = event_record.id;
        
        -- Log the change
        INSERT INTO tmp_vesting_fix_report (grant_id, grant_number, event_id, sequence_number, old_shares, new_shares)
        VALUES (grant_record.id, grant_record.grant_number, event_record.id, event_record.sequence_number, event_record.shares_to_vest, remainder_shares);
      END IF;
    END LOOP;
  END LOOP;
END $$;

-- Show what was changed
SELECT 
  grant_number,
  sequence_number,
  old_shares,
  new_shares,
  (new_shares - old_shares) as adjustment
FROM tmp_vesting_fix_report
ORDER BY grant_number, sequence_number;

-- Verify the fix worked - show any grants that still don't match
SELECT 
  g.grant_number,
  g.total_shares,
  SUM(ve.shares_to_vest) as calculated_total,
  (g.total_shares - SUM(ve.shares_to_vest)) as difference
FROM grants g
LEFT JOIN vesting_events ve ON ve.grant_id = g.id
GROUP BY g.id, g.grant_number, g.total_shares
HAVING g.total_shares != SUM(ve.shares_to_vest)
ORDER BY g.grant_number;

COMMIT;
