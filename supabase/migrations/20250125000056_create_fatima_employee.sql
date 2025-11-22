/*
  Create Fatima Employee Record
  
  This migration creates a new employee record specifically for Fatima with wajehah.sa@gmail.com
*/

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
  IF EXISTS (SELECT 1 FROM employees WHERE email = 'wajehah.sa@gmail.com' AND company_id = v_company_id) THEN
    RAISE NOTICE 'Employee with wajehah.sa@gmail.com already exists';
    
    -- Just enable portal access
    UPDATE employees
    SET portal_access_enabled = true,
        portal_username = 'wajehah.sa',
        portal_password = 'Wajehah123!'
    WHERE email = 'wajehah.sa@gmail.com' AND company_id = v_company_id;
    
    RAISE NOTICE 'Enabled portal access for existing employee';
  ELSE
    -- Create new employee record for Fatima
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
  
  -- Verify the employee exists
  SELECT id, first_name_en, last_name_en, email, portal_access_enabled
  INTO v_employee_id, v_employee_id, v_employee_id, v_employee_id, v_employee_id
  FROM employees
  WHERE email = 'wajehah.sa@gmail.com'
  AND company_id = v_company_id;
  
  RAISE NOTICE 'Verification: Employee with wajehah.sa@gmail.com exists and has portal access';
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error creating Fatima employee: %', SQLERRM;
END;
$$;
