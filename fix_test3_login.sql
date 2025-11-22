-- Fix test3@test.com Login Issue
-- This script addresses the "Invalid login credentials" error

-- 1. Check current state
SELECT 
  '=== CURRENT STATE CHECK ===' as step,
  'test3@test.com' as email,
  CASE 
    WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = 'test3@test.com') 
    THEN 'Auth user exists' 
    ELSE 'Auth user missing' 
  END as auth_status,
  CASE 
    WHEN EXISTS (SELECT 1 FROM employees WHERE email = 'test3@test.com') 
    THEN 'Employee record exists' 
    ELSE 'Employee record missing' 
  END as employee_status;

-- 2. Check employee record details
SELECT 
  '=== EMPLOYEE RECORD CHECK ===' as step,
  id,
  first_name_en,
  last_name_en,
  email,
  user_id,
  portal_access_enabled,
  portal_username,
  portal_password,
  company_id
FROM employees 
WHERE email = 'test3@test.com';

-- 3. Check if auth user exists
SELECT 
  '=== AUTH USER CHECK ===' as step,
  id,
  email,
  email_confirmed_at,
  created_at,
  last_sign_in_at
FROM auth.users 
WHERE email = 'test3@test.com';

-- 4. If auth user doesn't exist, show instructions
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'test3@test.com') THEN
    RAISE NOTICE '=== AUTH USER MISSING ===';
    RAISE NOTICE 'The employee record exists but the auth user is missing.';
    RAISE NOTICE 'Please create the auth user manually:';
    RAISE NOTICE '';
    RAISE NOTICE '1. Go to Supabase Dashboard';
    RAISE NOTICE '2. Navigate to Authentication > Users';
    RAISE NOTICE '3. Click "Add user" button';
    RAISE NOTICE '4. Fill in the details:';
    RAISE NOTICE '   - Email: test3@test.com';
    RAISE NOTICE '   - Password: Employee123! (or use the portal password from employee record)';
    RAISE NOTICE '   - Email Confirm: true';
    RAISE NOTICE '5. Click "Create user"';
    RAISE NOTICE '6. Then run this script again to link the user';
    RAISE NOTICE '';
    RAISE NOTICE 'ALTERNATIVE: You can also use the Supabase CLI:';
    RAISE NOTICE 'supabase auth users create test3@test.com --password Employee123!';
  ELSE
    RAISE NOTICE 'Auth user exists for test3@test.com';
    RAISE NOTICE 'You can proceed with linking the user to the employee record';
  END IF;
END;
$$;

-- 5. Link auth user to employee record (if auth user exists)
DO $$
DECLARE
  v_employee_id uuid;
  v_auth_user_id uuid;
  v_company_id uuid;
BEGIN
  -- Get employee ID
  SELECT id INTO v_employee_id 
  FROM employees 
  WHERE email = 'test3@test.com';
  
  -- Get auth user ID
  SELECT id INTO v_auth_user_id 
  FROM auth.users 
  WHERE email = 'test3@test.com';
  
  -- Get company ID
  SELECT id INTO v_company_id 
  FROM companies 
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_employee_id IS NULL THEN
    RAISE NOTICE 'Employee record not found for test3@test.com';
    RETURN;
  END IF;
  
  IF v_auth_user_id IS NULL THEN
    RAISE NOTICE 'Auth user not found for test3@test.com';
    RAISE NOTICE 'Please create the auth user first, then run this script again.';
    RETURN;
  END IF;
  
  -- Update employee record to link with auth user
  UPDATE employees SET
    user_id = v_auth_user_id,
    portal_access_enabled = true,
    updated_at = now()
  WHERE id = v_employee_id;
  
  RAISE NOTICE 'Employee record linked to auth user successfully';
  RAISE NOTICE 'Employee ID: %', v_employee_id;
  RAISE NOTICE 'Auth User ID: %', v_auth_user_id;
  RAISE NOTICE 'Company ID: %', v_company_id;
  
END;
$$;

-- 6. Test the exact query used by EmployeeLogin.tsx
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

-- 7. Final verification
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

-- 8. Test if login should work
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
