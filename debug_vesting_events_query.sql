-- Quick diagnostic queries to run in Supabase SQL Editor
-- Run these one by one to understand what's happening

-- 1. Check table counts
SELECT 
  'companies' as table_name, COUNT(*) as count FROM companies
UNION ALL
SELECT 
  'employees' as table_name, COUNT(*) as count FROM employees
UNION ALL
SELECT 
  'incentive_plans' as table_name, COUNT(*) as count FROM incentive_plans
UNION ALL
SELECT 
  'grants' as table_name, COUNT(*) as count FROM grants
UNION ALL
SELECT 
  'vesting_events' as table_name, COUNT(*) as count FROM vesting_events;

-- 2. Check grant statuses
SELECT 
  status, 
  COUNT(*) as count 
FROM grants 
GROUP BY status;

-- 3. Check active grants details
SELECT 
  g.id,
  g.status,
  g.total_shares,
  g.vesting_start_date,
  COALESCE(e.first_name_en, e.first_name_ar, 'Unknown') || ' ' || COALESCE(e.last_name_en, e.last_name_ar, 'Employee') as employee_name,
  p.plan_name_en,
  p.plan_code,
  p.vesting_schedule_template_id,
  p.vesting_config
FROM grants g
LEFT JOIN employees e ON g.employee_id = e.id
LEFT JOIN incentive_plans p ON g.plan_id = p.id
WHERE g.status = 'active'
ORDER BY g.created_at DESC
LIMIT 10;

-- 4. Check if vesting events exist for any grants
SELECT 
  g.id as grant_id,
  COUNT(ve.id) as vesting_events_count
FROM grants g
LEFT JOIN vesting_events ve ON g.id = ve.grant_id
WHERE g.status = 'active'
GROUP BY g.id
ORDER BY g.created_at DESC
LIMIT 10;

-- 5. Test vesting event generation for one grant (replace 'GRANT_ID_HERE' with actual grant ID)
-- SELECT generate_vesting_events_for_grant('GRANT_ID_HERE');

-- 6. Check vesting schedule templates
SELECT 
  id,
  name,
  total_duration_months,
  cliff_months,
  vesting_frequency,
  is_template
FROM vesting_schedules
WHERE is_template = true
ORDER BY created_at DESC;
