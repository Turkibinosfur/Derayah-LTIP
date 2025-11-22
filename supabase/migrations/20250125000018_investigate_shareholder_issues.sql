/*
  Investigate Shareholder Issues
  
  Problem: 
  - Sarah still appears in shareholders (shouldn't be there)
  - Other shareholders show zero shares
  - Need to understand where the original shares went
  
  Solution: 
  1. Check current state of shareholders table
  2. Check if there were original shareholders that got overwritten
  3. Identify what data should be restored
  4. Provide clear picture of what happened
*/

DO $$
DECLARE
  v_company_id uuid;
  rec RECORD;
  total_shares_in_shareholders numeric;
  total_shares_in_grants numeric;
  total_shares_in_plans numeric;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Financial company not found';
  END IF;
  
  RAISE NOTICE '=== INVESTIGATING SHAREHOLDER ISSUES ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  
  -- 1. Check current shareholders table
  RAISE NOTICE 'Current Shareholders:';
  FOR rec IN 
    SELECT 
      id,
      name,
      shareholder_type,
      shares_owned,
      ownership_percentage,
      share_class,
      is_active,
      created_at,
      updated_at
    FROM shareholders
    WHERE company_id = v_company_id
    ORDER BY created_at
  LOOP
    RAISE NOTICE '  %: % shares (% ownership) - Type: %, Class: %, Active: %, Created: %', 
      rec.name, rec.shares_owned, rec.ownership_percentage, rec.shareholder_type, rec.share_class, rec.is_active, rec.created_at;
  END LOOP;
  
  -- 2. Check total shares in shareholders table
  SELECT COALESCE(SUM(shares_owned), 0)
  INTO total_shares_in_shareholders
  FROM shareholders
  WHERE company_id = v_company_id AND is_active = true;
  
  RAISE NOTICE 'Total Shares in Shareholders Table: %', total_shares_in_shareholders;
  
  -- 3. Check grants data
  SELECT COALESCE(SUM(total_shares), 0)
  INTO total_shares_in_grants
  FROM grants
  WHERE company_id = v_company_id;
  
  RAISE NOTICE 'Total Shares in Grants: %', total_shares_in_grants;
  
  -- 4. Check incentive plans data
  SELECT COALESCE(SUM(total_shares_allocated), 0)
  INTO total_shares_in_plans
  FROM incentive_plans
  WHERE company_id = v_company_id;
  
  RAISE NOTICE 'Total Shares Allocated in Plans: %', total_shares_in_plans;
  
  -- 5. Check company data
  RAISE NOTICE 'Company Data:';
  FOR rec IN 
    SELECT 
      company_name_en,
      total_reserved_shares,
      available_shares
    FROM companies
    WHERE id = v_company_id
  LOOP
    RAISE NOTICE '  Company: %', rec.company_name_en;
    RAISE NOTICE '  Total Reserved: %', rec.total_reserved_shares;
    RAISE NOTICE '  Available: %', rec.available_shares;
  END LOOP;
  
  -- 6. Check if there are any audit logs or history
  RAISE NOTICE 'Recent Shareholder Changes:';
  FOR rec IN 
    SELECT 
      name,
      shares_owned,
      updated_at
    FROM shareholders
    WHERE company_id = v_company_id
      AND updated_at > '2025-01-24'
    ORDER BY updated_at DESC
  LOOP
    RAISE NOTICE '  %: % shares, updated: %', rec.name, rec.shares_owned, rec.updated_at;
  END LOOP;
  
  -- 7. Check if Sarah should be removed
  RAISE NOTICE 'Checking if Sarah should be removed:';
  IF EXISTS (
    SELECT 1 FROM shareholders 
    WHERE company_id = v_company_id 
      AND name LIKE '%Sarah%'
  ) THEN
    RAISE NOTICE '  WARNING: Sarah found in shareholders - this should be removed';
    RAISE NOTICE '  Sarah should only exist in employees/grants, not shareholders';
  END IF;
  
  -- 8. Check what the original shareholders should be
  RAISE NOTICE 'Expected Shareholder Structure:';
  RAISE NOTICE '  - Founders (should have significant shares)';
  RAISE NOTICE '  - Investors (should have shares from funding rounds)';
  RAISE NOTICE '  - NOT employees (employees get grants, not direct shares)';
  
  -- 9. Check if there are any funding rounds that should create shareholders
  RAISE NOTICE 'Funding Rounds:';
  FOR rec IN 
    SELECT 
      round_name,
      amount_raised,
      shares_issued,
      closing_date
    FROM funding_rounds
    WHERE company_id = v_company_id
    ORDER BY closing_date
  LOOP
    RAISE NOTICE '  %: % raised, % shares issued on %', 
      rec.round_name, rec.amount_raised, rec.shares_issued, rec.closing_date;
  END LOOP;
  
  -- 10. Summary of issues
  RAISE NOTICE '=== ISSUE SUMMARY ===';
  
  IF total_shares_in_shareholders = 0 THEN
    RAISE NOTICE 'ISSUE: No shares in shareholders table - this is wrong';
    RAISE NOTICE 'SOLUTION: Need to restore original shareholder data';
  END IF;
  
  IF EXISTS (SELECT 1 FROM shareholders WHERE company_id = v_company_id AND name LIKE '%Sarah%') THEN
    RAISE NOTICE 'ISSUE: Sarah in shareholders - she should only be in employees/grants';
    RAISE NOTICE 'SOLUTION: Remove Sarah from shareholders table';
  END IF;
  
  IF total_shares_in_grants > total_shares_in_plans THEN
    RAISE NOTICE 'ISSUE: More shares granted than allocated in plans';
    RAISE NOTICE 'SOLUTION: Check plan allocations vs actual grants';
  END IF;
  
  RAISE NOTICE '=== INVESTIGATION COMPLETE ===';
  
END $$;
