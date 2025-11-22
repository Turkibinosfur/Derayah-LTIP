/*
  Fix Dashboard and Cap Table Consistency
  
  Problem: 
  - Dashboard Equity Pool Size uses companies.total_reserved_shares
  - Dashboard Option Pool Balance uses companies.available_shares
  - Cap Table Employee Shares uses shareholders table
  - These are different data sources that don't match
  
  Solution:
  1. Check current values in all sources
  2. Synchronize the data sources
  3. Ensure consistency between dashboard and cap table
  4. Fix any missing or incorrect data
*/

DO $$
DECLARE
  v_company_id uuid;
  rec RECORD;
  total_employee_shares numeric;
  total_shareholders_shares numeric;
  current_reserved_shares numeric;
  current_available_shares numeric;
  grants_total_shares numeric;
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
  
  RAISE NOTICE '=== FIXING DASHBOARD-CAP TABLE CONSISTENCY ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  
  -- 1. Check current company data
  SELECT total_reserved_shares, available_shares
  INTO current_reserved_shares, current_available_shares
  FROM companies
  WHERE id = v_company_id;
  
  RAISE NOTICE 'Current Company Data:';
  RAISE NOTICE '  Total Reserved Shares: %', current_reserved_shares;
  RAISE NOTICE '  Available Shares: %', current_available_shares;
  
  -- 2. Check grants data
  SELECT COALESCE(SUM(total_shares), 0)
  INTO grants_total_shares
  FROM grants
  WHERE company_id = v_company_id;
  
  RAISE NOTICE 'Grants Total Shares: %', grants_total_shares;
  
  -- 3. Check plans data
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
  
  -- 4. Check shareholders data
  SELECT COALESCE(SUM(shares_owned), 0)
  INTO total_shareholders_shares
  FROM shareholders
  WHERE company_id = v_company_id AND is_active = true;
  
  RAISE NOTICE 'Shareholders Total Shares: %', total_shareholders_shares;
  
  -- 5. Check if there are employee shareholders
  RAISE NOTICE 'Employee Shareholders:';
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
    RAISE NOTICE '  % (%): % shares (% ownership)', 
      rec.name, rec.shareholder_type, rec.shares_owned, rec.ownership_percentage;
  END LOOP;
  
  -- 6. Calculate total employee shares from grants
  SELECT COALESCE(SUM(total_shares), 0)
  INTO total_employee_shares
  FROM grants g
  JOIN employees e ON g.employee_id = e.id
  WHERE g.company_id = v_company_id;
  
  RAISE NOTICE 'Total Employee Shares from Grants: %', total_employee_shares;
  
  -- 7. Fix company data to match actual grants
  UPDATE companies
  SET 
    total_reserved_shares = GREATEST(plans_total_allocated, grants_total_shares + 1000000),
    available_shares = GREATEST(plans_total_allocated, grants_total_shares + 1000000) - grants_total_shares,
    updated_at = now()
  WHERE id = v_company_id;
  
  RAISE NOTICE 'Updated Company Data:';
  RAISE NOTICE '  Total Reserved Shares: %', GREATEST(plans_total_allocated, grants_total_shares + 1000000);
  RAISE NOTICE '  Available Shares: %', GREATEST(plans_total_allocated, grants_total_shares + 1000000) - grants_total_shares;
  
  -- 8. Ensure employee shareholders exist in shareholders table
  -- This will sync the cap table with the actual grants
  INSERT INTO shareholders (
    company_id,
    name,
    shareholder_type,
    shares_owned,
    ownership_percentage,
    share_class,
    is_active,
    created_at,
    updated_at
  )
  SELECT 
    v_company_id,
    CONCAT(e.first_name_en, ' ', e.last_name_en) as name,
    'employee' as shareholder_type,
    SUM(g.total_shares) as shares_owned,
    0 as ownership_percentage, -- Will be calculated later
    'Common' as share_class,
    true as is_active,
    now() as created_at,
    now() as updated_at
  FROM employees e
  JOIN grants g ON e.id = g.employee_id
  WHERE g.company_id = v_company_id
    AND NOT EXISTS (
      SELECT 1 FROM shareholders s 
      WHERE s.company_id = v_company_id 
        AND s.shareholder_type = 'employee'
        AND s.name = CONCAT(e.first_name_en, ' ', e.last_name_en)
    )
  GROUP BY e.id, e.first_name_en, e.last_name_en;
  
  -- 9. Update existing employee shareholders with correct share counts
  UPDATE shareholders
  SET 
    shares_owned = (
      SELECT COALESCE(SUM(g.total_shares), 0)
      FROM grants g
      JOIN employees e ON g.employee_id = e.id
      WHERE g.company_id = v_company_id
        AND CONCAT(e.first_name_en, ' ', e.last_name_en) = shareholders.name
    ),
    updated_at = now()
  WHERE company_id = v_company_id 
    AND shareholder_type = 'employee';
  
  -- 10. Recalculate ownership percentages
  SELECT COALESCE(SUM(shares_owned), 0)
  INTO total_shareholders_shares
  FROM shareholders
  WHERE company_id = v_company_id AND is_active = true;
  
  UPDATE shareholders
  SET 
    ownership_percentage = CASE 
      WHEN total_shareholders_shares > 0 THEN (shares_owned / total_shareholders_shares) * 100
      ELSE 0
    END,
    updated_at = now()
  WHERE company_id = v_company_id AND is_active = true;
  
  -- 11. Final verification
  RAISE NOTICE 'Final Verification:';
  
  -- Company data
  SELECT total_reserved_shares, available_shares
  INTO current_reserved_shares, current_available_shares
  FROM companies
  WHERE id = v_company_id;
  
  RAISE NOTICE '  Company Total Reserved: %', current_reserved_shares;
  RAISE NOTICE '  Company Available: %', current_available_shares;
  
  -- Shareholders data
  SELECT COALESCE(SUM(shares_owned), 0)
  INTO total_shareholders_shares
  FROM shareholders
  WHERE company_id = v_company_id AND is_active = true;
  
  RAISE NOTICE '  Shareholders Total: %', total_shareholders_shares;
  
  -- Employee shareholders
  RAISE NOTICE '  Employee Shareholders:';
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
    RAISE NOTICE '    %: % shares (% ownership)', 
      rec.name, rec.shares_owned, rec.ownership_percentage;
  END LOOP;
  
  RAISE NOTICE '=== DASHBOARD-CAP TABLE CONSISTENCY FIX COMPLETE ===';
  
END $$;
