-- Quick Fix Test5
-- This script quickly diagnoses and fixes test5@test.com login issue

-- 1. Check if test5@test.com exists in employees table
SELECT 
  '=== CHECKING EMPLOYEE RECORD ===' as step,
  CASE 
    WHEN EXISTS (SELECT 1 FROM employees WHERE email = 'test5@test.com') 
    THEN 'Employee record EXISTS' 
    ELSE 'Employee record NOT FOUND' 
  END as employee_status;

-- 2. Check if test5@test.com exists in auth.users table
SELECT 
  '=== CHECKING AUTH USER ===' as step,
  CASE 
    WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = 'test5@test.com') 
    THEN 'Auth user EXISTS' 
    ELSE 'Auth user NOT FOUND' 
  END as auth_status;

-- 3. Show current state of test5@test.com
SELECT 
  '=== CURRENT STATE ===' as step,
  e.id as employee_id,
  e.first_name_en,
  e.last_name_en,
  e.email as employee_email,
  e.portal_access_enabled,
  e.portal_username,
  e.portal_password,
  e.user_id,
  u.email as auth_email,
  u.email_confirmed_at,
  CASE 
    WHEN e.portal_access_enabled = true AND e.user_id IS NOT NULL AND u.id IS NOT NULL 
    THEN 'Can Login' 
    ELSE 'Cannot Login' 
  END as login_status
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
WHERE e.email = 'test5@test.com';

-- 4. If employee record doesn't exist, create it
INSERT INTO employees (
  id,
  company_id,
  first_name_en,
  last_name_en,
  email,
  portal_access_enabled,
  portal_username,
  portal_password,
  created_at,
  updated_at
)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial' LIMIT 1),
  'Test',
  'Five',
  'test5@test.com',
  true,
  'test5',
  'Employee123!',
  now(),
  now()
WHERE NOT EXISTS (SELECT 1 FROM employees WHERE email = 'test5@test.com');

-- 5. Check if auth user exists, if not, provide instructions
SELECT 
  '=== AUTH USER CHECK ===' as step,
  CASE 
    WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = 'test5@test.com') 
    THEN 'Auth user exists - can proceed with linking'
    ELSE 'Auth user NOT FOUND - needs manual creation'
  END as auth_status;

-- 6. If auth user exists, link it to employee
UPDATE employees 
SET 
  user_id = (SELECT id FROM auth.users WHERE email = 'test5@test.com'),
  portal_access_enabled = true,
  portal_username = 'test5',
  portal_password = 'Employee123!',
  updated_at = now()
WHERE email = 'test5@test.com' 
  AND EXISTS (SELECT 1 FROM auth.users WHERE email = 'test5@test.com');

-- 7. Final verification
SELECT 
  '=== FINAL VERIFICATION ===' as step,
  e.id as employee_id,
  e.first_name_en,
  e.last_name_en,
  e.email as employee_email,
  e.portal_access_enabled,
  e.portal_username,
  e.portal_password,
  e.user_id,
  u.email as auth_email,
  u.email_confirmed_at,
  CASE 
    WHEN e.portal_access_enabled = true AND e.user_id IS NOT NULL AND u.id IS NOT NULL 
    THEN 'Can Login - Ready to test' 
    WHEN e.portal_access_enabled = true AND e.user_id IS NULL
    THEN 'Cannot Login - Auth user needs creation'
    ELSE 'Cannot Login - Portal access not enabled'
  END as login_status
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
WHERE e.email = 'test5@test.com';

-- 8. Show instructions if auth user doesn't exist
SELECT 
  '=== INSTRUCTIONS ===' as step,
  CASE 
    WHEN NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'test5@test.com') 
    THEN 'MANUAL ACTION REQUIRED: Go to Supabase Dashboard > Authentication > Users > Add user > Email: test5@test.com > Password: Employee123! > Set Email Confirm to true > Create user'
    ELSE 'Auth user exists - should be able to login now'
  END as instructions;
