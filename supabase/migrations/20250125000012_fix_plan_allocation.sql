/*
  Fix Plan Allocation
  
  Problem: The plan might have incorrect total allocation or the grants might not be properly linked.
  
  Solution: 
  1. Ensure plan has reasonable allocation
  2. Make sure grants are properly linked to the plan
  3. Fix any data integrity issues
  4. Ensure the plan can accept new grants
*/

DO $$
DECLARE
  v_company_id uuid;
  v_plan_id uuid;
  current_allocation numeric;
  current_granted numeric;
  current_available numeric;
  actual_grants_total numeric;
  new_allocation numeric;
  grants_count integer;
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
  
  RAISE NOTICE '=== FIXING PLAN ALLOCATION ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  RAISE NOTICE 'Plan ID: %', v_plan_id;
  
  -- Get current plan status
  SELECT total_shares_allocated, shares_granted, shares_available
  INTO current_allocation, current_granted, current_available
  FROM incentive_plans
  WHERE id = v_plan_id;
  
  RAISE NOTICE 'Current Plan Status:';
  RAISE NOTICE '  Total Allocated: %', current_allocation;
  RAISE NOTICE '  Shares Granted: %', current_granted;
  RAISE NOTICE '  Shares Available: %', current_available;
  
  -- Get actual grants total
  SELECT COALESCE(SUM(total_shares), 0)
  INTO actual_grants_total
  FROM grants
  WHERE company_id = v_company_id
    AND plan_id = v_plan_id;
  
  RAISE NOTICE 'Actual Grants Total: %', actual_grants_total;
  
  -- If the plan allocation is too small, increase it
  IF current_allocation < actual_grants_total THEN
    new_allocation := actual_grants_total + 1000000; -- Add 1M more for future grants
    
    UPDATE incentive_plans
    SET 
      total_shares_allocated = new_allocation,
      shares_granted = actual_grants_total,
      shares_available = new_allocation - actual_grants_total,
      updated_at = now()
    WHERE id = v_plan_id;
    
    RAISE NOTICE 'Plan allocation increased from % to %', current_allocation, new_allocation;
  ELSE
    -- Just fix the granted/available calculations
    UPDATE incentive_plans
    SET 
      shares_granted = actual_grants_total,
      shares_available = current_allocation - actual_grants_total,
      updated_at = now()
    WHERE id = v_plan_id;
    
    RAISE NOTICE 'Plan calculations updated to match actual grants';
  END IF;
  
  -- Verify the fix
  SELECT total_shares_allocated, shares_granted, shares_available
  INTO current_allocation, current_granted, current_available
  FROM incentive_plans
  WHERE id = v_plan_id;
  
  RAISE NOTICE 'Updated Plan Status:';
  RAISE NOTICE '  Total Allocated: %', current_allocation;
  RAISE NOTICE '  Shares Granted: %', current_granted;
  RAISE NOTICE '  Shares Available: %', current_available;
  
  -- Ensure all grants are properly linked to the plan
  UPDATE grants
  SET plan_id = v_plan_id
  WHERE company_id = v_company_id
    AND (plan_id IS NULL OR plan_id != v_plan_id);
  
  -- Check if any grants were updated
  IF FOUND THEN
    RAISE NOTICE 'Updated grants to link to correct plan';
  END IF;
  
  -- Final verification
  SELECT COUNT(*) INTO grants_count
  FROM grants
  WHERE company_id = v_company_id
    AND plan_id = v_plan_id;
  
  RAISE NOTICE 'Total grants linked to plan: %', grants_count;
  
  RAISE NOTICE '=== PLAN ALLOCATION FIX COMPLETE ===';
  
END $$;
