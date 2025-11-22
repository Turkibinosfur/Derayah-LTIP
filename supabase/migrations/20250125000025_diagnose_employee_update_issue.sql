/*
  Diagnostic migration to check why employee updates are failing.
  This migration will help identify the root cause of the update failure.
*/

DO $$
DECLARE
  rec RECORD;
  v_company_id uuid;
  v_employee_count integer;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';

  IF v_company_id IS NULL THEN
    RAISE NOTICE 'Company "Derayah Financial" not found. Exiting migration.';
    RETURN;
  END IF;

  RAISE NOTICE 'Processing company ID: %', v_company_id;

  -- Check if employees table exists and has the expected structure
  RAISE NOTICE '=== EMPLOYEES TABLE STRUCTURE ===';
  FOR rec IN
    SELECT column_name, data_type, is_nullable, column_default
    FROM information_schema.columns 
    WHERE table_name = 'employees' 
    ORDER BY ordinal_position
  LOOP
    RAISE NOTICE 'Column: % | Type: % | Nullable: % | Default: %', 
      rec.column_name, rec.data_type, rec.is_nullable, rec.column_default;
  END LOOP;

  -- Check RLS policies on employees table
  RAISE NOTICE '=== RLS POLICIES ON EMPLOYEES TABLE ===';
  FOR rec IN
    SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
    FROM pg_policies 
    WHERE tablename = 'employees'
    ORDER BY policyname
  LOOP
    RAISE NOTICE 'Policy: % | Command: % | Roles: % | Qual: % | With Check: %', 
      rec.policyname, rec.cmd, rec.roles, rec.qual, rec.with_check;
  END LOOP;

  -- Check if RLS is enabled on employees table
  RAISE NOTICE '=== RLS STATUS ===';
  SELECT relrowsecurity INTO rec
  FROM pg_class 
  WHERE relname = 'employees';
  
  IF rec.relrowsecurity THEN
    RAISE NOTICE 'RLS is ENABLED on employees table';
  ELSE
    RAISE NOTICE 'RLS is DISABLED on employees table';
  END IF;

  -- Check current employees in the company
  SELECT COUNT(*) INTO v_employee_count
  FROM employees
  WHERE company_id = v_company_id;

  RAISE NOTICE 'Number of employees in company: %', v_employee_count;

  -- Show sample employee data
  RAISE NOTICE '=== SAMPLE EMPLOYEE DATA ===';
  FOR rec IN
    SELECT id, employee_number, first_name_en, last_name_en, email, 
           portal_username, portal_password, portal_access_enabled
    FROM employees
    WHERE company_id = v_company_id
    LIMIT 3
  LOOP
    RAISE NOTICE 'Employee: % % (ID: %) | Email: % | Portal: % | Username: % | Password: % | Enabled: %', 
      rec.first_name_en, rec.last_name_en, rec.id, rec.email, 
      CASE WHEN rec.portal_username IS NOT NULL THEN 'Yes' ELSE 'No' END,
      rec.portal_username, 
      CASE WHEN rec.portal_password IS NOT NULL THEN '[SET]' ELSE '[NOT SET]' END,
      rec.portal_access_enabled;
  END LOOP;

  -- Test a simple update to see if it works
  RAISE NOTICE '=== TESTING SIMPLE UPDATE ===';
  BEGIN
    UPDATE employees 
    SET updated_at = now() 
    WHERE company_id = v_company_id 
    AND id = (SELECT id FROM employees WHERE company_id = v_company_id LIMIT 1);
    
    RAISE NOTICE 'Simple update test: SUCCESS';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Simple update test: FAILED - %', SQLERRM;
  END;

END $$;
