/*
  Manual Wajehah Employee Linking
  
  This migration will manually link the wajehah.sa@gmail.com auth user to an employee
*/

DO $$
DECLARE
  v_auth_user_id uuid;
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
  
  -- Find auth user for wajehah.sa@gmail.com
  SELECT id INTO v_auth_user_id
  FROM auth.users
  WHERE email = 'wajehah.sa@gmail.com';
  
  IF v_auth_user_id IS NULL THEN
    RAISE NOTICE 'No auth user found for wajehah.sa@gmail.com';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Found auth user: %', v_auth_user_id;
  
  -- List all employees to see what we have
  RAISE NOTICE 'Available employees:';
  FOR v_employee_id IN 
    SELECT id FROM employees WHERE company_id = v_company_id
  LOOP
    RAISE NOTICE 'Employee ID: %', v_employee_id;
  END LOOP;
  
  -- Try to find Fatima or any employee without user_id
  SELECT id INTO v_employee_id
  FROM employees
  WHERE company_id = v_company_id
  AND (first_name_en ILIKE '%fatima%' OR first_name_en ILIKE '%wajehah%' OR user_id IS NULL)
  LIMIT 1;
  
  IF v_employee_id IS NULL THEN
    RAISE NOTICE 'No suitable employee found';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Linking to employee: %', v_employee_id;
  
  -- Link auth user to employee
  UPDATE employees
  SET user_id = v_auth_user_id,
      portal_access_enabled = true,
      portal_username = 'wajehah.sa',
      portal_password = 'Wajehah123!',
      email = 'wajehah.sa@gmail.com'
  WHERE id = v_employee_id;
  
  RAISE NOTICE 'Successfully linked auth user to employee';
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error: %', SQLERRM;
END;
$$;
