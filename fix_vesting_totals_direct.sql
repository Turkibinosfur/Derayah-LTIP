-- Fix existing vesting_events so the sum of shares_to_vest per grant equals grants.total_shares
-- Run this directly in your database to fix the 48 vs 50 shares issue

BEGIN;

-- Create temp table for reporting
CREATE TEMPORARY TABLE IF NOT EXISTS tmp_vesting_fix_report (
  grant_id uuid,
  last_event_id uuid,
  before_last_shares bigint,
  after_last_shares bigint
) ON COMMIT DROP;

-- Create temp table for rows to fix
CREATE TEMPORARY TABLE IF NOT EXISTS tmp_to_fix (
  grant_id uuid,
  last_event_id uuid,
  current_last_shares bigint,
  new_last_shares bigint
) ON COMMIT DROP;

-- Clear any existing data
TRUNCATE tmp_to_fix;

-- Find grants where vesting events don't sum to total_shares
INSERT INTO tmp_to_fix (grant_id, last_event_id, current_last_shares, new_last_shares)
WITH agg AS (
  SELECT
    ve.grant_id,
    SUM(ve.shares_to_vest) as current_total,
    (SELECT v2.id 
     FROM vesting_events v2 
     WHERE v2.grant_id = ve.grant_id 
     ORDER BY v2.sequence_number DESC 
     LIMIT 1) as last_event_id,
    (SELECT v3.shares_to_vest 
     FROM vesting_events v3 
     WHERE v3.grant_id = ve.grant_id 
     ORDER BY v3.sequence_number DESC 
     LIMIT 1) as current_last_shares
  FROM vesting_events ve
  GROUP BY ve.grant_id
), calc AS (
  SELECT
    a.grant_id,
    a.last_event_id,
    a.current_last_shares::bigint as current_last_shares,
    (g.total_shares - (a.current_total - a.current_last_shares))::bigint as new_last_shares
  FROM agg a
  JOIN grants g ON g.id = a.grant_id
)
SELECT grant_id, last_event_id, current_last_shares, new_last_shares
FROM calc
WHERE new_last_shares >= 0 AND new_last_shares <> current_last_shares;

-- Update the last event for each grant to make totals match
UPDATE vesting_events ve
SET shares_to_vest = tf.new_last_shares,
    updated_at = NOW()
FROM tmp_to_fix tf
WHERE ve.id = tf.last_event_id;

-- Report what was changed
INSERT INTO tmp_vesting_fix_report (grant_id, last_event_id, before_last_shares, after_last_shares)
SELECT tf.grant_id, tf.last_event_id, tf.current_last_shares, tf.new_last_shares
FROM tmp_to_fix tf;

-- Show the report
SELECT 
  grant_id,
  last_event_id,
  before_last_shares,
  after_last_shares,
  (after_last_shares - before_last_shares) as adjustment
FROM tmp_vesting_fix_report
ORDER BY grant_id;

COMMIT;

-- Verify the fix worked
SELECT 
  g.id as grant_id,
  g.grant_number,
  g.total_shares,
  SUM(ve.shares_to_vest) as calculated_total,
  (g.total_shares - SUM(ve.shares_to_vest)) as difference
FROM grants g
LEFT JOIN vesting_events ve ON ve.grant_id = g.id
GROUP BY g.id, g.grant_number, g.total_shares
HAVING g.total_shares != SUM(ve.shares_to_vest)
ORDER BY g.grant_number;






