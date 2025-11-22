-- Test the fixed queries
-- Run this after fixing the column reference issues

-- 1. Simple count check
SELECT 'Total vesting events:' as description, COUNT(*) as count FROM vesting_events;

-- 2. Test the corrected frontend query
SELECT 
  ve.id,
  ve.vesting_date,
  ve.shares_to_vest,
  ve.status,
  ve.event_type,
  e.first_name_en,
  e.first_name_ar,
  e.last_name_en,
  e.last_name_ar,
  p.plan_name_en,
  p.plan_code,
  p.plan_type
FROM vesting_events ve
LEFT JOIN employees e ON ve.employee_id = e.id
LEFT JOIN grants g ON ve.grant_id = g.id
LEFT JOIN incentive_plans p ON g.plan_id = p.id
ORDER BY ve.created_at DESC
LIMIT 5;

-- 3. Check by company
SELECT 
  ve.company_id,
  c.company_name_en,
  COUNT(*) as events_count
FROM vesting_events ve
LEFT JOIN companies c ON ve.company_id = c.id
GROUP BY ve.company_id, c.company_name_en;

-- 4. If you want to test with a specific company ID, replace below:
-- SELECT 
--   ve.id,
--   ve.vesting_date,
--   ve.shares_to_vest,
--   ve.status,
--   COALESCE(e.first_name_en, e.first_name_ar, 'Unknown') || ' ' || COALESCE(e.last_name_en, e.last_name_ar, 'Employee') as employee_name,
--   p.plan_name_en
-- FROM vesting_events ve
-- LEFT JOIN employees e ON ve.employee_id = e.id
-- LEFT JOIN grants g ON ve.grant_id = g.id
-- LEFT JOIN incentive_plans p ON g.plan_id = p.id
-- WHERE ve.company_id = 'YOUR_COMPANY_ID_HERE'
-- ORDER BY ve.vesting_date ASC;
