-- Fix Employee Auth Linking
-- This script ensures employee records are properly linked to auth users

-- 1. Check current state for test3@test.com
SELECT 
  '=== TEST3@TEST.COM STATUS ===' as step,
  e.id as employee_id,
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
WHERE e.email = 'test3@test.com';

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

-- 3. Check all employees with portal access
SELECT 
  '=== ALL EMPLOYEES WITH PORTAL ACCESS ===' as step,
  e.id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id,
  e.portal_access_enabled,
  CASE 
    WHEN u.id IS NOT NULL THEN 'Linked' 
    ELSE 'Not linked' 
  END as link_status,
  u.email as auth_email
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
WHERE e.portal_access_enabled = true
ORDER BY e.created_at DESC;

-- 4. Create auth user for test3@test.com if it doesn't exist
DO $$
DECLARE
  v_auth_user_id uuid;
  v_employee_id uuid;
  v_company_id uuid;
BEGIN
  -- Check if auth user exists
  SELECT id INTO v_auth_user_id 
  FROM auth.users 
  WHERE email = 'test3@test.com';
  
  IF v_auth_user_id IS NULL THEN
    RAISE NOTICE '=== AUTH USER MISSING ===';
    RAISE NOTICE 'Auth user does not exist for test3@test.com';
    RAISE NOTICE 'Please create the auth user manually:';
    RAISE NOTICE '';
    RAISE NOTICE '1. Go to Supabase Dashboard > Authentication > Users';
    RAISE NOTICE '2. Click "Add user"';
    RAISE NOTICE '3. Email: test3@test.com';
    RAISE NOTICE '4. Password: Employee123!';
    RAISE NOTICE '5. Email Confirm: true';
    RAISE NOTICE '6. Click "Create user"';
    RAISE NOTICE '7. Then run this script again';
    RAISE NOTICE '';
    RAISE NOTICE 'ALTERNATIVE: Use Supabase CLI:';
    RAISE NOTICE 'supabase auth users create test3@test.com --password Employee123!';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Auth user exists for test3@test.com with ID: %', v_auth_user_id;
  
  -- Get employee ID
  SELECT id INTO v_employee_id 
  FROM employees 
  WHERE email = 'test3@test.com';
  
  IF v_employee_id IS NULL THEN
    RAISE NOTICE 'Employee record not found for test3@test.com';
    RETURN;
  END IF;
  
  -- Get company ID
  SELECT id INTO v_company_id 
  FROM companies 
  WHERE company_name_en = 'Derayah Financial';
  
  -- Link employee to auth user
  UPDATE employees SET
    user_id = v_auth_user_id,
    portal_access_enabled = true,
    updated_at = now()
  WHERE id = v_employee_id;
  
  RAISE NOTICE 'Employee linked to auth user successfully';
  RAISE NOTICE 'Employee ID: %', v_employee_id;
  RAISE NOTICE 'Auth User ID: %', v_auth_user_id;
  RAISE NOTICE 'Company ID: %', v_company_id;
  
END;
$$;

-- 5. Test the exact query used by EmployeeLogin.tsx
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
  SELECT id FROM auth.users WHERE email = 'test3@test.com'
);

-- 6. Final verification
SELECT 
  '=== FINAL VERIFICATION ===' as step,
  e.id,
  e.company_id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id,
  e.portal_access_enabled,
  u.email as auth_email,
  u.email_confirmed_at,
  c.company_name_en
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
LEFT JOIN companies c ON e.company_id = c.id
WHERE e.email = 'test3@test.com';

-- 7. Test if login should work
SELECT 
  '=== LOGIN TEST RESULT ===' as step,
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM employees e 
      WHERE e.user_id = (
        SELECT id FROM auth.users WHERE email = 'test3@test.com'
      )
    ) 
    THEN 'SUCCESS: Login should work - employee record linked to auth user' 
    ELSE 'FAILED: Login will fail - employee record not linked to auth user' 
  END as login_status;
