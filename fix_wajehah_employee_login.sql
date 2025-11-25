-- Fix employee@example.com Employee Login
-- This script ensures the employee record exists and is properly configured

-- 1. Check current state
SELECT 
  '=== CURRENT STATE ===' as step,
  'employee@example.com' as email,
  CASE 
    WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = 'employee@example.com') 
    THEN 'Auth user exists' 
    ELSE 'Auth user missing' 
  END as auth_status,
  CASE 
    WHEN EXISTS (SELECT 1 FROM employees WHERE email = 'employee@example.com') 
    THEN 'Employee record exists' 
    ELSE 'Employee record missing' 
  END as employee_status;

-- 2. Get company ID
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
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Company not found';
  END IF;
  
  RAISE NOTICE 'Company ID: %', v_company_id;
  
  -- Check if auth user exists
  SELECT id INTO v_auth_user_id 
  FROM auth.users 
  WHERE email = 'employee@example.com';
  
  IF v_auth_user_id IS NULL THEN
    RAISE NOTICE 'Auth user does not exist for employee@example.com';
    RAISE NOTICE 'Please create the auth user manually in Supabase Dashboard';
    RAISE NOTICE 'Email: employee@example.com';
    RAISE NOTICE 'Password: Employee123!';
  ELSE
    RAISE NOTICE 'Auth user exists with ID: %', v_auth_user_id;
  END IF;
  
  -- Check if employee record exists
  SELECT id INTO v_employee_id 
  FROM employees 
  WHERE email = 'employee@example.com';
  
  IF v_employee_id IS NULL THEN
    RAISE NOTICE 'Employee record does not exist, creating...';
    
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
    RAISE NOTICE 'Employee record exists with ID: %', v_employee_id;
    
    -- Update employee record to ensure it's properly configured
    UPDATE employees SET
      user_id = v_auth_user_id,
      portal_access_enabled = true,
      portal_username = 'wajehah.sa',
      portal_password = 'Employee123!',
      updated_at = now()
    WHERE id = v_employee_id;
    
    RAISE NOTICE 'Employee record updated';
  END IF;
  
  -- Final verification
  RAISE NOTICE '=== FINAL VERIFICATION ===';
  RAISE NOTICE 'Employee ID: %', v_employee_id;
  RAISE NOTICE 'Auth User ID: %', v_auth_user_id;
  RAISE NOTICE 'Company ID: %', v_company_id;
  
END;
$$;

-- 3. Final verification
SELECT 
  '=== FINAL VERIFICATION ===' as step,
  e.id as employee_id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id,
  e.portal_access_enabled,
  e.portal_username,
  u.email as auth_email,
  u.email_confirmed_at
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
WHERE e.email = 'employee@example.com';
