-- Quick Fix for employee@example.com Login
-- This script provides a step-by-step solution to fix the login issue

-- Step 1: Check current state
SELECT 
  '=== STEP 1: CURRENT STATE ===' as step,
  CASE 
    WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = 'employee@example.com') 
    THEN 'Auth user exists' 
    ELSE 'Auth user missing' 
  END as auth_status,
  CASE 
    WHEN EXISTS (SELECT 1 FROM employees WHERE email = 'employee@example.com') 
    THEN 'Employee record exists' 
    ELSE 'Employee record missing' 
  END as employee_status,
  CASE 
    WHEN EXISTS (SELECT 1 FROM companies WHERE company_name_en = 'Derayah Financial') 
    THEN 'Company exists' 
    ELSE 'Company missing' 
  END as company_status;

-- Step 2: Create company if missing
INSERT INTO companies (
  id,
  company_name_en,
  company_name_ar,
  tadawul_symbol,
  commercial_registration_number,
  verification_status,
  total_reserved_shares,
  available_shares,
  status,
  created_at,
  updated_at
) 
SELECT 
  gen_random_uuid(),
  'Derayah Financial',
  'دارة المالية',
  'DERAYAH',
  '1010123456',
  'verified',
  10000000,
  10000000,
  'active',
  now(),
  now()
WHERE NOT EXISTS (SELECT 1 FROM companies WHERE company_name_en = 'Derayah Financial');

-- Step 3: Check if auth user exists
SELECT 
  '=== STEP 3: AUTH USER CHECK ===' as step,
  id,
  email,
  email_confirmed_at,
  created_at
FROM auth.users 
WHERE email = 'employee@example.com';

-- Step 4: If auth user doesn't exist, show instructions
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'employee@example.com') THEN
    RAISE NOTICE '=== AUTH USER MISSING ===';
    RAISE NOTICE 'Please create the auth user manually:';
    RAISE NOTICE '1. Go to Supabase Dashboard > Authentication > Users';
    RAISE NOTICE '2. Click "Add user"';
    RAISE NOTICE '3. Email: employee@example.com';
    RAISE NOTICE '4. Password: Employee123!';
    RAISE NOTICE '5. Confirm the email';
    RAISE NOTICE '6. Then run this script again.';
  ELSE
    RAISE NOTICE 'Auth user exists for employee@example.com';
  END IF;
END;
$$;

-- Step 5: Create employee record if auth user exists
DO $$
DECLARE
  v_company_id uuid;
  v_employee_id uuid;
  v_auth_user_id uuid;
BEGIN
  -- Get company ID
  SELECT id INTO v_company_id 
  FROM companies 
  WHERE company_name_en = 'Derayah Financial';
  
  -- Get auth user ID
  SELECT id INTO v_auth_user_id 
  FROM auth.users 
  WHERE email = 'employee@example.com';
  
  IF v_auth_user_id IS NULL THEN
    RAISE NOTICE 'Cannot create employee record - auth user not found';
    RAISE NOTICE 'Please create the auth user first, then run this script again.';
    RETURN;
  END IF;
  
  -- Check if employee record exists
  SELECT id INTO v_employee_id 
  FROM employees 
  WHERE email = 'employee@example.com';
  
  IF v_employee_id IS NULL THEN
    -- Create employee record
    INSERT INTO employees (
      id,
      company_id,
      first_name_en,
      last_name_en,
      email,
      user_id,
      portal_access_enabled,
      portal_username,
      portal_password,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_company_id,
      'Fatima',
      'Al-Zahrani',
      'employee@example.com',
      v_auth_user_id,
      true,
      'wajehah.sa',
      'Employee123!',
      now(),
      now()
    ) RETURNING id INTO v_employee_id;
    
    RAISE NOTICE 'Employee record created with ID: %', v_employee_id;
  ELSE
    -- Update employee record
    UPDATE employees SET
      user_id = v_auth_user_id,
      portal_access_enabled = true,
      portal_username = 'wajehah.sa',
      portal_password = 'Employee123!',
      updated_at = now()
    WHERE id = v_employee_id;
    
    RAISE NOTICE 'Employee record updated with ID: %', v_employee_id;
  END IF;
  
  RAISE NOTICE '=== SETUP COMPLETE ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  RAISE NOTICE 'Employee ID: %', v_employee_id;
  RAISE NOTICE 'Auth User ID: %', v_auth_user_id;
  
END;
$$;

-- Step 6: Test the exact query used by EmployeeLogin.tsx
SELECT 
  '=== STEP 6: LOGIN QUERY TEST ===' as step,
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

-- Step 7: Final verification
SELECT 
  '=== STEP 7: FINAL VERIFICATION ===' as step,
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
WHERE e.email = 'employee@example.com';

-- Step 8: Test if login should work
SELECT 
  '=== STEP 8: LOGIN TEST RESULT ===' as step,
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM employees e 
      WHERE e.user_id = (
        SELECT id FROM auth.users WHERE email = 'employee@example.com'
      )
    ) 
    THEN 'SUCCESS: Login should work - employee record found' 
    ELSE 'FAILED: Login will fail - no employee record found' 
  END as login_status;
