/*
  Link Wajehah Employee to Existing Auth User
  
  Problem: wajehah.sa@gmail.com auth user exists but is not linked to any employee
  Solution: Link the existing auth user to the appropriate employee record
  
  This migration will:
  1. Find the existing auth user for wajehah.sa@gmail.com
  2. Link it to the appropriate employee record
  3. Enable portal access for that employee
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
  
  RAISE NOTICE 'Found auth user for wajehah.sa@gmail.com: %', v_auth_user_id;
  
  -- Find employee with email wajehah.sa@gmail.com or similar
  SELECT id INTO v_employee_id
  FROM employees
  WHERE company_id = v_company_id
  AND (email = 'wajehah.sa@gmail.com' OR email LIKE '%wajehah%' OR email LIKE '%fatima%')
  LIMIT 1;
  
  IF v_employee_id IS NULL THEN
    RAISE NOTICE 'No employee found for wajehah.sa@gmail.com';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Found employee: %', v_employee_id;
  
  -- Link auth user to employee
  UPDATE employees
  SET user_id = v_auth_user_id,
      portal_access_enabled = true,
      portal_username = 'wajehah.sa',
      portal_password = 'Wajehah123!'
  WHERE id = v_employee_id;
  
  RAISE NOTICE 'Successfully linked auth user % to employee %', v_auth_user_id, v_employee_id;
  
  -- Verify the link
  SELECT id, first_name_en, last_name_en, email, user_id, portal_access_enabled
  INTO v_employee_id, v_employee_id, v_employee_id, v_employee_id, v_employee_id, v_employee_id
  FROM employees
  WHERE id = v_employee_id;
  
  RAISE NOTICE 'Employee record updated successfully';
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error linking wajehah employee: %', SQLERRM;
END;
$$;
