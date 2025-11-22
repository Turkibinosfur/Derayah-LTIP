-- Diagnose Employee Login Issues
-- This script checks the current state of employee records and auth users

-- 1. Check if wajehah.sa@gmail.com exists in auth.users
SELECT 
  '=== AUTH USERS CHECK ===' as step,
  id,
  email,
  email_confirmed_at,
  created_at,
  last_sign_in_at
FROM auth.users 
WHERE email = 'wajehah.sa@gmail.com';

-- 2. Check if employee record exists for wajehah.sa@gmail.com
SELECT 
  '=== EMPLOYEE RECORDS CHECK ===' as step,
  id,
  first_name_en,
  last_name_en,
  email,
  user_id,
  portal_access_enabled,
  portal_username,
  company_id
FROM employees 
WHERE email = 'wajehah.sa@gmail.com';

-- 3. Check if there are any employees with user_id linked to wajehah.sa@gmail.com
SELECT 
  '=== EMPLOYEE BY USER_ID CHECK ===' as step,
  e.id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id,
  u.email as auth_email
FROM employees e
JOIN auth.users u ON e.user_id = u.id
WHERE u.email = 'wajehah.sa@gmail.com';

-- 4. Check all employees in the company
SELECT 
  '=== ALL EMPLOYEES ===' as step,
  id,
  first_name_en,
  last_name_en,
  email,
  user_id,
  portal_access_enabled,
  company_id
FROM employees 
WHERE company_id = (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial')
ORDER BY created_at;

-- 5. Check if there are any auth users with similar emails
SELECT 
  '=== SIMILAR EMAILS ===' as step,
  id,
  email,
  email_confirmed_at
FROM auth.users 
WHERE email LIKE '%wajehah%' OR email LIKE '%fatima%'
ORDER BY email;

-- 6. Check company_users table
SELECT 
  '=== COMPANY USERS ===' as step,
  cu.id,
  cu.role,
  cu.is_active,
  u.email,
  c.company_name_en
FROM company_users cu
JOIN auth.users u ON cu.user_id = u.id
JOIN companies c ON cu.company_id = c.id
WHERE c.company_name_en = 'Derayah Financial';
