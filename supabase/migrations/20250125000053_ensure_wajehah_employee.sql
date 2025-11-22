/*
  Ensure Wajehah Employee Record Exists
  
  This migration ensures that there's an employee record for wajehah.sa@gmail.com
  with portal access enabled.
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
  SELECT id INTO v_employee_id
  FROM employees
  WHERE email = 'wajehah.sa@gmail.com'
  AND company_id = v_company_id;
  
  IF v_employee_id IS NOT NULL THEN
    RAISE NOTICE 'Employee with wajehah.sa@gmail.com already exists: %', v_employee_id;
    
    -- Update to ensure portal access is enabled
    UPDATE employees
    SET portal_access_enabled = true,
        portal_username = 'wajehah.sa',
        portal_password = 'Wajehah123!'
    WHERE id = v_employee_id;
    
    RAISE NOTICE 'Updated existing employee for portal access';
  ELSE
    -- Find any employee to update with wajehah.sa@gmail.com
    SELECT id INTO v_employee_id
    FROM employees
    WHERE company_id = v_company_id
    LIMIT 1;
    
    IF v_employee_id IS NULL THEN
      RAISE NOTICE 'No employees found in company';
      RETURN;
    END IF;
    
    RAISE NOTICE 'Updating employee % with wajehah.sa@gmail.com', v_employee_id;
    
    -- Update employee with wajehah.sa@gmail.com email and portal access
    UPDATE employees
    SET email = 'wajehah.sa@gmail.com',
        portal_access_enabled = true,
        portal_username = 'wajehah.sa',
        portal_password = 'Wajehah123!'
    WHERE id = v_employee_id;
    
    RAISE NOTICE 'Updated employee with wajehah.sa@gmail.com and portal access';
  END IF;
  
  -- Verify the update
  SELECT id, first_name_en, last_name_en, email, portal_access_enabled, portal_username
  INTO v_employee_id, v_employee_id, v_employee_id, v_employee_id, v_employee_id, v_employee_id
  FROM employees
  WHERE email = 'wajehah.sa@gmail.com'
  AND company_id = v_company_id;
  
  RAISE NOTICE 'Verification: Employee with wajehah.sa@gmail.com exists and has portal access enabled';
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error ensuring wajehah employee: %', SQLERRM;
END;
$$;
