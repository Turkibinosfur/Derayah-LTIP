-- Fix grants.vested_shares to match actual vesting events
-- This ensures ESOP pools show the correct vested amounts

BEGIN;

-- Create temp table for reporting
CREATE TEMPORARY TABLE IF NOT EXISTS tmp_grants_fix_report (
  grant_id uuid,
  grant_number text,
  old_vested_shares numeric,
  new_vested_shares bigint,
  vesting_events_count int
) ON COMMIT DROP;

-- Update grants.vested_shares based on actual vesting events
-- Count vested, transferred, and exercised as all representing vested shares
WITH vesting_totals AS (
  SELECT 
    ve.grant_id,
    SUM(CASE WHEN ve.status IN ('vested', 'transferred', 'exercised') THEN ve.shares_to_vest ELSE 0 END) as actual_vested,
    COUNT(*) as total_events
  FROM vesting_events ve
  GROUP BY ve.grant_id
),
grants_to_update AS (
  SELECT 
    g.id as grant_id,
    g.grant_number,
    g.vested_shares as old_vested,
    COALESCE(vt.actual_vested, 0) as new_vested,
    COALESCE(vt.total_events, 0) as event_count
  FROM grants g
  LEFT JOIN vesting_totals vt ON vt.grant_id = g.id
  WHERE g.vested_shares != COALESCE(vt.actual_vested, 0)
)
UPDATE grants 
SET 
  vested_shares = gtu.new_vested,
  remaining_unvested_shares = (grants.total_shares - gtu.new_vested),
  updated_at = NOW()
FROM grants_to_update gtu
WHERE grants.id = gtu.grant_id;

-- Report what was changed
INSERT INTO tmp_grants_fix_report (grant_id, grant_number, old_vested_shares, new_vested_shares, vesting_events_count)
WITH vesting_totals AS (
  SELECT 
    ve.grant_id,
    SUM(CASE WHEN ve.status IN ('vested', 'transferred', 'exercised') THEN ve.shares_to_vest ELSE 0 END) as actual_vested,
    COUNT(*) as total_events
  FROM vesting_events ve
  GROUP BY ve.grant_id
)
SELECT 
  g.id as grant_id,
  g.grant_number,
  g.vested_shares as old_vested,
  COALESCE(vt.actual_vested, 0) as new_vested,
  COALESCE(vt.total_events, 0) as event_count
FROM grants g
LEFT JOIN vesting_totals vt ON vt.grant_id = g.id
WHERE g.vested_shares != COALESCE(vt.actual_vested, 0);

-- Show the report
SELECT 
  grant_number,
  old_vested_shares,
  new_vested_shares,
  (new_vested_shares - old_vested_shares) as adjustment,
  vesting_events_count
FROM tmp_grants_fix_report
ORDER BY grant_number;

-- Verify the fix worked
SELECT 
  g.grant_number,
  g.total_shares,
  g.vested_shares as grants_vested,
  COALESCE(SUM(CASE WHEN ve.status IN ('vested', 'transferred', 'exercised') THEN ve.shares_to_vest ELSE 0 END), 0) as events_vested,
  (g.vested_shares - COALESCE(SUM(CASE WHEN ve.status IN ('vested', 'transferred', 'exercised') THEN ve.shares_to_vest ELSE 0 END), 0)) as difference
FROM grants g
LEFT JOIN vesting_events ve ON ve.grant_id = g.id
GROUP BY g.id, g.grant_number, g.total_shares, g.vested_shares
HAVING g.vested_shares != COALESCE(SUM(CASE WHEN ve.status IN ('vested', 'transferred', 'exercised') THEN ve.shares_to_vest ELSE 0 END), 0)
ORDER BY g.grant_number;

COMMIT;

