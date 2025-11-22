/*
  Test Grants Access
  
  This migration tests if grants are accessible after the RLS policy fixes.
  It will show exactly what data is available and help identify any remaining issues.
*/

DO $$
DECLARE
  v_company_id uuid;
  grant_count integer;
  rec RECORD;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Financial company not found';
  END IF;
  
  RAISE NOTICE '=== TESTING GRANTS ACCESS ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  
  -- Test 1: Count all grants for the company
  SELECT COUNT(*) INTO grant_count
  FROM grants
  WHERE company_id = v_company_id;
  
  RAISE NOTICE 'Total grants in database: %', grant_count;
  
  -- Test 2: List all grants with details
  RAISE NOTICE 'Grant Details:';
  FOR rec IN 
    SELECT 
      g.grant_number,
      g.total_shares,
      g.status,
      g.employee_id,
      e.first_name_en,
      e.last_name_en,
      e.employee_number,
      p.plan_name_en
    FROM grants g
    LEFT JOIN employees e ON g.employee_id = e.id
    LEFT JOIN incentive_plans p ON g.plan_id = p.id
    WHERE g.company_id = v_company_id
    ORDER BY g.grant_number
  LOOP
    RAISE NOTICE '  %: % shares, status=%, employee=% % (%), plan=%', 
      rec.grant_number, rec.total_shares, rec.status, rec.first_name_en, rec.last_name_en, rec.employee_number, rec.plan_name_en;
  END LOOP;
  
  -- Test 3: Check if grants have valid employee references
  SELECT COUNT(*) INTO grant_count
  FROM grants g
  LEFT JOIN employees e ON g.employee_id = e.id
  WHERE g.company_id = v_company_id AND e.id IS NULL;
  
  IF grant_count > 0 THEN
    RAISE NOTICE 'ERROR: % grants have invalid employee_id references', grant_count;
  ELSE
    RAISE NOTICE 'SUCCESS: All grants have valid employee references';
  END IF;
  
  -- Test 4: Check if grants have valid plan references
  SELECT COUNT(*) INTO grant_count
  FROM grants g
  LEFT JOIN incentive_plans p ON g.plan_id = p.id
  WHERE g.company_id = v_company_id AND p.id IS NULL;
  
  IF grant_count > 0 THEN
    RAISE NOTICE 'ERROR: % grants have invalid plan_id references', grant_count;
  ELSE
    RAISE NOTICE 'SUCCESS: All grants have valid plan references';
  END IF;
  
  -- Test 5: Sum total shares
  SELECT COALESCE(SUM(total_shares), 0) INTO grant_count
  FROM grants
  WHERE company_id = v_company_id;
  
  RAISE NOTICE 'Total shares granted: %', grant_count;
  
  -- Test 6: Check active grants
  SELECT COUNT(*) INTO grant_count
  FROM grants
  WHERE company_id = v_company_id AND status = 'active';
  
  RAISE NOTICE 'Active grants: %', grant_count;
  
  -- Test 7: Check pending grants
  SELECT COUNT(*) INTO grant_count
  FROM grants
  WHERE company_id = v_company_id AND status = 'pending_signature';
  
  RAISE NOTICE 'Pending signature grants: %', grant_count;
  
  RAISE NOTICE '=== TEST COMPLETE ===';
  
END $$;
