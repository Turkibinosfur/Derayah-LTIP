-- Fix Fatima Login Issue
-- Run this SQL directly in your Supabase SQL Editor

-- First, let's see what employees exist
SELECT 
  id,
  first_name_en,
  last_name_en,
  email,
  portal_access_enabled,
  portal_username
FROM employees 
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
ORDER BY first_name_en;

-- Now let's fix the issue by updating an existing employee or creating a new one
-- This will ensure wajehah.sa@gmail.com has an employee record with portal access

-- Step 1: Check if any employee with wajehah.sa@gmail.com exists
DO $$
DECLARE
  v_employee_id uuid;
  v_company_id uuid;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE NOTICE 'Derayah Financial company not found';
    RETURN;
  END IF;
  
  -- Check if employee with wajehah.sa@gmail.com already exists
  SELECT id INTO v_employee_id
  FROM employees
  WHERE email = 'wajehah.sa@gmail.com'
  AND company_id = v_company_id;
  
  IF v_employee_id IS NOT NULL THEN
    RAISE NOTICE 'Employee with wajehah.sa@gmail.com already exists: %', v_employee_id;
    
    -- Enable portal access
    UPDATE employees
    SET portal_access_enabled = true,
        portal_username = 'wajehah.sa',
        portal_password = 'Wajehah123!'
    WHERE id = v_employee_id;
    
    RAISE NOTICE 'Enabled portal access for existing employee';
  ELSE
    RAISE NOTICE 'No employee with wajehah.sa@gmail.com found, creating new one...';
    
    -- Find any existing employee to update
    SELECT id INTO v_employee_id
    FROM employees
    WHERE company_id = v_company_id
    LIMIT 1;
    
    IF v_employee_id IS NOT NULL THEN
      -- Update existing employee
      UPDATE employees
      SET email = 'wajehah.sa@gmail.com',
          first_name_en = 'Fatima',
          last_name_en = 'Al-Zahrani',
          portal_access_enabled = true,
          portal_username = 'wajehah.sa',
          portal_password = 'Wajehah123!'
      WHERE id = v_employee_id;
      
      RAISE NOTICE 'Updated existing employee % with wajehah.sa@gmail.com', v_employee_id;
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
        '1234567890',
        'wajehah.sa@gmail.com',
        'Fatima',
        'Al-Zahrani',
        'Finance',
        'Senior Analyst',
        '2024-01-01',
        'active',
        true,
        'wajehah.sa',
        'Wajehah123!',
        now(),
        now()
      ) RETURNING id INTO v_employee_id;
      
      RAISE NOTICE 'Created new employee record for Fatima: %', v_employee_id;
    END IF;
  END IF;
  
  -- Verify the result
  RAISE NOTICE 'Verification - Employee with wajehah.sa@gmail.com:';
  FOR v_employee_id IN 
    SELECT id, first_name_en, last_name_en, email, portal_access_enabled, portal_username
    FROM employees 
    WHERE email = 'wajehah.sa@gmail.com'
    AND company_id = v_company_id
  LOOP
    RAISE NOTICE 'ID: %, Name: % %, Email: %, Portal Access: %, Username: %', 
      v_employee_id, v_employee_id, v_employee_id, v_employee_id, v_employee_id, v_employee_id;
  END LOOP;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error: %', SQLERRM;
END;
$$;
