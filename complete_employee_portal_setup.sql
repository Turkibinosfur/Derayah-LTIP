-- Complete Employee Portal Setup for employee@example.com
-- This script ensures everything is properly configured for the employee portal

-- 1. Check current state
SELECT 
  '=== CURRENT STATE CHECK ===' as step,
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
  END as employee_status,
  CASE 
    WHEN EXISTS (SELECT 1 FROM grants g JOIN employees e ON g.employee_id = e.id WHERE e.email = 'employee@example.com' AND g.status = 'pending_signature') 
    THEN 'Pending grant exists' 
    ELSE 'No pending grant' 
  END as grant_status;

-- 2. Complete setup
DO $$
DECLARE
  v_company_id uuid;
  v_plan_id uuid;
  v_employee_id uuid;
  v_auth_user_id uuid;
  v_grant_id uuid;
BEGIN
  -- Get company ID
  SELECT id INTO v_company_id 
  FROM companies 
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    -- Create company
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
  
  -- Get or create employee record
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
  
  -- Get or create incentive plan
  SELECT id INTO v_plan_id 
  FROM incentive_plans 
  WHERE plan_name_en = 'Derayah Employee Stock Plan 2025' 
    AND company_id = v_company_id;
  
  IF v_plan_id IS NULL THEN
    INSERT INTO incentive_plans (
      id,
      company_id,
      plan_name_en,
      plan_name_ar,
      plan_code,
      plan_type,
      start_date,
      end_date,
      total_shares_allocated,
      vesting_schedule_type,
      description_en,
      description_ar,
      status,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_company_id,
      'Derayah Employee Stock Plan 2025',
      'خطة أسهم الموظفين 2025',
      'DESP-2025',
      'employee_stock_option',
      '2025-01-01',
      '2029-12-31',
      1000000,
      'cliff_and_monthly',
      'Employee Stock Option Plan for 2025',
      'خطة خيارات الأسهم للموظفين 2025',
      'active',
      now(),
      now()
    ) RETURNING id INTO v_plan_id;
    
    RAISE NOTICE 'Incentive plan created with ID: %', v_plan_id;
  ELSE
    RAISE NOTICE 'Incentive plan exists with ID: %', v_plan_id;
  END IF;
  
  -- Check if pending grant exists
  SELECT id INTO v_grant_id 
  FROM grants 
  WHERE employee_id = v_employee_id 
    AND status = 'pending_signature';
  
  IF v_grant_id IS NULL THEN
    -- Create pending grant
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
      v_plan_id,
      'GR-20250125-003',
      50000,
      0,
      50000,
      now(),
      now(),
      now() + interval '4 years',
      'pending_signature',
      now(),
      now()
    ) RETURNING id INTO v_grant_id;
    
    RAISE NOTICE 'Pending grant created with ID: %', v_grant_id;
  ELSE
    RAISE NOTICE 'Pending grant already exists with ID: %', v_grant_id;
  END IF;
  
  RAISE NOTICE '=== SETUP COMPLETE ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  RAISE NOTICE 'Employee ID: %', v_employee_id;
  RAISE NOTICE 'Auth User ID: %', v_auth_user_id;
  RAISE NOTICE 'Plan ID: %', v_plan_id;
  RAISE NOTICE 'Grant ID: %', v_grant_id;
  
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
  u.email as auth_email,
  u.email_confirmed_at,
  c.company_name_en
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
LEFT JOIN companies c ON e.company_id = c.id
WHERE e.email = 'employee@example.com';

-- 4. Check grants that should appear in dashboard
SELECT 
  '=== GRANTS FOR DASHBOARD ===' as step,
  g.id,
  g.grant_number,
  g.total_shares,
  g.vested_shares,
  g.remaining_unvested_shares,
  g.status,
  g.grant_date,
  ip.plan_name_en
FROM grants g
JOIN employees e ON g.employee_id = e.id
LEFT JOIN incentive_plans ip ON g.plan_id = ip.id
WHERE e.email = 'employee@example.com'
  AND g.status IN ('active', 'pending_signature')
ORDER BY g.created_at DESC;

-- 5. Test the exact query used by EmployeeDashboard.tsx
SELECT 
  '=== DASHBOARD QUERY TEST ===' as step,
  g.id,
  g.total_shares,
  g.vested_shares,
  g.remaining_unvested_shares,
  g.status,
  g.grant_number
FROM grants g
JOIN employees e ON g.employee_id = e.id
WHERE e.user_id = (
  SELECT id FROM auth.users WHERE email = 'employee@example.com'
)
AND g.status IN ('active', 'pending_signature');
