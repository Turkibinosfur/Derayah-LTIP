/*
  Adjust Grant Amounts to More Reasonable Numbers
  
  Problem: The current grants total 10 million shares, which might be too high for a typical ESOP plan.
  
  Solution: Reduce individual grant amounts to more realistic numbers while maintaining the same distribution ratio.
  
  New Allocation:
  - Sarah: 300,000 shares (was 3,000,000)
  - Khalid: 350,000 shares (was 3,500,000)  
  - Fatima: 350,000 shares (was 3,500,000)
  - Total: 1,000,000 shares (was 10,000,000)
*/

DO $$
DECLARE
  v_company_id uuid;
  v_plan_id uuid;
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
  
  -- Update individual grants to more reasonable amounts
  -- Sarah: 300,000 shares (reduced from 3,000,000)
  UPDATE grants 
  SET 
    total_shares = 300000,
    remaining_unvested_shares = 300000,
    updated_at = now()
  WHERE company_id = v_company_id 
    AND grant_number = 'GRANT-2025-001';
  
  -- Khalid: 350,000 shares (reduced from 3,500,000)
  UPDATE grants 
  SET 
    total_shares = 350000,
    remaining_unvested_shares = 350000,
    updated_at = now()
  WHERE company_id = v_company_id 
    AND grant_number = 'GRANT-2025-002';
  
  -- Fatima: 350,000 shares (reduced from 3,500,000)
  UPDATE grants 
  SET 
    total_shares = 350000,
    remaining_unvested_shares = 350000,
    updated_at = now()
  WHERE company_id = v_company_id 
    AND grant_number = 'GRANT-2025-003';
  
  -- Update the plan allocation to match the new total
  UPDATE incentive_plans
  SET 
    total_shares_allocated = 1000000,
    shares_granted = 1000000,
    shares_available = 0,
    updated_at = now()
  WHERE id = v_plan_id;
  
  -- Update vesting schedules to reflect new amounts
  -- Sarah's vesting: 300,000 / 36 months = 8,333.33 per month
  UPDATE vesting_schedules 
  SET shares_to_vest = 8333.33
  WHERE grant_id IN (
    SELECT id FROM grants 
    WHERE company_id = v_company_id 
      AND grant_number = 'GRANT-2025-001'
  );
  
  -- Khalid's vesting: 350,000 / 36 months = 9,722.22 per month
  UPDATE vesting_schedules 
  SET shares_to_vest = 9722.22
  WHERE grant_id IN (
    SELECT id FROM grants 
    WHERE company_id = v_company_id 
      AND grant_number = 'GRANT-2025-002'
  );
  
  -- Fatima's vesting: 350,000 / 36 months = 9,722.22 per month
  UPDATE vesting_schedules 
  SET shares_to_vest = 9722.22
  WHERE grant_id IN (
    SELECT id FROM grants 
    WHERE company_id = v_company_id 
      AND grant_number = 'GRANT-2025-003'
  );
  
  RAISE NOTICE 'Successfully adjusted grant amounts:';
  RAISE NOTICE '  Sarah: 300,000 shares (was 3,000,000)';
  RAISE NOTICE '  Khalid: 350,000 shares (was 3,500,000)';
  RAISE NOTICE '  Fatima: 350,000 shares (was 3,500,000)';
  RAISE NOTICE '  Total: 1,000,000 shares (was 10,000,000)';
  RAISE NOTICE '  Plan allocation updated to match new total';
  
END $$;
