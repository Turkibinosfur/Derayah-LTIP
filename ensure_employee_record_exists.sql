-- Ensure Employee Record Exists for wajehah.sa@gmail.com
-- This script ensures the employee record exists and is properly configured

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

-- 3. Ensure company exists
DO $$
DECLARE
  v_company_id uuid;
BEGIN
  SELECT id INTO v_company_id 
  FROM companies 
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
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
    ) VALUES (
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
    ) RETURNING id INTO v_company_id;
    
    RAISE NOTICE 'Company created with ID: %', v_company_id;
  ELSE
    RAISE NOTICE 'Company exists with ID: %', v_company_id;
  END IF;
END;
$$;

-- 4. Ensure employee record exists
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
  WHERE email = 'wajehah.sa@gmail.com';
  
  IF v_auth_user_id IS NULL THEN
    RAISE NOTICE 'Auth user does not exist for wajehah.sa@gmail.com';
    RAISE NOTICE 'Please create the auth user manually in Supabase Dashboard:';
    RAISE NOTICE 'Email: wajehah.sa@gmail.com';
    RAISE NOTICE 'Password: Employee123!';
    RAISE NOTICE 'Then run this script again.';
    RETURN;
  END IF;
  
  -- Check if employee record exists
  SELECT id INTO v_employee_id 
  FROM employees 
  WHERE email = 'wajehah.sa@gmail.com';
  
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
      'wajehah.sa@gmail.com',
      v_auth_user_id,
      true,
      'wajehah.sa',
      'Employee123!',
      now(),
      now()
    ) RETURNING id INTO v_employee_id;
    
    RAISE NOTICE 'Employee record created with ID: %', v_employee_id;
  ELSE
    -- Update employee record to ensure it's properly configured
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

-- 5. Final verification
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
WHERE e.email = 'wajehah.sa@gmail.com';

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
  SELECT id FROM auth.users WHERE email = 'wajehah.sa@gmail.com'
);
