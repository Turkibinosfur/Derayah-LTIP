-- Complete Employee Setup for employee@example.com
-- This script ensures everything is properly configured for employee login

-- 1. Ensure company exists
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

-- 2. Check if auth user exists and create if needed
DO $$
DECLARE
  v_auth_user_id uuid;
  v_company_id uuid;
  v_employee_id uuid;
BEGIN
  -- Get company ID
  SELECT id INTO v_company_id 
  FROM companies 
  WHERE company_name_en = 'Derayah Financial';
  
  -- Check if auth user exists
  SELECT id INTO v_auth_user_id 
  FROM auth.users 
  WHERE email = 'employee@example.com';
  
  IF v_auth_user_id IS NULL THEN
    RAISE NOTICE 'Auth user does not exist for employee@example.com';
    RAISE NOTICE 'Please create the auth user manually in Supabase Dashboard:';
    RAISE NOTICE 'Email: employee@example.com';
    RAISE NOTICE 'Password: Employee123!';
    RAISE NOTICE 'Then run this script again.';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Auth user exists with ID: %', v_auth_user_id;
  
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
  
  -- Create a sample grant for testing
  IF NOT EXISTS (SELECT 1 FROM grants WHERE employee_id = v_employee_id) THEN
    INSERT INTO grants (
      id,
      employee_id,
      plan_id,
      grant_number,
      total_shares,
      vested_shares,
      remaining_unvested_shares,
      grant_date,
      vesting_start_date,
      vesting_end_date,
      status,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_employee_id,
      (SELECT id FROM incentive_plans WHERE plan_name_en = 'Derayah Employee Stock Plan 2025' LIMIT 1),
      'GR-20250125-001',
      50000,
      0,
      50000,
      now(),
      now(),
      now() + interval '4 years',
      'pending_signature',
      now(),
      now()
    );
    
    RAISE NOTICE 'Sample grant created for testing';
  END IF;
  
  RAISE NOTICE '=== SETUP COMPLETE ===';
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
  u.email_confirmed_at,
  c.company_name_en
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
LEFT JOIN companies c ON e.company_id = c.id
WHERE e.email = 'employee@example.com';
