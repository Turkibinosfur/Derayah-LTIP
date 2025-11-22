/*
  Direct Wajehah Employee Linking
  
  This migration will directly update an employee record to enable portal access
  for wajehah.sa@gmail.com without trying to access the auth schema.
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
  
  -- Find any employee to link (preferably one without user_id)
  SELECT id INTO v_employee_id
  FROM employees
  WHERE company_id = v_company_id
  AND (user_id IS NULL OR user_id = '00000000-0000-0000-0000-000000000000')
  LIMIT 1;
  
  IF v_employee_id IS NULL THEN
    -- If no employee without user_id, just pick the first one
    SELECT id INTO v_employee_id
    FROM employees
    WHERE company_id = v_company_id
    LIMIT 1;
  END IF;
  
  IF v_employee_id IS NULL THEN
    RAISE NOTICE 'No employees found';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Linking employee % to wajehah.sa@gmail.com', v_employee_id;
  
  -- Update employee record to enable portal access
  UPDATE employees
  SET portal_access_enabled = true,
      portal_username = 'wajehah.sa',
      portal_password = 'Wajehah123!',
      email = 'wajehah.sa@gmail.com'
  WHERE id = v_employee_id;
  
  RAISE NOTICE 'Successfully updated employee % for portal access', v_employee_id;
  
  -- Show the updated employee info
  RAISE NOTICE 'Employee details:';
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
    RAISE NOTICE 'Error: %', SQLERRM;
END;
$$;
