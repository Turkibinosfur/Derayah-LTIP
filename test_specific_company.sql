-- Test query for the specific company ID from the logs
-- Company ID: b7c082c7-79ff-4a62-8c79-a2b2a08110b1

-- 1. Check if this company exists
SELECT 
  'Company check:' as step,
  id,
  company_name_en,
  company_name_ar,
  created_at
FROM companies 
WHERE id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1';

-- 2. Check vesting events for this specific company
SELECT 
  'Vesting events for this company:' as step,
  COUNT(*) as total_events
FROM vesting_events 
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1';

-- 3. Show sample vesting events for this company
SELECT 
  'Sample events:' as step,
  ve.id,
  ve.vesting_date,
  ve.shares_to_vest,
  ve.status,
  ve.event_type,
  COALESCE(e.first_name_en, e.first_name_ar, 'Unknown') || ' ' || COALESCE(e.last_name_en, e.last_name_ar, 'Employee') as employee_name,
  p.plan_name_en
FROM vesting_events ve
LEFT JOIN employees e ON ve.employee_id = e.id
LEFT JOIN grants g ON ve.grant_id = g.id
LEFT JOIN incentive_plans p ON g.plan_id = p.id
WHERE ve.company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'
ORDER BY ve.vesting_date ASC
LIMIT 10;

-- 4. Check all companies that have vesting events
SELECT 
  'All companies with vesting events:' as step,
  ve.company_id,
  c.company_name_en,
  COUNT(*) as events_count
FROM vesting_events ve
LEFT JOIN companies c ON ve.company_id = c.id
GROUP BY ve.company_id, c.company_name_en
ORDER BY events_count DESC;
