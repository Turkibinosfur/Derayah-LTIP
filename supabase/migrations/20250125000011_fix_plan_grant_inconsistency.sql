/*
  Fix Plan-Grant Inconsistency
  
  Problem: 
  - Incentive plan shows 1,000,000 granted shares
  - Available shares shows 0
  - Employees show 0 shares
  - Cannot create new grants due to 0 available shares
  
  This suggests the plan's shares_granted doesn't match the actual grants in the database.
  
  Solution: 
  1. Check actual grants vs plan allocation
  2. Fix the plan's shares_granted to match actual grants
  3. Recalculate available shares
  4. Ensure data consistency
*/

DO $$
DECLARE
  v_company_id uuid;
  v_plan_id uuid;
  actual_granted_shares numeric;
  plan_allocated_shares numeric;
  plan_granted_shares numeric;
  plan_available_shares numeric;
  rec RECORD;
  null_employee_count integer;
  invalid_employee_count integer;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Financial company not found';
  END IF;
  
  -- Get the plan ID
  SELECT id INTO v_plan_id
  FROM incentive_plans
  WHERE company_id = v_company_id
    AND plan_code = 'DESP-2025-001';
  
  IF v_plan_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Employee Stock Plan 2025 not found';
  END IF;
  
  RAISE NOTICE '=== FIXING PLAN-GRANT INCONSISTENCY ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  RAISE NOTICE 'Plan ID: %', v_plan_id;
  
  -- Check current plan allocation
  SELECT total_shares_allocated, shares_granted, shares_available
  INTO plan_allocated_shares, plan_granted_shares, plan_available_shares
  FROM incentive_plans
  WHERE id = v_plan_id;
  
  RAISE NOTICE 'Current Plan Status:';
  RAISE NOTICE '  Total Allocated: %', plan_allocated_shares;
  RAISE NOTICE '  Shares Granted: %', plan_granted_shares;
  RAISE NOTICE '  Shares Available: %', plan_available_shares;
  
  -- Check actual grants in database
  SELECT COALESCE(SUM(total_shares), 0)
  INTO actual_granted_shares
  FROM grants
  WHERE company_id = v_company_id
    AND plan_id = v_plan_id;
  
  RAISE NOTICE 'Actual Grants in Database:';
  RAISE NOTICE '  Total Shares Granted: %', actual_granted_shares;
  
  -- List all grants for this plan
  RAISE NOTICE 'Grants for this plan:';
  FOR rec IN 
    SELECT 
      g.grant_number,
      g.total_shares,
      g.status,
      e.first_name_en,
      e.last_name_en
    FROM grants g
    LEFT JOIN employees e ON g.employee_id = e.id
    WHERE g.company_id = v_company_id
      AND g.plan_id = v_plan_id
    ORDER BY g.grant_number
  LOOP
    RAISE NOTICE '  %: % shares, status=%, employee=% %', 
      rec.grant_number, rec.total_shares, rec.status, rec.first_name_en, rec.last_name_en;
  END LOOP;
  
  -- Check if there's a mismatch
  IF plan_granted_shares != actual_granted_shares THEN
    RAISE NOTICE 'INCONSISTENCY DETECTED:';
    RAISE NOTICE '  Plan shows granted: %', plan_granted_shares;
    RAISE NOTICE '  Actual grants total: %', actual_granted_shares;
    
    -- Fix the plan to match actual grants
    UPDATE incentive_plans
    SET 
      shares_granted = actual_granted_shares,
      shares_available = total_shares_allocated - actual_granted_shares,
      updated_at = now()
    WHERE id = v_plan_id;
    
    RAISE NOTICE 'Plan updated to match actual grants';
  ELSE
    RAISE NOTICE 'Plan and grants are consistent';
  END IF;
  
  -- Verify the fix
  SELECT total_shares_allocated, shares_granted, shares_available
  INTO plan_allocated_shares, plan_granted_shares, plan_available_shares
  FROM incentive_plans
  WHERE id = v_plan_id;
  
  RAISE NOTICE 'Updated Plan Status:';
  RAISE NOTICE '  Total Allocated: %', plan_allocated_shares;
  RAISE NOTICE '  Shares Granted: %', plan_granted_shares;
  RAISE NOTICE '  Shares Available: %', plan_available_shares;
  
  -- Check if grants are properly linked to employees
  RAISE NOTICE 'Checking employee-grant relationships:';
  FOR rec IN 
    SELECT 
      e.first_name_en,
      e.last_name_en,
      e.employee_number,
      COALESCE(SUM(g.total_shares), 0) as total_shares
    FROM employees e
    LEFT JOIN grants g ON e.id = g.employee_id AND g.company_id = v_company_id
    WHERE e.company_id = v_company_id
    GROUP BY e.id, e.first_name_en, e.last_name_en, e.employee_number
    ORDER BY e.employee_number
  LOOP
    RAISE NOTICE '  % % (%): % shares', 
      rec.first_name_en, rec.last_name_en, rec.employee_number, rec.total_shares;
  END LOOP;
  
  -- Check if there are any grants with NULL employee_id
  SELECT COUNT(*) INTO null_employee_count
  FROM grants
  WHERE company_id = v_company_id AND employee_id IS NULL;
  
  IF null_employee_count > 0 THEN
    RAISE NOTICE 'WARNING: % grants have NULL employee_id', null_employee_count;
  END IF;
  
  -- Check if there are any grants with invalid employee_id
  SELECT COUNT(*) INTO invalid_employee_count
  FROM grants g
  LEFT JOIN employees e ON g.employee_id = e.id
  WHERE g.company_id = v_company_id AND e.id IS NULL;
  
  IF invalid_employee_count > 0 THEN
    RAISE NOTICE 'WARNING: % grants have invalid employee_id references', invalid_employee_count;
  END IF;
  
  RAISE NOTICE '=== PLAN-GRANT CONSISTENCY FIX COMPLETE ===';
  
END $$;
