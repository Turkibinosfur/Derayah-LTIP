-- Simple Employee Login Test
-- This script tests the employee login functionality without complex functions

-- 1. Check if auth user exists
SELECT 
  '=== AUTH USER CHECK ===' as test,
  id,
  email,
  email_confirmed_at,
  created_at
FROM auth.users 
WHERE email = 'employee@example.com';

-- 2. Check if employee record exists
SELECT 
  '=== EMPLOYEE RECORD CHECK ===' as test,
  id,
  first_name_en,
  last_name_en,
  email,
  user_id,
  portal_access_enabled,
  company_id
FROM employees 
WHERE email = 'employee@example.com';

-- 3. Test the exact query used by EmployeeLogin.tsx
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
  SELECT id FROM auth.users WHERE email = 'employee@example.com'
);

-- 4. Check if there are any RLS issues
SELECT 
  '=== RLS POLICIES CHECK ===' as test,
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies 
WHERE tablename IN ('employees', 'grants', 'companies')
ORDER BY tablename, policyname;

-- 5. Check if there are any missing indexes
SELECT 
  '=== INDEX CHECK ===' as test,
  indexname,
  indexdef
FROM pg_indexes 
WHERE tablename = 'employees' 
  AND schemaname = 'public';

-- 6. Create missing indexes if needed
CREATE INDEX IF NOT EXISTS idx_employees_user_id ON employees(user_id);
CREATE INDEX IF NOT EXISTS idx_employees_email ON employees(email);
CREATE INDEX IF NOT EXISTS idx_employees_company_id ON employees(company_id);

-- 7. Test if we can create a simple test record
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
  WHERE email = 'employee@example.com'
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

-- 8. Final verification
SELECT 
  '=== FINAL VERIFICATION ===' as test,
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
WHERE e.email = 'employee@example.com';
