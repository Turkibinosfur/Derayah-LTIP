-- Find grants that don't have any vesting events
-- This helps identify grants that need vesting events generated

SELECT 
  g.id as grant_id,
  g.grant_number,
  g.total_shares,
  g.vested_shares,
  g.remaining_unvested_shares,
  g.status as grant_status,
  g.grant_date,
  g.vesting_start_date,
  g.vesting_end_date,
  e.first_name_en || ' ' || e.last_name_en as employee_name,
  e.employee_number,
  ip.plan_name_en,
  ip.plan_code,
  ip.plan_type,
  c.company_name_en,
  g.created_at,
  g.updated_at,
  CASE 
    WHEN g.status = 'pending_signature' THEN 'Grant not yet accepted by employee'
    WHEN g.status = 'active' THEN 'Active grant - vesting events should exist'
    WHEN g.status = 'cancelled' THEN 'Grant cancelled - may not need vesting events'
    WHEN g.status = 'forfeited' THEN 'Grant forfeited - may not need vesting events'
    ELSE 'Unknown status'
  END as reason_for_no_events
FROM grants g
INNER JOIN employees e ON e.id = g.employee_id
INNER JOIN incentive_plans ip ON ip.id = g.plan_id
INNER JOIN companies c ON c.id = g.company_id
LEFT JOIN vesting_events ve ON ve.grant_id = g.id
WHERE ve.id IS NULL
ORDER BY 
  g.created_at DESC,
  c.company_name_en,
  ip.plan_name_en,
  g.grant_number;

-- Summary by company
SELECT 
  c.company_name_en,
  COUNT(*) as grants_without_events,
  SUM(g.total_shares) as total_shares_affected
FROM grants g
INNER JOIN companies c ON c.id = g.company_id
LEFT JOIN vesting_events ve ON ve.grant_id = g.id
WHERE ve.id IS NULL
GROUP BY c.id, c.company_name_en
ORDER BY grants_without_events DESC;

-- Summary by grant status
SELECT 
  g.status,
  COUNT(*) as grants_without_events,
  SUM(g.total_shares) as total_shares_affected
FROM grants g
LEFT JOIN vesting_events ve ON ve.grant_id = g.id
WHERE ve.id IS NULL
GROUP BY g.status
ORDER BY grants_without_events DESC;

-- Summary by plan
SELECT 
  ip.plan_name_en,
  ip.plan_code,
  COUNT(*) as grants_without_events,
  SUM(g.total_shares) as total_shares_affected
FROM grants g
INNER JOIN incentive_plans ip ON ip.id = g.plan_id
LEFT JOIN vesting_events ve ON ve.grant_id = g.id
WHERE ve.id IS NULL
GROUP BY ip.id, ip.plan_name_en, ip.plan_code
ORDER BY grants_without_events DESC;

