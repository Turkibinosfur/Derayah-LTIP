-- Check Auth Users and Credentials
-- This script shows all auth users and their credentials

-- 1. Show all auth users with their details
SELECT 
  '=== ALL AUTH USERS ===' as step,
  id,
  email,
  email_confirmed_at,
  created_at,
  last_sign_in_at,
  raw_user_meta_data,
  raw_app_meta_data
FROM auth.users 
ORDER BY created_at DESC;

-- 2. Show employees with portal access and their auth status
SELECT 
  '=== EMPLOYEES WITH PORTAL ACCESS ===' as step,
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
  u.created_at as auth_created_at,
  CASE 
    WHEN e.portal_access_enabled = true AND e.user_id IS NOT NULL AND u.id IS NOT NULL 
    THEN 'Can Login' 
    ELSE 'Cannot Login' 
  END as login_status
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
WHERE e.portal_access_enabled = true
ORDER BY e.created_at DESC;

-- 3. Show employees without auth users
SELECT 
  '=== EMPLOYEES WITHOUT AUTH USERS ===' as step,
  e.id as employee_id,
  e.first_name_en,
  e.last_name_en,
  e.email as employee_email,
  e.portal_username,
  e.portal_password,
  'Needs Auth User Creation' as status
FROM employees e
WHERE e.portal_access_enabled = true 
  AND e.user_id IS NULL
ORDER BY e.created_at DESC;

-- 4. Show auth users without employee records
SELECT 
  '=== AUTH USERS WITHOUT EMPLOYEE RECORDS ===' as step,
  u.id as auth_user_id,
  u.email as auth_email,
  u.email_confirmed_at,
  u.created_at as auth_created_at,
  'No Employee Record' as status
FROM auth.users u
LEFT JOIN employees e ON e.user_id = u.id
WHERE e.id IS NULL
ORDER BY u.created_at DESC;

-- 5. Show summary statistics
SELECT 
  '=== SUMMARY STATISTICS ===' as step,
  (SELECT COUNT(*) FROM auth.users) as total_auth_users,
  (SELECT COUNT(*) FROM employees WHERE portal_access_enabled = true) as employees_with_portal_access,
  (SELECT COUNT(*) FROM employees WHERE portal_access_enabled = true AND user_id IS NOT NULL) as employees_with_linked_auth_users,
  (SELECT COUNT(*) FROM employees WHERE portal_access_enabled = true AND user_id IS NULL) as employees_without_auth_users;

-- 6. Show detailed credentials for each employee
SELECT 
  '=== EMPLOYEE CREDENTIALS ===' as step,
  e.id as employee_id,
  e.first_name_en,
  e.last_name_en,
  e.email as employee_email,
  e.portal_username,
  e.portal_password,
  e.portal_access_enabled,
  u.email as auth_email,
  u.email_confirmed_at,
  CASE 
    WHEN e.portal_access_enabled = true AND e.user_id IS NOT NULL AND u.id IS NOT NULL 
    THEN 'Ready to Login' 
    WHEN e.portal_access_enabled = true AND e.user_id IS NULL
    THEN 'Needs Auth User Creation'
    ELSE 'Portal Access Disabled'
  END as status
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
ORDER BY e.created_at DESC;
