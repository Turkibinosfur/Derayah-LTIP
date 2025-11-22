-- Debug query to check multiple due vesting events
-- This will help identify grants with multiple overdue events

-- Step 1: Find grants with multiple due events
WITH due_events AS (
  SELECT 
    vs.grant_id,
    g.grant_number,
    COUNT(*) as due_event_count,
    STRING_AGG(
      CONCAT('Seq:', vs.sequence_number, ' Date:', vs.vesting_date, ' Shares:', vs.shares_to_vest), 
      '; ' 
      ORDER BY vs.sequence_number
    ) as due_events_detail,
    SUM(vs.shares_to_vest) as total_due_shares,
    MIN(vs.vesting_date) as earliest_due_date,
    MAX(vs.vesting_date) as latest_due_date,
    CURRENT_DATE - MIN(vs.vesting_date) as days_overdue
  FROM vesting_schedules vs
  JOIN grants g ON vs.grant_id = g.id
  WHERE 
    vs.vesting_date <= CURRENT_DATE 
    AND vs.status = 'pending'
  GROUP BY vs.grant_id, g.grant_number
  HAVING COUNT(*) >= 2
),
grant_summary AS (
  SELECT 
    de.*,
    g.total_shares,
    g.vested_shares,
    e.first_name_en || ' ' || e.last_name_en as employee_name,
    e.email,
    c.company_name_en
  FROM due_events de
  JOIN grants g ON de.grant_id = g.id
  JOIN employees e ON g.employee_id = e.id
  JOIN companies c ON e.company_id = c.id
)
SELECT * FROM grant_summary
ORDER BY due_event_count DESC, days_overdue DESC;

-- Step 2: Check for potential duplicate vesting events
SELECT 
  vs1.grant_id,
  g.grant_number,
  vs1.sequence_number,
  COUNT(*) as duplicate_count,
  STRING_AGG(vs1.id::text, ', ') as record_ids,
  STRING_AGG(vs1.vesting_date::text, ', ') as vesting_dates,
  STRING_AGG(vs1.shares_to_vest::text, ', ') as shares_amounts
FROM vesting_schedules vs1
JOIN grants g ON vs1.grant_id = g.id
GROUP BY vs1.grant_id, g.grant_number, vs1.sequence_number
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
