/*
  Verify Dashboard Calculations
  
  This migration verifies that the dashboard calculations are using the correct data sources
  and provides a clear summary of what should be displayed in each dashboard card.
*/

DO $$
DECLARE
  v_company_id uuid;
  rec RECORD;
  dashboard_equity_pool numeric;
  dashboard_option_pool numeric;
  cap_table_employee_shares numeric;
  grants_total numeric;
  plans_total_allocated numeric;
  plans_shares_granted numeric;
  plans_shares_available numeric;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Financial company not found';
  END IF;
  
  RAISE NOTICE '=== DASHBOARD CALCULATIONS VERIFICATION ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  
  -- 1. Dashboard Equity Pool Size (companies.total_reserved_shares)
  SELECT total_reserved_shares
  INTO dashboard_equity_pool
  FROM companies
  WHERE id = v_company_id;
  
  RAISE NOTICE 'Dashboard Equity Pool Size: %', dashboard_equity_pool;
  
  -- 2. Dashboard Option Pool Balance (companies.available_shares)
  SELECT available_shares
  INTO dashboard_option_pool
  FROM companies
  WHERE id = v_company_id;
  
  RAISE NOTICE 'Dashboard Option Pool Balance: %', dashboard_option_pool;
  
  -- 3. Cap Table Employee Shares (shareholders table, type='employee')
  SELECT COALESCE(SUM(shares_owned), 0)
  INTO cap_table_employee_shares
  FROM shareholders
  WHERE company_id = v_company_id 
    AND is_active = true 
    AND shareholder_type = 'employee';
  
  RAISE NOTICE 'Cap Table Employee Shares: %', cap_table_employee_shares;
  
  -- 4. Actual Grants Total
  SELECT COALESCE(SUM(total_shares), 0)
  INTO grants_total
  FROM grants
  WHERE company_id = v_company_id;
  
  RAISE NOTICE 'Actual Grants Total: %', grants_total;
  
  -- 5. Plans Data
  SELECT 
    COALESCE(SUM(total_shares_allocated), 0),
    COALESCE(SUM(shares_granted), 0),
    COALESCE(SUM(shares_available), 0)
  INTO plans_total_allocated, plans_shares_granted, plans_shares_available
  FROM incentive_plans
  WHERE company_id = v_company_id;
  
  RAISE NOTICE 'Plans Data:';
  RAISE NOTICE '  Total Allocated: %', plans_total_allocated;
  RAISE NOTICE '  Shares Granted: %', plans_shares_granted;
  RAISE NOTICE '  Shares Available: %', plans_shares_available;
  
  -- 6. Check for inconsistencies
  RAISE NOTICE '=== INCONSISTENCY CHECK ===';
  
  IF dashboard_equity_pool != cap_table_employee_shares THEN
    RAISE NOTICE 'INCONSISTENCY: Dashboard Equity Pool (%) != Cap Table Employee Shares (%)', 
      dashboard_equity_pool, cap_table_employee_shares;
  ELSE
    RAISE NOTICE 'CONSISTENT: Dashboard Equity Pool matches Cap Table Employee Shares';
  END IF;
  
  IF dashboard_option_pool != plans_shares_available THEN
    RAISE NOTICE 'INCONSISTENCY: Dashboard Option Pool (%) != Plans Available Shares (%)', 
      dashboard_option_pool, plans_shares_available;
  ELSE
    RAISE NOTICE 'CONSISTENT: Dashboard Option Pool matches Plans Available Shares';
  END IF;
  
  IF grants_total != plans_shares_granted THEN
    RAISE NOTICE 'INCONSISTENCY: Actual Grants (%) != Plans Granted Shares (%)', 
      grants_total, plans_shares_granted;
  ELSE
    RAISE NOTICE 'CONSISTENT: Actual Grants match Plans Granted Shares';
  END IF;
  
  -- 7. Show all employee shareholders
  RAISE NOTICE '=== EMPLOYEE SHAREHOLDERS IN CAP TABLE ===';
  FOR rec IN 
    SELECT 
      name,
      shareholder_type,
      shares_owned,
      ownership_percentage
    FROM shareholders
    WHERE company_id = v_company_id 
      AND is_active = true
      AND shareholder_type = 'employee'
    ORDER BY shares_owned DESC
  LOOP
    RAISE NOTICE '  %: % shares (% ownership)', 
      rec.name, rec.shares_owned, rec.ownership_percentage;
  END LOOP;
  
  -- 8. Show all grants
  RAISE NOTICE '=== GRANTS DATA ===';
  FOR rec IN 
    SELECT 
      g.grant_number,
      g.total_shares,
      g.status,
      CONCAT(e.first_name_en, ' ', e.last_name_en) as employee_name
    FROM grants g
    LEFT JOIN employees e ON g.employee_id = e.id
    WHERE g.company_id = v_company_id
    ORDER BY g.grant_number
  LOOP
    RAISE NOTICE '  %: % shares, status=%, employee=%', 
      rec.grant_number, rec.total_shares, rec.status, rec.employee_name;
  END LOOP;
  
  -- 9. Recommendations
  RAISE NOTICE '=== RECOMMENDATIONS ===';
  
  IF dashboard_equity_pool = 0 THEN
    RAISE NOTICE 'ISSUE: Dashboard Equity Pool Size is 0 - this should show total reserved shares';
  END IF;
  
  IF dashboard_option_pool = 0 THEN
    RAISE NOTICE 'ISSUE: Dashboard Option Pool Balance is 0 - this should show available shares';
  END IF;
  
  IF cap_table_employee_shares = 0 THEN
    RAISE NOTICE 'ISSUE: Cap Table shows 0 employee shares - employees should be in shareholders table';
  END IF;
  
  RAISE NOTICE '=== VERIFICATION COMPLETE ===';
  
END $$;
