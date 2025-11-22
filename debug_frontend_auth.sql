-- Debug frontend authentication and company linking
-- This helps identify if the issue is with user/company association

-- Check all auth users and their company associations
SELECT 
  au.id as auth_user_id,
  au.email,
  cu.company_id,
  cu.role,
  c.company_name_en,
  cu.created_at as linked_at
FROM auth.users au
LEFT JOIN company_users cu ON au.id = cu.user_id
LEFT JOIN companies c ON cu.company_id = c.id
ORDER BY au.created_at DESC
LIMIT 10;

-- If you know your email, you can check specifically:
-- SELECT 
--   au.id as auth_user_id,
--   au.email,
--   cu.company_id,
--   cu.role,
--   c.company_name_en
-- FROM auth.users au
-- LEFT JOIN company_users cu ON au.id = cu.user_id
-- LEFT JOIN companies c ON cu.company_id = c.id
-- WHERE au.email = 'your-email@example.com';

-- Check if there are any vesting events for each company
SELECT 
  c.id as company_id,
  c.company_name_en,
  COUNT(ve.id) as vesting_events_count,
  COUNT(DISTINCT g.id) as grants_count,
  COUNT(DISTINCT e.id) as employees_count
FROM companies c
LEFT JOIN vesting_events ve ON c.id = ve.company_id
LEFT JOIN grants g ON c.id = g.company_id AND g.status = 'active'
LEFT JOIN employees e ON c.id = e.company_id
GROUP BY c.id, c.company_name_en
ORDER BY vesting_events_count DESC;
