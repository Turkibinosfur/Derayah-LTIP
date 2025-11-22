-- Check All Employees Auth Status
-- This script checks all employees and their corresponding auth users

-- 1. Check all employees with portal access enabled
SELECT 
  '=== EMPLOYEES WITH PORTAL ACCESS ===' as step,
  e.id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id,
  e.portal_access_enabled,
  e.portal_username,
  e.portal_password,
  CASE 
    WHEN u.id IS NOT NULL THEN 'Auth user exists' 
    ELSE 'Auth user missing' 
  END as auth_status,
  u.email as auth_email,
  u.email_confirmed_at
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
WHERE e.portal_access_enabled = true
ORDER BY e.created_at DESC;

-- 2. Check all auth users
SELECT 
  '=== ALL AUTH USERS ===' as step,
  id,
  email,
  email_confirmed_at,
  created_at,
  last_sign_in_at
FROM auth.users 
ORDER BY created_at DESC;

-- 3. Check employees without linked auth users
SELECT 
  '=== EMPLOYEES WITHOUT AUTH USERS ===' as step,
  e.id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id,
  e.portal_access_enabled,
  e.portal_username,
  e.portal_password
FROM employees e
WHERE e.portal_access_enabled = true 
  AND e.user_id IS NULL
ORDER BY e.created_at DESC;

-- 4. Check auth users without employee records
SELECT 
  '=== AUTH USERS WITHOUT EMPLOYEE RECORDS ===' as step,
  u.id,
  u.email,
  u.email_confirmed_at,
  u.created_at
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM employees e 
  WHERE e.user_id = u.id
)
ORDER BY u.created_at DESC;

-- 5. Summary
SELECT 
  '=== SUMMARY ===' as step,
  COUNT(*) as total_employees,
  COUNT(CASE WHEN portal_access_enabled = true THEN 1 END) as employees_with_portal_access,
  COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as employees_with_linked_auth_users,
  COUNT(CASE WHEN portal_access_enabled = true AND user_id IS NULL THEN 1 END) as employees_without_auth_users
FROM employees;
