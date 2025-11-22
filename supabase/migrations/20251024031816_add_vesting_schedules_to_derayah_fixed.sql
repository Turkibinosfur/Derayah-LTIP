/*
  # Add Vesting Schedules to Derayah Company
  
  1. Creates vesting schedules for Derayah
    - Standard 4-year vesting with 1-year cliff
    - Executive 5-year vesting with 1-year cliff
    - Performance-based 3-year vesting
  
  2. Links existing grants to appropriate vesting schedules
  
  3. Security
    - No RLS changes needed (existing policies apply)
*/

DO $$
DECLARE
  v_company_id uuid;
  v_standard_schedule_id uuid;
  v_executive_schedule_id uuid;
  v_performance_schedule_id uuid;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Financial company not found';
  END IF;
  
  -- Create Standard 4-Year Vesting Schedule (1-year cliff)
  INSERT INTO vesting_schedules (
    id,
    company_id,
    name,
    description,
    schedule_type,
    total_duration_months,
    cliff_months,
    vesting_frequency,
    is_template,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_company_id,
    'Standard 4-Year Vesting',
    'Standard vesting schedule: 4 years total, 1-year cliff, monthly vesting thereafter',
    'time_based',
    48,
    12,
    'monthly',
    true,
    now(),
    now()
  ) RETURNING id INTO v_standard_schedule_id;
  
  -- Create Executive 5-Year Vesting Schedule (1-year cliff)
  INSERT INTO vesting_schedules (
    id,
    company_id,
    name,
    description,
    schedule_type,
    total_duration_months,
    cliff_months,
    vesting_frequency,
    is_template,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_company_id,
    'Executive 5-Year Vesting',
    'Executive vesting schedule: 5 years total, 1-year cliff, quarterly vesting thereafter',
    'time_based',
    60,
    12,
    'quarterly',
    true,
    now(),
    now()
  ) RETURNING id INTO v_executive_schedule_id;
  
  -- Create Performance-Based 3-Year Schedule
  INSERT INTO vesting_schedules (
    id,
    company_id,
    name,
    description,
    schedule_type,
    total_duration_months,
    cliff_months,
    vesting_frequency,
    is_template,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_company_id,
    'Performance 3-Year Vesting',
    'Performance-based vesting: 3 years total, 6-month cliff, quarterly vesting with performance milestones',
    'performance_based',
    36,
    6,
    'quarterly',
    true,
    now(),
    now()
  ) RETURNING id INTO v_performance_schedule_id;
  
  -- Link all existing grants to the standard 4-year schedule
  UPDATE grants
  SET 
    vesting_schedule_id = v_standard_schedule_id,
    updated_at = now()
  WHERE company_id = v_company_id
    AND vesting_schedule_id IS NULL;
  
  RAISE NOTICE 'Created vesting schedules:';
  RAISE NOTICE '  Standard 4-Year: %', v_standard_schedule_id;
  RAISE NOTICE '  Executive 5-Year: %', v_executive_schedule_id;
  RAISE NOTICE '  Performance 3-Year: %', v_performance_schedule_id;
  RAISE NOTICE 'Linked % grants to standard schedule', (
    SELECT COUNT(*) FROM grants WHERE vesting_schedule_id = v_standard_schedule_id
  );
END $$;
