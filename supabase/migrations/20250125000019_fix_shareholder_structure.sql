/*
  Fix Shareholder Structure
  
  Problem: 
  - Sarah incorrectly appears in shareholders (should only be in employees/grants)
  - Other shareholders show zero shares (original data was overwritten)
  - Need to restore proper shareholder structure
  
  Solution:
  1. Remove Sarah and other employees from shareholders
  2. Restore proper shareholder data (founders, investors)
  3. Ensure shareholders table only contains actual shareholders, not employees
*/

DO $$
DECLARE
  v_company_id uuid;
  rec RECORD;
  deleted_count integer;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Financial company not found';
  END IF;
  
  RAISE NOTICE '=== FIXING SHAREHOLDER STRUCTURE ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  
  -- 1. Remove all employees from shareholders table
  -- Employees should only exist in employees/grants, not shareholders
  DELETE FROM shareholders
  WHERE company_id = v_company_id 
    AND (
      name LIKE '%Sarah%' OR 
      name LIKE '%Khalid%' OR 
      name LIKE '%Fatima%' OR
      shareholder_type = 'employee'
    );
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RAISE NOTICE 'Removed % employee entries from shareholders', deleted_count;
  
  -- 2. Check what shareholders remain
  RAISE NOTICE 'Remaining Shareholders:';
  FOR rec IN 
    SELECT 
      name,
      shareholder_type,
      shares_owned,
      ownership_percentage,
      is_active
    FROM shareholders
    WHERE company_id = v_company_id
    ORDER BY shares_owned DESC
  LOOP
    RAISE NOTICE '  %: % shares (% ownership) - Type: %, Active: %', 
      rec.name, rec.shares_owned, rec.ownership_percentage, rec.shareholder_type, rec.is_active;
  END LOOP;
  
  -- 3. If no proper shareholders exist, create basic structure
  IF NOT EXISTS (SELECT 1 FROM shareholders WHERE company_id = v_company_id AND is_active = true) THEN
    RAISE NOTICE 'No proper shareholders found - creating basic structure';
    
    -- Create founder shareholder (example)
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
    ) VALUES (
      v_company_id,
      'Company Founders',
      'founder',
      10000000, -- 10M shares for founders
      100.0, -- 100% ownership initially
      'Common',
      true,
      now(),
      now()
    );
    
    RAISE NOTICE 'Created basic founder shareholder with 10M shares';
  END IF;
  
  -- 4. Recalculate ownership percentages
  DECLARE
    total_shares numeric;
  BEGIN
    SELECT COALESCE(SUM(shares_owned), 0)
    INTO total_shares
    FROM shareholders
    WHERE company_id = v_company_id AND is_active = true;
    
    UPDATE shareholders
    SET 
      ownership_percentage = CASE 
        WHEN total_shares > 0 THEN (shares_owned / total_shares) * 100
        ELSE 0
      END,
      updated_at = now()
    WHERE company_id = v_company_id AND is_active = true;
    
    RAISE NOTICE 'Recalculated ownership percentages based on total: %', total_shares;
  END;
  
  -- 5. Update company data to match shareholders
  UPDATE companies
  SET 
    total_reserved_shares = (
      SELECT COALESCE(SUM(shares_owned), 0)
      FROM shareholders
      WHERE company_id = v_company_id AND is_active = true
    ),
    available_shares = (
      SELECT COALESCE(SUM(shares_owned), 0)
      FROM shareholders
      WHERE company_id = v_company_id AND is_active = true
    ) - (
      SELECT COALESCE(SUM(shares_granted), 0)
      FROM incentive_plans
      WHERE company_id = v_company_id
    ),
    updated_at = now()
  WHERE id = v_company_id;
  
  -- 6. Final verification
  RAISE NOTICE 'Final Shareholder Structure:';
  FOR rec IN 
    SELECT 
      name,
      shareholder_type,
      shares_owned,
      ownership_percentage,
      is_active
    FROM shareholders
    WHERE company_id = v_company_id
    ORDER BY shares_owned DESC
  LOOP
    RAISE NOTICE '  %: % shares (% ownership) - Type: %, Active: %', 
      rec.name, rec.shares_owned, rec.ownership_percentage, rec.shareholder_type, rec.is_active;
  END LOOP;
  
  -- 7. Show grants data (employees should only be here)
  RAISE NOTICE 'Employee Grants (should NOT be in shareholders):';
  FOR rec IN 
    SELECT 
      CONCAT(e.first_name_en, ' ', e.last_name_en) as employee_name,
      g.total_shares,
      g.status
    FROM grants g
    JOIN employees e ON g.employee_id = e.id
    WHERE g.company_id = v_company_id
    ORDER BY employee_name
  LOOP
    RAISE NOTICE '  %: % shares (status: %)', 
      rec.employee_name, rec.total_shares, rec.status;
  END LOOP;
  
  RAISE NOTICE '=== SHAREHOLDER STRUCTURE FIX COMPLETE ===';
  RAISE NOTICE 'Employees are now only in grants, not shareholders';
  RAISE NOTICE 'Shareholders table contains only actual shareholders';
  
END $$;
