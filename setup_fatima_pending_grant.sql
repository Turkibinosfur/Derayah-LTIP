-- Setup Fatima Al-Zahrani with a grant in "Pending Signature" status
-- Run this SQL directly in your Supabase SQL Editor

-- First, let's check if Fatima exists and get her details
SELECT 
  '=== FATIMA EMPLOYEE RECORD ===' as info;

SELECT 
  id,
  first_name_en,
  last_name_en,
  email,
  portal_access_enabled,
  company_id
FROM employees 
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
AND first_name_en = 'Fatima'
AND last_name_en = 'Al-Zahrani';

-- Check if there are any existing grants for Fatima
SELECT 
  '=== EXISTING GRANTS FOR FATIMA ===' as info;

SELECT 
  g.id,
  g.grant_number,
  g.total_shares,
  g.status,
  g.grant_date,
  ip.plan_name_en
FROM grants g
LEFT JOIN incentive_plans ip ON g.plan_id = ip.id
WHERE g.employee_id IN (
  SELECT id FROM employees 
  WHERE company_id = (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial')
  AND first_name_en = 'Fatima'
  AND last_name_en = 'Al-Zahrani'
);

-- Create a grant with "Pending Signature" status for Fatima if she doesn't have one
DO $$
DECLARE
  v_company_id uuid;
  v_fatima_id uuid;
  v_plan_id uuid;
  v_grant_id uuid;
  v_grant_number text;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE NOTICE 'Derayah Financial company not found';
    RETURN;
  END IF;
  
  -- Get Fatima's employee ID
  SELECT id INTO v_fatima_id
  FROM employees
  WHERE company_id = v_company_id
  AND first_name_en = 'Fatima'
  AND last_name_en = 'Al-Zahrani';
  
  IF v_fatima_id IS NULL THEN
    RAISE NOTICE 'Fatima Al-Zahrani not found';
    RETURN;
  END IF;
  
  -- Get the first available incentive plan
  SELECT id INTO v_plan_id
  FROM incentive_plans
  WHERE company_id = v_company_id
  LIMIT 1;
  
  IF v_plan_id IS NULL THEN
    RAISE NOTICE 'No incentive plan found for company';
    RETURN;
  END IF;
  
  -- Check if Fatima already has a grant
  IF EXISTS (SELECT 1 FROM grants WHERE employee_id = v_fatima_id) THEN
    RAISE NOTICE 'Fatima already has grants, updating status to pending_signature...';
    
    -- Update existing grant to pending signature status
    UPDATE grants
    SET status = 'pending_signature'
    WHERE employee_id = v_fatima_id
    AND status != 'pending_signature';
    
    RAISE NOTICE 'Updated existing grant to pending signature status';
  ELSE
    RAISE NOTICE 'Creating new grant for Fatima with pending signature status...';
    
    -- Generate grant number
    v_grant_number := 'GR-' || to_char(now(), 'YYYYMMDD') || '-' || lpad((SELECT COUNT(*) + 1 FROM grants)::text, 6, '0');
    
    -- Create new grant
    INSERT INTO grants (
      id,
      company_id,
      employee_id,
      plan_id,
      grant_number,
      total_shares,
      vested_shares,
      remaining_unvested_shares,
      status,
      grant_date,
      vesting_start_date,
      vesting_end_date,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_company_id,
      v_fatima_id,
      v_plan_id,
      v_grant_number,
      50000, -- 50,000 shares
      0, -- No shares vested yet
      50000, -- All shares unvested
      'pending_signature',
      now(),
      now(), -- vesting_start_date
      now() + interval '4 years', -- vesting_end_date (4 years from now)
      now(),
      now()
    ) RETURNING id INTO v_grant_id;
    
    RAISE NOTICE 'Created new grant % for Fatima with ID: %', v_grant_number, v_grant_id;
  END IF;
  
  RAISE NOTICE 'Fatima grant setup completed successfully';
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error setting up Fatima grant: %', SQLERRM;
END;
$$;

-- Show final results
SELECT 
  '=== FINAL GRANTS FOR FATIMA ===' as info;

SELECT 
  g.id,
  g.grant_number,
  g.total_shares,
  g.vested_shares,
  g.remaining_unvested_shares,
  g.status,
  g.grant_date,
  ip.plan_name_en,
  e.first_name_en,
  e.last_name_en,
  e.email
FROM grants g
LEFT JOIN incentive_plans ip ON g.plan_id = ip.id
LEFT JOIN employees e ON g.employee_id = e.id
WHERE g.employee_id IN (
  SELECT id FROM employees 
  WHERE company_id = (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial')
  AND first_name_en = 'Fatima'
  AND last_name_en = 'Al-Zahrani'
)
ORDER BY g.created_at DESC;
