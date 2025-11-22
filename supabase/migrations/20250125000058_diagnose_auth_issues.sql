/*
  # Diagnose Auth Issues
  
  This migration checks the current state of authentication and identifies issues
  that might be causing login lag for admin@derayah.com
*/

-- Check if admin user exists
SELECT 
  '=== ADMIN USER CHECK ===' as info;

SELECT 
  id,
  email,
  email_confirmed_at,
  created_at,
  last_sign_in_at,
  is_super_admin
FROM auth.users 
WHERE email = 'admin@derayah.com';

-- Check company_users table for admin
SELECT 
  '=== COMPANY USERS CHECK ===' as info;

SELECT 
  cu.id,
  cu.company_id,
  cu.user_id,
  cu.role,
  cu.is_active,
  c.company_name_en
FROM company_users cu
JOIN companies c ON cu.company_id = c.id
JOIN auth.users u ON cu.user_id = u.id
WHERE u.email = 'admin@derayah.com';

-- Check if user_roles view works
SELECT 
  '=== USER ROLES VIEW CHECK ===' as info;

SELECT 
  user_id,
  email,
  company_id,
  role,
  user_type
FROM user_roles
WHERE email = 'admin@derayah.com';

-- Check RLS policies status
SELECT 
  '=== RLS POLICIES STATUS ===' as info;

SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename IN ('companies', 'company_users', 'employees')
ORDER BY tablename, policyname;

-- Check for any blocking queries or locks
SELECT 
  '=== ACTIVE QUERIES ===' as info;

SELECT 
  pid,
  state,
  query_start,
  query
FROM pg_stat_activity 
WHERE state = 'active' 
AND query NOT LIKE '%pg_stat_activity%'
AND query NOT LIKE '%pg_policies%'
ORDER BY query_start;
