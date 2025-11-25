-- Setup Pending Grant for employee@example.com
-- This script ensures the employee has a pending grant that should appear in the dashboard

-- 1. Check current state
SELECT 
  '=== CURRENT STATE CHECK ===' as step,
  e.id as employee_id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id,
  e.portal_access_enabled,
  u.email as auth_email,
  c.company_name_en
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
LEFT JOIN companies c ON e.company_id = c.id
WHERE e.email = 'employee@example.com';

-- 2. Check existing grants
SELECT 
  '=== EXISTING GRANTS ===' as step,
  g.id,
  g.grant_number,
  g.total_shares,
  g.status,
  g.employee_acceptance_at,
  ip.plan_name_en
FROM grants g
JOIN employees e ON g.employee_id = e.id
LEFT JOIN incentive_plans ip ON g.plan_id = ip.id
WHERE e.email = 'employee@example.com';

-- 3. Ensure company and incentive plan exist
DO $$
DECLARE
  v_company_id uuid;
  v_plan_id uuid;
  v_employee_id uuid;
  v_grant_id uuid;
BEGIN
  -- Get company ID
  SELECT id INTO v_company_id 
  FROM companies 
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Company not found';
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
  
  -- Get employee ID
  SELECT id INTO v_employee_id 
  FROM employees 
  WHERE email = 'employee@example.com';
  
  IF v_employee_id IS NULL THEN
    RAISE EXCEPTION 'Employee not found. Please run the employee setup script first.';
  END IF;
  
  -- Check if grant already exists
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
  RAISE NOTICE 'Employee ID: %', v_employee_id;
  RAISE NOTICE 'Plan ID: %', v_plan_id;
  RAISE NOTICE 'Grant ID: %', v_grant_id;
  
END;
$$;

-- 4. Final verification
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

-- 5. Check grants that should appear in dashboard
SELECT 
  '=== GRANTS FOR DASHBOARD ===' as step,
  g.id,
  g.grant_number,
  g.total_shares,
  g.vested_shares,
  g.remaining_unvested_shares,
  g.status,
  g.grant_date,
  g.vesting_start_date,
  g.vesting_end_date,
  ip.plan_name_en
FROM grants g
JOIN employees e ON g.employee_id = e.id
LEFT JOIN incentive_plans ip ON g.plan_id = ip.id
WHERE e.email = 'employee@example.com'
  AND g.status IN ('active', 'pending_signature')
ORDER BY g.created_at DESC;
