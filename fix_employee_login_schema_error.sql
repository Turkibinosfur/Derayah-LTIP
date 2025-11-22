-- Fix Employee Login Schema Error
-- This script addresses the "Database error querying schema" error

-- 1. Check current state
SELECT 
  '=== CURRENT STATE CHECK ===' as step,
  'wajehah.sa@gmail.com' as email,
  CASE 
    WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = 'wajehah.sa@gmail.com') 
    THEN 'Auth user exists' 
    ELSE 'Auth user missing' 
  END as auth_status,
  CASE 
    WHEN EXISTS (SELECT 1 FROM employees WHERE email = 'wajehah.sa@gmail.com') 
    THEN 'Employee record exists' 
    ELSE 'Employee record missing' 
  END as employee_status;

-- 2. Check RLS policies
SELECT 
  '=== RLS POLICIES CHECK ===' as step,
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies 
WHERE tablename IN ('employees', 'grants', 'companies')
ORDER BY tablename, policyname;

-- 3. Check if there are any schema issues
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

-- 5. Check if there are any permission issues
SELECT 
  '=== PERMISSION CHECK ===' as step,
  u.id,
  u.email,
  u.email_confirmed_at,
  u.created_at,
  u.last_sign_in_at
FROM auth.users u
WHERE u.email = 'wajehah.sa@gmail.com';

-- 6. Create a simple test function to check if the query works
CREATE OR REPLACE FUNCTION test_employee_login_query(p_email text)
RETURNS TABLE(
  employee_id uuid,
  company_id uuid,
  first_name_en text,
  last_name_en text,
  employee_email text,
  user_id uuid
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.company_id,
    e.first_name_en,
    e.last_name_en,
    e.email,
    e.user_id
  FROM employees e
  WHERE e.user_id = (
    SELECT id FROM auth.users WHERE email = p_email
  );
END;
$$;

-- 7. Test the function
SELECT 
  '=== FUNCTION TEST ===' as step,
  *
FROM test_employee_login_query('wajehah.sa@gmail.com');

-- 8. Check if there are any missing indexes
SELECT 
  '=== INDEX CHECK ===' as step,
  indexname,
  indexdef
FROM pg_indexes 
WHERE tablename = 'employees' 
  AND schemaname = 'public';

-- 9. Create missing indexes if needed
CREATE INDEX IF NOT EXISTS idx_employees_user_id ON employees(user_id);
CREATE INDEX IF NOT EXISTS idx_employees_email ON employees(email);
CREATE INDEX IF NOT EXISTS idx_employees_company_id ON employees(company_id);

-- 10. Final verification
SELECT 
  '=== FINAL VERIFICATION ===' as step,
  e.id,
  e.company_id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id,
  u.email as auth_email,
  u.email_confirmed_at
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
WHERE e.email = 'wajehah.sa@gmail.com';
