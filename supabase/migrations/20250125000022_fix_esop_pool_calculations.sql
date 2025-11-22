/*
  Fix ESOP Pool Calculations
  
  Problem: 
  1. Portfolio page shows ESOP Pool Allocated from incentive plans instead of employee shareholders
  2. Dashboard shows Equity Pool Size from companies.total_reserved_shares instead of employee shareholders
  3. Dashboard shows Option Pool Balance from companies.available_shares instead of calculated value
  
  Solution:
  1. Calculate ESOP Pool Allocated from shareholders with type 'employee'
  2. Calculate Equity Pool Size from total employee shares
  3. Calculate Option Pool Balance as (total pool - granted shares)
*/

DO $$
DECLARE
  v_company_id uuid;
  employee_shares_total numeric;
  total_shares_authorized numeric;
  option_pool_balance numeric;
  rec RECORD;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Financial company not found';
  END IF;
  
  RAISE NOTICE '=== FIXING ESOP POOL CALCULATIONS ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  
  -- 1. Calculate total shares owned by employees
  SELECT COALESCE(SUM(shares_owned), 0)
  INTO employee_shares_total
  FROM shareholders
  WHERE company_id = v_company_id 
    AND shareholder_type = 'employee'
    AND is_active = true;
  
  RAISE NOTICE 'Employee Shares Total: %', employee_shares_total;
  
  -- 2. Get total shares authorized (from companies table or calculate from all shareholders)
  SELECT COALESCE(SUM(shares_owned), 0)
  INTO total_shares_authorized
  FROM shareholders
  WHERE company_id = v_company_id 
    AND is_active = true;
  
  RAISE NOTICE 'Total Shares Authorized: %', total_shares_authorized;
  
  -- 3. Calculate option pool balance (total - employee shares)
  option_pool_balance := total_shares_authorized - employee_shares_total;
  
  RAISE NOTICE 'Option Pool Balance: %', option_pool_balance;
  
  -- 4. Update companies table with correct values
  UPDATE companies
  SET 
    total_reserved_shares = employee_shares_total,
    available_shares = option_pool_balance,
    updated_at = now()
  WHERE id = v_company_id;
  
  RAISE NOTICE 'Updated companies table with:';
  RAISE NOTICE '  total_reserved_shares: %', employee_shares_total;
  RAISE NOTICE '  available_shares: %', option_pool_balance;
  
  -- 5. Show current state
  RAISE NOTICE '=== CURRENT SHAREHOLDER BREAKDOWN ===';
  
  FOR rec IN 
    SELECT 
      shareholder_type,
      COUNT(*) as count,
      SUM(shares_owned) as total_shares,
      ROUND((SUM(shares_owned) / total_shares_authorized) * 100, 2) as percentage
    FROM shareholders
    WHERE company_id = v_company_id AND is_active = true
    GROUP BY shareholder_type
    ORDER BY total_shares DESC
  LOOP
    RAISE NOTICE '  %: % shareholders, % shares (%)', 
      rec.shareholder_type, rec.count, rec.total_shares, rec.percentage;
  END LOOP;
  
  -- 6. Show incentive plans vs shareholders comparison
  RAISE NOTICE '=== INCENTIVE PLANS VS SHAREHOLDERS COMPARISON ===';
  
  DECLARE
    plan_total numeric;
    plan_granted numeric;
  BEGIN
    SELECT 
      COALESCE(SUM(total_shares_allocated), 0),
      COALESCE(SUM(shares_granted), 0)
    INTO plan_total, plan_granted
    FROM incentive_plans
    WHERE company_id = v_company_id;
    
    RAISE NOTICE 'Incentive Plans Total Allocated: %', plan_total;
    RAISE NOTICE 'Incentive Plans Shares Granted: %', plan_granted;
    RAISE NOTICE 'Employee Shareholders Total: %', employee_shares_total;
    RAISE NOTICE 'Difference (Plans - Employees): %', plan_total - employee_shares_total;
  END;
  
  RAISE NOTICE '=== ESOP POOL CALCULATIONS FIXED ===';
  RAISE NOTICE 'Portfolio page should now show: % (employee shareholders)', employee_shares_total;
  RAISE NOTICE 'Dashboard Equity Pool Size should show: % (employee shareholders)', employee_shares_total;
  RAISE NOTICE 'Dashboard Option Pool Balance should show: % (total - employee)', option_pool_balance;
  
END $$;
