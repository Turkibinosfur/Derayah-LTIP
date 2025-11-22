/*
  Check Authentication Setup
  
  Problem: Grants still not showing despite RLS policy fixes.
  This might be due to authentication/authorization issues.
  
  Solution: Check the complete authentication setup and ensure proper user-company relationships.
*/

DO $$
DECLARE
  v_company_id uuid;
  rec RECORD;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Financial company not found';
  END IF;
  
  RAISE NOTICE '=== AUTHENTICATION SETUP CHECK ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  
  -- Check company_users
  RAISE NOTICE 'Company Users:';
  FOR rec IN 
    SELECT user_id, role, created_at
    FROM company_users
    WHERE company_id = v_company_id
  LOOP
    RAISE NOTICE '  User ID: %, Role: %, Created: %', rec.user_id, rec.role, rec.created_at;
  END LOOP;
  
  -- Check if there are any company_users
  IF NOT EXISTS (SELECT 1 FROM company_users WHERE company_id = v_company_id) THEN
    RAISE NOTICE 'ERROR: No company_users found for Derayah Financial!';
    RAISE NOTICE 'This is likely the root cause - users cannot access company data without company_users records.';
    
    -- Try to find any users that might be associated with this company
    RAISE NOTICE 'Checking for potential users...';
    FOR rec IN 
      SELECT DISTINCT user_id
      FROM employees
      WHERE company_id = v_company_id AND user_id IS NOT NULL
    LOOP
      RAISE NOTICE '  Found employee with user_id: %', rec.user_id;
    END LOOP;
    
  ELSE
    RAISE NOTICE 'SUCCESS: Company users found';
  END IF;
  
  -- Check employees and their user_id
  RAISE NOTICE 'Employees and their user_id:';
  FOR rec IN 
    SELECT first_name_en, last_name_en, email, user_id
    FROM employees
    WHERE company_id = v_company_id
  LOOP
    RAISE NOTICE '  % % (%) - user_id: %', rec.first_name_en, rec.last_name_en, rec.email, rec.user_id;
  END LOOP;
  
  -- Check grants again with more detail
  RAISE NOTICE 'Grants with company_id check:';
  FOR rec IN 
    SELECT grant_number, total_shares, status, company_id, employee_id
    FROM grants
    WHERE company_id = v_company_id
  LOOP
    RAISE NOTICE '  %: % shares, status=%, company_id=%, employee_id=%', 
      rec.grant_number, rec.total_shares, rec.status, rec.company_id, rec.employee_id;
  END LOOP;
  
  -- Check if grants exist but are not accessible due to RLS
  RAISE NOTICE 'Checking RLS policy effectiveness...';
  
  -- This will show if there are grants that exist but might not be accessible
  SELECT COUNT(*) INTO rec
  FROM grants
  WHERE company_id = v_company_id;
  
  RAISE NOTICE 'Total grants in database: %', rec;
  
  RAISE NOTICE '=== AUTHENTICATION CHECK COMPLETE ===';
  
END $$;
