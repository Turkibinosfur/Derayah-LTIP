/*
  Diagnose Employee Email Addresses
  
  This migration shows all employees and their email addresses to help debug the login issue.
*/

DO $$
DECLARE
  rec RECORD;
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
  
  RAISE NOTICE '=== EMPLOYEE DIAGNOSTIC REPORT ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  RAISE NOTICE '';
  
  -- List all employees
  RAISE NOTICE 'All employees in Derayah Financial:';
  FOR rec IN 
    SELECT 
      id,
      first_name_en,
      last_name_en,
      email,
      portal_access_enabled,
      portal_username,
      user_id
    FROM employees 
    WHERE company_id = v_company_id
    ORDER BY first_name_en
  LOOP
    RAISE NOTICE 'ID: %, Name: % %, Email: %, Portal Access: %, Username: %, User ID: %', 
      rec.id, rec.first_name_en, rec.last_name_en, rec.email, 
      rec.portal_access_enabled, rec.portal_username, rec.user_id;
  END LOOP;
  
  RAISE NOTICE '';
  RAISE NOTICE '=== SPECIFIC CHECKS ===';
  
  -- Check for wajehah.sa@gmail.com
  IF EXISTS (SELECT 1 FROM employees WHERE email = 'wajehah.sa@gmail.com' AND company_id = v_company_id) THEN
    RAISE NOTICE '✓ Employee with wajehah.sa@gmail.com EXISTS';
  ELSE
    RAISE NOTICE '✗ Employee with wajehah.sa@gmail.com NOT FOUND';
  END IF;
  
  -- Check for wajehah.com@gmail.com
  IF EXISTS (SELECT 1 FROM employees WHERE email = 'wajehah.com@gmail.com' AND company_id = v_company_id) THEN
    RAISE NOTICE '✓ Employee with wajehah.com@gmail.com EXISTS';
  ELSE
    RAISE NOTICE '✗ Employee with wajehah.com@gmail.com NOT FOUND';
  END IF;
  
  -- Check for employees with portal access
  SELECT COUNT(*) INTO rec
  FROM employees 
  WHERE company_id = v_company_id 
  AND portal_access_enabled = true;
  
  RAISE NOTICE 'Employees with portal access enabled: %', rec;
  
  RAISE NOTICE '';
  RAISE NOTICE '=== END DIAGNOSTIC REPORT ===';
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error in diagnostic: %', SQLERRM;
END;
$$;
