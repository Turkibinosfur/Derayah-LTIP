/*
  # Add 3 Employees with 10M Shares for 4-Year Incentive Plan
  
  ## Overview
  This migration adds 3 new employees to Derayah Financial with a total of 10 million shares
  allocated across a 4-year incentive plan with standard vesting schedules.
  
  ## Employees Added
  1. Sarah Al-Mansouri - Senior Software Engineer (3M shares)
  2. Khalid Al-Zahrani - Product Manager (3.5M shares) 
  3. Fatima Al-Rashid - Data Scientist (3.5M shares)
  
  ## Plan Details
  - Plan Type: LTIP_RSU (Restricted Stock Units)
  - Total Shares: 10,000,000
  - Vesting Period: 4 years
  - Cliff Period: 1 year
  - Vesting Frequency: Monthly
  
  ## Security
  - All data is company-specific and isolated by RLS policies
*/

DO $$
DECLARE
  v_company_id uuid;
  v_plan_id uuid;
  v_sarah_id uuid;
  v_khalid_id uuid;
  v_fatima_id uuid;
  v_sarah_portfolio_id uuid;
  v_khalid_portfolio_id uuid;
  v_fatima_portfolio_id uuid;
  v_sarah_grant_id uuid;
  v_khalid_grant_id uuid;
  v_fatima_grant_id uuid;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Financial company not found';
  END IF;
  
  -- Check if employees already exist to prevent duplicate data
  IF EXISTS (
    SELECT 1 FROM employees 
    WHERE company_id = v_company_id 
    AND employee_number IN ('EMP-2025-001', 'EMP-2025-002', 'EMP-2025-003')
  ) THEN
    RAISE NOTICE 'Employees already exist, skipping migration';
    RETURN;
  END IF;
  
  -- Create 4-Year Incentive Plan
  INSERT INTO incentive_plans (
    id,
    company_id,
    plan_name_en,
    plan_name_ar,
    plan_type,
    plan_code,
    description_en,
    description_ar,
    vesting_schedule_type,
    vesting_config,
    total_shares_allocated,
    shares_granted,
    shares_available,
    start_date,
    end_date,
    status,
    approval_status,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_company_id,
    'Derayah Employee Stock Plan 2025',
    'خطة أسهم الموظفين دراية 2025',
    'LTIP_RSU',
    'DESP-2025-001',
    '4-year employee stock incentive plan with 1-year cliff and monthly vesting',
    'خطة حوافز أسهم الموظفين لمدة 4 سنوات مع فترة انتظار سنة واحدة واستحقاق شهري',
    'time_based',
    '{"duration_months": 48, "cliff_months": 12, "vesting_frequency": "monthly", "performance_metrics": null}'::jsonb,
    10000000,
    0,
    10000000,
    '2025-01-01',
    '2028-12-31',
    'active',
    'approved',
    now(),
    now()
  ) RETURNING id INTO v_plan_id;
  
  -- Note: We'll create individual vesting schedule entries for each grant
  -- No template needed for the original vesting_schedules table structure
  
  -- Create Employee 1: Sarah Al-Mansouri (only if not exists)
  INSERT INTO employees (
    id,
    company_id,
    employee_number,
    national_id,
    email,
    phone,
    first_name_en,
    last_name_en,
    first_name_ar,
    last_name_ar,
    department,
    job_title,
    hire_date,
    employment_status,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_company_id,
    'EMP-2025-001',
    '1234567890',
    'sarah.mansouri@derayah.com',
    '+966501234567',
    'Sarah',
    'Al-Mansouri',
    'سارة',
    'المنصوري',
    'Engineering',
    'Senior Software Engineer',
    '2023-06-15',
    'active',
    now(),
    now()
  ) RETURNING id INTO v_sarah_id;
  
  -- Create Employee 2: Khalid Al-Zahrani
  INSERT INTO employees (
    id,
    company_id,
    employee_number,
    national_id,
    email,
    phone,
    first_name_en,
    last_name_en,
    first_name_ar,
    last_name_ar,
    department,
    job_title,
    hire_date,
    employment_status,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_company_id,
    'EMP-2025-002',
    '1234567891',
    'khalid.zahrani@derayah.com',
    '+966501234568',
    'Khalid',
    'Al-Zahrani',
    'خالد',
    'الزهراني',
    'Product',
    'Product Manager',
    '2023-08-20',
    'active',
    now(),
    now()
  ) RETURNING id INTO v_khalid_id;
  
  -- Create Employee 3: Fatima Al-Rashid
  INSERT INTO employees (
    id,
    company_id,
    employee_number,
    national_id,
    email,
    phone,
    first_name_en,
    last_name_en,
    first_name_ar,
    last_name_ar,
    department,
    job_title,
    hire_date,
    employment_status,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_company_id,
    'EMP-2025-003',
    '1234567892',
    'fatima.rashid@derayah.com',
    '+966501234569',
    'Fatima',
    'Al-Rashid',
    'فاطمة',
    'الراشد',
    'Data Science',
    'Data Scientist',
    '2023-09-10',
    'active',
    now(),
    now()
  ) RETURNING id INTO v_fatima_id;
  
  -- Create Portfolio for Sarah
  INSERT INTO portfolios (
    id,
    portfolio_type,
    company_id,
    employee_id,
    total_shares,
    available_shares,
    locked_shares,
    portfolio_number,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    'employee_vested',
    v_company_id,
    v_sarah_id,
    0,
    0,
    0,
    'PORT-2025-001',
    now(),
    now()
  ) RETURNING id INTO v_sarah_portfolio_id;
  
  -- Create Portfolio for Khalid
  INSERT INTO portfolios (
    id,
    portfolio_type,
    company_id,
    employee_id,
    total_shares,
    available_shares,
    locked_shares,
    portfolio_number,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    'employee_vested',
    v_company_id,
    v_khalid_id,
    0,
    0,
    0,
    'PORT-2025-002',
    now(),
    now()
  ) RETURNING id INTO v_khalid_portfolio_id;
  
  -- Create Portfolio for Fatima
  INSERT INTO portfolios (
    id,
    portfolio_type,
    company_id,
    employee_id,
    total_shares,
    available_shares,
    locked_shares,
    portfolio_number,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    'employee_vested',
    v_company_id,
    v_fatima_id,
    0,
    0,
    0,
    'PORT-2025-003',
    now(),
    now()
  ) RETURNING id INTO v_fatima_portfolio_id;
  
  -- Create Grants for each employee
  -- Sarah: 3M shares
  INSERT INTO grants (
    id,
    grant_number,
    company_id,
    plan_id,
    employee_id,
    grant_date,
    total_shares,
    vested_shares,
    exercised_shares,
    forfeited_shares,
    remaining_unvested_shares,
    vesting_start_date,
    vesting_end_date,
    status,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    'GRANT-2025-001',
    v_company_id,
    v_plan_id,
    v_sarah_id,
    '2025-01-01',
    3000000,
    0,
    0,
    0,
    3000000,
    '2025-01-01',
    '2028-12-31',
    'active',
    now(),
    now()
  ) RETURNING id INTO v_sarah_grant_id;
  
  -- Khalid: 3.5M shares
  INSERT INTO grants (
    id,
    grant_number,
    company_id,
    plan_id,
    employee_id,
    grant_date,
    total_shares,
    vested_shares,
    exercised_shares,
    forfeited_shares,
    remaining_unvested_shares,
    vesting_start_date,
    vesting_end_date,
    status,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    'GRANT-2025-002',
    v_company_id,
    v_plan_id,
    v_khalid_id,
    '2025-01-01',
    3500000,
    0,
    0,
    0,
    3500000,
    '2025-01-01',
    '2028-12-31',
    'active',
    now(),
    now()
  ) RETURNING id INTO v_khalid_grant_id;
  
  -- Fatima: 3.5M shares
  INSERT INTO grants (
    id,
    grant_number,
    company_id,
    plan_id,
    employee_id,
    grant_date,
    total_shares,
    vested_shares,
    exercised_shares,
    forfeited_shares,
    remaining_unvested_shares,
    vesting_start_date,
    vesting_end_date,
    status,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    'GRANT-2025-003',
    v_company_id,
    v_plan_id,
    v_fatima_id,
    '2025-01-01',
    3500000,
    0,
    0,
    0,
    3500000,
    '2025-01-01',
    '2028-12-31',
    'active',
    now(),
    now()
  ) RETURNING id INTO v_fatima_grant_id;
  
  -- Note: Individual vesting schedules will be created for each grant
  
  -- Create detailed vesting schedules for each grant
  -- Sarah's vesting schedule (3M shares over 48 months, 1-year cliff)
  -- Only insert if vesting schedules don't already exist for this grant
  IF NOT EXISTS (
    SELECT 1 FROM vesting_schedules 
    WHERE grant_id = v_sarah_grant_id
  ) THEN
    INSERT INTO vesting_schedules (
      id,
      grant_id,
      sequence_number,
      vesting_date,
      shares_to_vest,
      performance_condition_met,
      status,
      created_at
    ) 
    SELECT 
      gen_random_uuid(),
      v_sarah_grant_id,
      generate_series(1, 36) as sequence_number,
      ('2026-01-01'::date + (generate_series(1, 36) * interval '1 month'))::date as vesting_date,
      83333.33 as shares_to_vest, -- 3M shares / 36 months after cliff
      true,
      'pending',
      now()
    FROM generate_series(1, 36);
  END IF;
  
  -- Khalid's vesting schedule (3.5M shares over 48 months, 1-year cliff)
  IF NOT EXISTS (
    SELECT 1 FROM vesting_schedules 
    WHERE grant_id = v_khalid_grant_id
  ) THEN
    INSERT INTO vesting_schedules (
      id,
      grant_id,
      sequence_number,
      vesting_date,
      shares_to_vest,
      performance_condition_met,
      status,
      created_at
    ) 
    SELECT 
      gen_random_uuid(),
      v_khalid_grant_id,
      generate_series(1, 36) as sequence_number,
      ('2026-01-01'::date + (generate_series(1, 36) * interval '1 month'))::date as vesting_date,
      97222.22 as shares_to_vest, -- 3.5M shares / 36 months after cliff
      true,
      'pending',
      now()
    FROM generate_series(1, 36);
  END IF;
  
  -- Fatima's vesting schedule (3.5M shares over 48 months, 1-year cliff)
  IF NOT EXISTS (
    SELECT 1 FROM vesting_schedules 
    WHERE grant_id = v_fatima_grant_id
  ) THEN
    INSERT INTO vesting_schedules (
      id,
      grant_id,
      sequence_number,
      vesting_date,
      shares_to_vest,
      performance_condition_met,
      status,
      created_at
    ) 
    SELECT 
      gen_random_uuid(),
      v_fatima_grant_id,
      generate_series(1, 36) as sequence_number,
      ('2026-01-01'::date + (generate_series(1, 36) * interval '1 month'))::date as vesting_date,
      97222.22 as shares_to_vest, -- 3.5M shares / 36 months after cliff
      true,
      'pending',
      now()
    FROM generate_series(1, 36);
  END IF;
  
  -- Update plan with granted shares
  UPDATE incentive_plans 
  SET 
    shares_granted = 10000000,
    shares_available = 0,
    updated_at = now()
  WHERE id = v_plan_id;
  
  RAISE NOTICE 'Successfully created 3 employees with 10M shares for 4-year incentive plan';
  RAISE NOTICE 'Plan ID: %', v_plan_id;
  RAISE NOTICE 'Employees created: Sarah (%), Khalid (%), Fatima (%)', v_sarah_id, v_khalid_id, v_fatima_id;
  RAISE NOTICE 'Grants created: Sarah (%), Khalid (%), Fatima (%)', v_sarah_grant_id, v_khalid_grant_id, v_fatima_grant_id;
  
END $$;
