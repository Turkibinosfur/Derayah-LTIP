-- Diagnose wajehah.sa@gmail.com Login Issues
-- This script checks the current state and identifies the problem

-- 1. Check if auth user exists
SELECT 
  '=== AUTH USER CHECK ===' as step,
  id,
  email,
  email_confirmed_at,
  created_at,
  last_sign_in_at
FROM auth.users 
WHERE email = 'wajehah.sa@gmail.com';

-- 2. Check if employee record exists
SELECT 
  '=== EMPLOYEE RECORD CHECK ===' as step,
  id,
  first_name_en,
  last_name_en,
  email,
  user_id,
  portal_access_enabled,
  company_id
FROM employees 
WHERE email = 'wajehah.sa@gmail.com';

-- 3. Check if company exists
SELECT 
  '=== COMPANY CHECK ===' as step,
  id,
  company_name_en,
  status
FROM companies 
WHERE company_name_en = 'Derayah Financial';

-- 4. Test the exact query used by EmployeeLogin.tsx
SELECT 
  '=== EMPLOYEE LOGIN QUERY TEST ===' as step,
  e.id,
  e.company_id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id
FROM employees e
WHERE e.user_id = (
  SELECT id FROM auth.users WHERE email = 'wajehah.sa@gmail.com'
);

-- 5. Check RLS policies
SELECT 
  '=== RLS POLICIES CHECK ===' as step,
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies 
WHERE tablename IN ('employees', 'grants', 'companies')
ORDER BY tablename, policyname;

-- 6. Check if there are any missing indexes
SELECT 
  '=== INDEX CHECK ===' as step,
  indexname,
  indexdef
FROM pg_indexes 
WHERE tablename = 'employees' 
  AND schemaname = 'public';

-- 7. Check if there are any schema issues
SELECT 
  '=== SCHEMA CHECK ===' as step,
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'employees' 
  AND table_schema = 'public'
  AND column_name IN ('id', 'company_id', 'first_name_en', 'last_name_en', 'email', 'user_id')
ORDER BY ordinal_position;
