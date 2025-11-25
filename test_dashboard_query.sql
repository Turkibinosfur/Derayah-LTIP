-- Test Dashboard Query
-- This script tests the exact query used by EmployeeDashboard.tsx

-- 1. Get employee by user_id (this is what the dashboard does)
SELECT 
  '=== EMPLOYEE BY USER_ID ===' as test,
  e.id,
  e.company_id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id
FROM employees e
WHERE e.user_id = (
  SELECT id FROM auth.users WHERE email = 'employee@example.com'
);

-- 2. Test the grants query (this is what the dashboard does)
SELECT 
  '=== GRANTS QUERY ===' as test,
  g.id,
  g.total_shares,
  g.vested_shares,
  g.remaining_unvested_shares,
  g.status,
  g.grant_number
FROM grants g
JOIN employees e ON g.employee_id = e.id
WHERE e.user_id = (
  SELECT id FROM auth.users WHERE email = 'employee@example.com'
)
AND g.status IN ('active', 'pending_signature');

-- 3. Test company query
SELECT 
  '=== COMPANY QUERY ===' as test,
  c.id,
  c.tadawul_symbol
FROM companies c
WHERE c.id = (
  SELECT e.company_id 
  FROM employees e 
  WHERE e.user_id = (
    SELECT id FROM auth.users WHERE email = 'employee@example.com'
  )
);

-- 4. Check if there are any RLS issues
SELECT 
  '=== RLS POLICIES ===' as test,
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies 
WHERE tablename IN ('employees', 'grants', 'companies')
ORDER BY tablename, policyname;

-- 5. Check if the user has the right permissions
SELECT 
  '=== USER PERMISSIONS ===' as test,
  u.id,
  u.email,
  u.email_confirmed_at,
  u.created_at
FROM auth.users u
WHERE u.email = 'employee@example.com';
