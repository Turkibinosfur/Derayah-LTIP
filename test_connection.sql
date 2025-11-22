-- Test Database Connection
-- This script tests if the database is accessible and working

-- 1. Test basic connection
SELECT 
  '=== CONNECTION TEST ===' as test,
  now() as current_time,
  current_user as current_user,
  current_database() as current_database;

-- 2. Test if we can read from auth.users
SELECT 
  '=== AUTH USERS TEST ===' as test,
  COUNT(*) as total_users,
  COUNT(CASE WHEN email = 'wajehah.sa@gmail.com' THEN 1 END) as target_user_exists
FROM auth.users;

-- 3. Test if we can read from employees
SELECT 
  '=== EMPLOYEES TEST ===' as test,
  COUNT(*) as total_employees,
  COUNT(CASE WHEN email = 'wajehah.sa@gmail.com' THEN 1 END) as target_employee_exists
FROM employees;

-- 4. Test if we can read from companies
SELECT 
  '=== COMPANIES TEST ===' as test,
  COUNT(*) as total_companies,
  COUNT(CASE WHEN company_name_en = 'Derayah Financial' THEN 1 END) as target_company_exists
FROM companies;

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
  SELECT id FROM auth.users WHERE email = 'wajehah.sa@gmail.com'
);

-- 6. Check if there are any RLS issues
SELECT 
  '=== RLS POLICIES CHECK ===' as test,
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies 
WHERE tablename IN ('employees', 'grants', 'companies')
ORDER BY tablename, policyname;

-- 7. Check if there are any missing indexes
SELECT 
  '=== INDEX CHECK ===' as test,
  indexname,
  indexdef
FROM pg_indexes 
WHERE tablename = 'employees' 
  AND schemaname = 'public';

-- 8. Create missing indexes if needed
CREATE INDEX IF NOT EXISTS idx_employees_user_id ON employees(user_id);
CREATE INDEX IF NOT EXISTS idx_employees_email ON employees(email);
CREATE INDEX IF NOT EXISTS idx_employees_company_id ON employees(company_id);

-- 9. Final test - try to run the exact query again
SELECT 
  '=== FINAL QUERY TEST ===' as test,
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
