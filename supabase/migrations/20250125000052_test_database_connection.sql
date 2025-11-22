/*
  Test Database Connection
  
  This migration tests if we can access the database and basic tables.
*/

-- Test basic database access
DO $$
DECLARE
  v_company_count integer;
  v_employee_count integer;
BEGIN
  -- Count companies
  SELECT COUNT(*) INTO v_company_count FROM companies;
  RAISE NOTICE 'Companies found: %', v_company_count;
  
  -- Count employees
  SELECT COUNT(*) INTO v_employee_count FROM employees;
  RAISE NOTICE 'Employees found: %', v_employee_count;
  
  -- List companies
  RAISE NOTICE 'Companies:';
  FOR v_company_count IN 
    SELECT id, company_name_en FROM companies
  LOOP
    RAISE NOTICE 'Company: %', v_company_count;
  END LOOP;
  
  -- List employees
  RAISE NOTICE 'Employees:';
  FOR v_employee_count IN 
    SELECT id, first_name_en, last_name_en, email FROM employees
  LOOP
    RAISE NOTICE 'Employee: %', v_employee_count;
  END LOOP;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Database connection test failed: %', SQLERRM;
END;
$$;
