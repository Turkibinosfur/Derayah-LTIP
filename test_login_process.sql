-- Test Login Process
-- This script tests the login process step by step

-- 1. Test basic connection
SELECT 
  '=== CONNECTION TEST ===' as test,
  now() as current_time,
  current_user as current_user,
  current_database() as current_database;

-- 2. Test auth.users table access
SELECT 
  '=== AUTH USERS TEST ===' as test,
  COUNT(*) as total_users,
  COUNT(CASE WHEN email = 'test3@test.com' THEN 1 END) as target_user_exists
FROM auth.users;

-- 3. Test employees table access
SELECT 
  '=== EMPLOYEES TEST ===' as test,
  COUNT(*) as total_employees,
  COUNT(CASE WHEN email = 'test3@test.com' THEN 1 END) as target_employee_exists
FROM employees;

-- 4. Test the exact query used by EmployeeLogin.tsx
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
  SELECT id FROM auth.users WHERE email = 'test3@test.com'
);

-- 5. Test if we can find the employee by email
SELECT 
  '=== EMPLOYEE BY EMAIL TEST ===' as test,
  e.id,
  e.company_id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id,
  e.portal_access_enabled
FROM employees e
WHERE e.email = 'test3@test.com';

-- 6. Test if we can find the auth user by email
SELECT 
  '=== AUTH USER BY EMAIL TEST ===' as test,
  id,
  email,
  email_confirmed_at,
  created_at
FROM auth.users 
WHERE email = 'test3@test.com';

-- 7. Test the linking between employee and auth user
SELECT 
  '=== LINKING TEST ===' as test,
  e.id as employee_id,
  e.email as employee_email,
  e.user_id,
  u.id as auth_user_id,
  u.email as auth_email,
  CASE 
    WHEN e.user_id = u.id THEN 'Linked' 
    ELSE 'Not linked' 
  END as link_status
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
WHERE e.email = 'test3@test.com';

-- 8. Test the complete login flow
SELECT 
  '=== COMPLETE LOGIN FLOW TEST ===' as test,
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM employees e 
      WHERE e.email = 'test3@test.com'
        AND e.portal_access_enabled = true
        AND e.user_id IS NOT NULL
        AND EXISTS (
          SELECT 1 
          FROM auth.users u 
          WHERE u.id = e.user_id 
            AND u.email = 'test3@test.com'
        )
    ) 
    THEN 'SUCCESS: Login should work' 
    ELSE 'FAILED: Login will fail' 
  END as login_result;
