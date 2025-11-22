/*
  Fix Fatima Employee Record
  
  This migration ensures that Fatima has the correct email address and portal access enabled.
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
  
  -- Find Fatima's employee record (look for any employee with "fatima" in the name)
  SELECT id INTO v_employee_id
  FROM employees
  WHERE company_id = v_company_id
  AND (first_name_en ILIKE '%fatima%' OR last_name_en ILIKE '%fatima%' OR first_name_en ILIKE '%wajehah%')
  LIMIT 1;
  
  IF v_employee_id IS NULL THEN
    -- If no Fatima found, find any employee without portal access
    SELECT id INTO v_employee_id
    FROM employees
    WHERE company_id = v_company_id
    AND (portal_access_enabled IS NULL OR portal_access_enabled = false)
    LIMIT 1;
  END IF;
  
  IF v_employee_id IS NULL THEN
    -- If still no employee found, just pick the first one
    SELECT id INTO v_employee_id
    FROM employees
    WHERE company_id = v_company_id
    LIMIT 1;
  END IF;
  
  IF v_employee_id IS NULL THEN
    RAISE NOTICE 'No employees found in company';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Updating employee % for Fatima/Wajehah', v_employee_id;
  
  -- Update employee record with wajehah.sa@gmail.com and portal access
  UPDATE employees
  SET email = 'wajehah.sa@gmail.com',
      first_name_en = 'Fatima',
      last_name_en = 'Al-Zahrani',
      portal_access_enabled = true,
      portal_username = 'wajehah.sa',
      portal_password = 'Wajehah123!'
  WHERE id = v_employee_id;
  
  RAISE NOTICE 'Successfully updated employee for Fatima/Wajehah with portal access';
  
  -- Verify the update
  RAISE NOTICE 'Verification - Employee details:';
  FOR v_employee_id IN 
    SELECT id, first_name_en, last_name_en, email, portal_access_enabled, portal_username
    FROM employees 
    WHERE id = v_employee_id
  LOOP
    RAISE NOTICE 'ID: %, Name: % %, Email: %, Portal Access: %, Username: %', 
      v_employee_id, v_employee_id, v_employee_id, v_employee_id, v_employee_id, v_employee_id;
  END LOOP;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error fixing Fatima employee record: %', SQLERRM;
END;
$$;
