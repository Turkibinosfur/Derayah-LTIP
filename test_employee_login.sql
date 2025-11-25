-- Test Employee Login Setup
-- This script verifies that the employee login should work

-- 1. Check auth user
SELECT 
  '=== AUTH USER CHECK ===' as test,
  id,
  email,
  email_confirmed_at,
  created_at
FROM auth.users 
WHERE email = 'employee@example.com';

-- 2. Check employee record
SELECT 
  '=== EMPLOYEE RECORD CHECK ===' as test,
  id,
  first_name_en,
  last_name_en,
  email,
  user_id,
  portal_access_enabled,
  portal_username,
  company_id
FROM employees 
WHERE email = 'employee@example.com';

-- 3. Check if employee has grants
SELECT 
  '=== GRANTS CHECK ===' as test,
  g.id,
  g.grant_number,
  g.total_shares,
  g.status,
  ip.plan_name_en
FROM grants g
JOIN employees e ON g.employee_id = e.id
LEFT JOIN incentive_plans ip ON g.plan_id = ip.id
WHERE e.email = 'employee@example.com';

-- 4. Check company
SELECT 
  '=== COMPANY CHECK ===' as test,
  id,
  company_name_en,
  status
FROM companies 
WHERE company_name_en = 'Derayah Financial';

-- 5. Test the exact query that EmployeeLogin.tsx uses
SELECT 
  '=== EMPLOYEE LOGIN QUERY TEST ===' as test,
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
