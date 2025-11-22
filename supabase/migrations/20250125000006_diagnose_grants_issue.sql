/*
  Diagnose Grants and Employee Relationship Issue
  
  Problem: Grants page shows no results and employees show zero shares, suggesting grants are not properly linked to employees.
  
  Solution: Check the actual data relationships and identify the issue.
*/

DO $$
DECLARE
  v_company_id uuid;
  v_plan_id uuid;
  v_sarah_id uuid;
  v_khalid_id uuid;
  v_fatima_id uuid;
  grant_count integer;
  employee_count integer;
  rec RECORD;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Financial company not found';
  END IF;
  
  RAISE NOTICE 'Company ID: %', v_company_id;
  
  -- Check if employees exist
  SELECT COUNT(*) INTO employee_count
  FROM employees
  WHERE company_id = v_company_id;
  
  RAISE NOTICE 'Total employees in company: %', employee_count;
  
  -- List all employees
  RAISE NOTICE 'Employees:';
  FOR rec IN 
    SELECT id, employee_number, first_name_en, last_name_en, email
    FROM employees
    WHERE company_id = v_company_id
  LOOP
    RAISE NOTICE '  - %: % % (%) - %', rec.employee_number, rec.first_name_en, rec.last_name_en, rec.email, rec.id;
  END LOOP;
  
  -- Check if grants exist
  SELECT COUNT(*) INTO grant_count
  FROM grants
  WHERE company_id = v_company_id;
  
  RAISE NOTICE 'Total grants in company: %', grant_count;
  
  -- List all grants with employee info
  RAISE NOTICE 'Grants:';
  FOR rec IN 
    SELECT 
      g.grant_number,
      g.total_shares,
      g.status,
      e.first_name_en,
      e.last_name_en,
      e.employee_number,
      g.employee_id
    FROM grants g
    LEFT JOIN employees e ON g.employee_id = e.id
    WHERE g.company_id = v_company_id
  LOOP
    RAISE NOTICE '  - %: % shares, status=%, employee=% % (%), employee_id=%', 
      rec.grant_number, rec.total_shares, rec.status, rec.first_name_en, rec.last_name_en, rec.employee_number, rec.employee_id;
  END LOOP;
  
  -- Check if there are any grants with NULL employee_id
  SELECT COUNT(*) INTO grant_count
  FROM grants
  WHERE company_id = v_company_id AND employee_id IS NULL;
  
  IF grant_count > 0 THEN
    RAISE NOTICE 'WARNING: % grants have NULL employee_id', grant_count;
  END IF;
  
  -- Check if there are any grants with invalid employee_id
  SELECT COUNT(*) INTO grant_count
  FROM grants g
  LEFT JOIN employees e ON g.employee_id = e.id
  WHERE g.company_id = v_company_id AND e.id IS NULL;
  
  IF grant_count > 0 THEN
    RAISE NOTICE 'WARNING: % grants have invalid employee_id references', grant_count;
  END IF;
  
  -- Check RLS policies
  RAISE NOTICE 'Checking RLS policies for grants table:';
  FOR rec IN 
    SELECT policyname, cmd, roles
    FROM pg_policies 
    WHERE tablename = 'grants'
  LOOP
    RAISE NOTICE '  - %: % for %', rec.policyname, rec.cmd, rec.roles;
  END LOOP;
  
  -- Check if there are any grants that should be visible
  SELECT COUNT(*) INTO grant_count
  FROM grants
  WHERE company_id = v_company_id AND status = 'active';
  
  RAISE NOTICE 'Active grants: %', grant_count;
  
  -- Check if there are any grants that should be visible
  SELECT COUNT(*) INTO grant_count
  FROM grants
  WHERE company_id = v_company_id AND status = 'pending_signature';
  
  RAISE NOTICE 'Pending signature grants: %', grant_count;
  
END $$;
