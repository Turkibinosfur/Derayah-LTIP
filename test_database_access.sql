-- Test Database Access for wajehah.sa@gmail.com
-- This script tests if the database queries work properly

-- 1. Test basic connection
SELECT 
  '=== BASIC CONNECTION TEST ===' as test,
  now() as current_time,
  current_user as current_user,
  current_database() as current_database;

-- 2. Test auth.users table access
SELECT 
  '=== AUTH USERS ACCESS TEST ===' as test,
  COUNT(*) as total_users,
  COUNT(CASE WHEN email = 'wajehah.sa@gmail.com' THEN 1 END) as target_user_exists
FROM auth.users;

-- 3. Test employees table access
SELECT 
  '=== EMPLOYEES TABLE ACCESS TEST ===' as test,
  COUNT(*) as total_employees,
  COUNT(CASE WHEN email = 'wajehah.sa@gmail.com' THEN 1 END) as target_employee_exists
FROM employees;

-- 4. Test companies table access
SELECT 
  '=== COMPANIES TABLE ACCESS TEST ===' as test,
  COUNT(*) as total_companies,
  COUNT(CASE WHEN company_name_en = 'Derayah Financial' THEN 1 END) as target_company_exists
FROM companies;

-- 5. Test the exact query used by EmployeeLogin.tsx
SELECT 
  '=== EMPLOYEE LOGIN QUERY TEST ===' as test,
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM employees e 
      WHERE e.user_id = (
        SELECT id FROM auth.users WHERE email = 'wajehah.sa@gmail.com'
      )
    ) 
    THEN 'Query should work' 
    ELSE 'Query will fail - no employee record found' 
  END as query_result;

-- 6. Test if we can create a simple test record
DO $$
DECLARE
  v_test_id uuid;
  v_company_id uuid;
  v_auth_user_id uuid;
BEGIN
  -- Get company ID
  SELECT id INTO v_company_id 
  FROM companies 
  WHERE company_name_en = 'Derayah Financial'
  LIMIT 1;
  
  -- Get auth user ID
  SELECT id INTO v_auth_user_id 
  FROM auth.users 
  WHERE email = 'wajehah.sa@gmail.com'
  LIMIT 1;
  
  IF v_company_id IS NULL OR v_auth_user_id IS NULL THEN
    RAISE NOTICE 'Cannot create test record - missing company or auth user';
    RETURN;
  END IF;
  
  -- Try to create a test record in employees table
  INSERT INTO employees (
    id,
    company_id,
    first_name_en,
    last_name_en,
    email,
    user_id,
    portal_access_enabled,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_company_id,
    'Test',
    'User',
    'test@example.com',
    v_auth_user_id,
    false,
    now(),
    now()
  ) RETURNING id INTO v_test_id;
  
  -- Delete the test record
  DELETE FROM employees WHERE id = v_test_id;
  
  RAISE NOTICE 'Database write test successful';
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Database write test failed: %', SQLERRM;
END;
$$;

-- 7. Check if there are any schema issues
SELECT 
  '=== SCHEMA ISSUES CHECK ===' as test,
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'employees' 
  AND table_schema = 'public'
  AND column_name IN ('id', 'company_id', 'first_name_en', 'last_name_en', 'email', 'user_id')
ORDER BY ordinal_position;

-- 8. Check if there are any missing constraints
SELECT 
  '=== CONSTRAINTS CHECK ===' as test,
  constraint_name,
  constraint_type,
  table_name
FROM information_schema.table_constraints 
WHERE table_name = 'employees' 
  AND table_schema = 'public';

-- 9. Final test - try to run the exact query
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
