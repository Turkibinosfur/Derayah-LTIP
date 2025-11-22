/*
  Simple Delete and Regenerate for Grant GR-20251101-000011
  
  This just deletes the old events and lets the JavaScript function regenerate them
  when you view the grant.
*/

-- First, delete the existing vesting events
DELETE FROM vesting_events 
WHERE grant_id = (SELECT id FROM grants WHERE grant_number = 'GR-20251101-000011');

SELECT 
  'Deleted existing vesting events' as status,
  COUNT(*) as remaining_events
FROM vesting_events
WHERE grant_id = (SELECT id FROM grants WHERE grant_number = 'GR-20251101-000011');

-- The frontend will auto-regenerate when you view the grant details
SELECT 
  'Next step: View the grant details in the UI to trigger auto-regeneration' as instruction;

