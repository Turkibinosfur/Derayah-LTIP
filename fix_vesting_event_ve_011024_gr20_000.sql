-- Fix for vesting event VE-011024-GR20-000
-- This script checks the event status and can manually set performance_condition_met if needed

-- First, check the current state of the event
SELECT 
  ve.id,
  ve.event_id,
  ve.status,
  ve.event_type,
  ve.performance_condition_met,
  ve.shares_to_vest,
  ve.vesting_date,
  g.grant_number,
  g.vested_shares,
  g.remaining_unvested_shares,
  g.total_shares,
  -- Check if grant has linked performance metrics
  EXISTS (
    SELECT 1 
    FROM grant_performance_metrics gpm 
    WHERE gpm.grant_id = g.id
  ) as has_performance_metrics
FROM vesting_events ve
JOIN grants g ON g.id = ve.grant_id
WHERE ve.id = (
  SELECT id FROM vesting_events 
  WHERE grant_id = (
    SELECT id FROM grants WHERE grant_number = 'GR-20251102-000015'
  )
  AND sequence_number = 0
  LIMIT 1
);

-- If the event doesn't have linked performance metrics, we can set performance_condition_met to true
-- This allows the event to be vested without the performance confirmation modal
UPDATE vesting_events
SET 
  performance_condition_met = true,
  performance_notes = 'Performance condition confirmed - no linked metrics require confirmation',
  updated_at = now()
WHERE id = (
  SELECT id FROM vesting_events 
  WHERE grant_id = (
    SELECT id FROM grants WHERE grant_number = 'GR-20251102-000015'
  )
  AND sequence_number = 0
  LIMIT 1
)
AND NOT EXISTS (
  SELECT 1 
  FROM grant_performance_metrics gpm 
  WHERE gpm.grant_id = (
    SELECT grant_id FROM vesting_events 
    WHERE id = (
      SELECT id FROM vesting_events 
      WHERE grant_id = (
        SELECT id FROM grants WHERE grant_number = 'GR-20251102-000015'
      )
      AND sequence_number = 0
      LIMIT 1
    )
  )
);

-- Verify the update
SELECT 
  ve.id,
  ve.status,
  ve.event_type,
  ve.performance_condition_met,
  ve.performance_notes
FROM vesting_events ve
WHERE ve.id = (
  SELECT id FROM vesting_events 
  WHERE grant_id = (
    SELECT id FROM grants WHERE grant_number = 'GR-20251102-000015'
  )
  AND sequence_number = 0
  LIMIT 1
);

