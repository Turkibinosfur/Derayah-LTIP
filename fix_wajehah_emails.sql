-- Fix wajehah.com@gmail.com and wajehah.sa@gmail.com employee records
-- Run this SQL directly in your Supabase SQL Editor

DO $$
DECLARE
  v_company_id uuid;
  v_employee_id uuid;
  v_employee_count integer := 0;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE NOTICE 'Derayah Financial company not found';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Fixing wajehah.com@gmail.com and wajehah.sa@gmail.com employee records...';
  
  -- Check if wajehah.com@gmail.com exists
  SELECT id INTO v_employee_id
  FROM employees
  WHERE email = 'wajehah.com@gmail.com'
  AND company_id = v_company_id;
  
  IF v_employee_id IS NOT NULL THEN
    RAISE NOTICE 'wajehah.com@gmail.com already exists: %', v_employee_id;
    
    -- Enable portal access
    UPDATE employees
    SET portal_access_enabled = true,
        portal_username = 'wajehah.com',
        portal_password = 'WajehahCom123!'
    WHERE id = v_employee_id;
    
    RAISE NOTICE 'Enabled portal access for wajehah.com@gmail.com';
  ELSE
    RAISE NOTICE 'wajehah.com@gmail.com not found, creating employee record...';
    
    -- Find any existing employee to update
    SELECT id INTO v_employee_id
    FROM employees
    WHERE company_id = v_company_id
    LIMIT 1;
    
    IF v_employee_id IS NOT NULL THEN
      -- Update existing employee with wajehah.com@gmail.com
      UPDATE employees
      SET email = 'wajehah.com@gmail.com',
          first_name_en = 'Wajehah',
          last_name_en = 'Al-Zahrani',
          portal_access_enabled = true,
          portal_username = 'wajehah.com',
          portal_password = 'WajehahCom123!'
      WHERE id = v_employee_id;
      
      RAISE NOTICE 'Updated employee % with wajehah.com@gmail.com', v_employee_id;
    ELSE
      -- Create new employee
      INSERT INTO employees (
        id,
        company_id,
        employee_number,
        national_id,
        email,
        first_name_en,
        last_name_en,
        department,
        job_title,
        hire_date,
        employment_status,
        portal_access_enabled,
        portal_username,
        portal_password,
        created_at,
        updated_at
      ) VALUES (
        gen_random_uuid(),
        v_company_id,
        'EMP-WAJEHAH-001',
        '1234567890',
        'wajehah.com@gmail.com',
        'Wajehah',
        'Al-Zahrani',
        'Finance',
        'Senior Analyst',
        '2024-01-01',
        'active',
        true,
        'wajehah.com',
        'WajehahCom123!',
        now(),
        now()
      ) RETURNING id INTO v_employee_id;
      
      RAISE NOTICE 'Created new employee record for wajehah.com@gmail.com: %', v_employee_id;
    END IF;
  END IF;
  
  -- Check if wajehah.sa@gmail.com exists
  SELECT id INTO v_employee_id
  FROM employees
  WHERE email = 'wajehah.sa@gmail.com'
  AND company_id = v_company_id;
  
  IF v_employee_id IS NOT NULL THEN
    RAISE NOTICE 'wajehah.sa@gmail.com already exists: %', v_employee_id;
    
    -- Enable portal access
    UPDATE employees
    SET portal_access_enabled = true,
        portal_username = 'wajehah.sa',
        portal_password = 'WajehahSa123!'
    WHERE id = v_employee_id;
    
    RAISE NOTICE 'Enabled portal access for wajehah.sa@gmail.com';
  ELSE
    RAISE NOTICE 'wajehah.sa@gmail.com not found, creating employee record...';
    
    -- Find any existing employee to update (different from wajehah.com)
    SELECT id INTO v_employee_id
    FROM employees
    WHERE company_id = v_company_id
    AND email != 'wajehah.com@gmail.com'
    LIMIT 1;
    
    IF v_employee_id IS NOT NULL THEN
      -- Update existing employee with wajehah.sa@gmail.com
      UPDATE employees
      SET email = 'wajehah.sa@gmail.com',
          first_name_en = 'Fatima',
          last_name_en = 'Al-Zahrani',
          portal_access_enabled = true,
          portal_username = 'wajehah.sa',
          portal_password = 'WajehahSa123!'
      WHERE id = v_employee_id;
      
      RAISE NOTICE 'Updated employee % with wajehah.sa@gmail.com', v_employee_id;
    ELSE
      -- Create new employee
      INSERT INTO employees (
        id,
        company_id,
        employee_number,
        national_id,
        email,
        first_name_en,
        last_name_en,
        department,
        job_title,
        hire_date,
        employment_status,
        portal_access_enabled,
        portal_username,
        portal_password,
        created_at,
        updated_at
      ) VALUES (
        gen_random_uuid(),
        v_company_id,
        'EMP-FATIMA-001',
        '1234567891',
        'wajehah.sa@gmail.com',
        'Fatima',
        'Al-Zahrani',
        'Finance',
        'Senior Analyst',
        '2024-01-01',
        'active',
        true,
        'wajehah.sa',
        'WajehahSa123!',
        now(),
        now()
      ) RETURNING id INTO v_employee_id;
      
      RAISE NOTICE 'Created new employee record for wajehah.sa@gmail.com: %', v_employee_id;
    END IF;
  END IF;
  
  -- Verify the results
  RAISE NOTICE 'Verification - Employee records:';
  FOR v_employee_id IN 
    SELECT id, first_name_en, last_name_en, email, portal_access_enabled, portal_username, portal_password
    FROM employees 
    WHERE email IN ('wajehah.com@gmail.com', 'wajehah.sa@gmail.com')
    AND company_id = v_company_id
  LOOP
    RAISE NOTICE 'ID: %, Name: % %, Email: %, Portal Access: %, Username: %, Password: %', 
      v_employee_id, v_employee_id, v_employee_id, v_employee_id, v_employee_id, v_employee_id, v_employee_id;
  END LOOP;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error: %', SQLERRM;
END;
$$;

-- Show final results
SELECT 
  '=== FINAL EMPLOYEE RECORDS ===' as info;

SELECT 
  id,
  first_name_en,
  last_name_en,
  email,
  portal_access_enabled,
  portal_username,
  portal_password
FROM employees 
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
AND email IN ('wajehah.com@gmail.com', 'wajehah.sa@gmail.com')
ORDER BY email;
