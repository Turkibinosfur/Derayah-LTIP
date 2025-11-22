/*
  Restore Employee Shareholders
  
  Problem: I incorrectly removed employee shareholders from the cap table.
  In an ESOP system, employees who have received shares SHOULD be in the shareholders table.
  
  Solution: 
  1. Restore employee shareholders based on their grants
  2. Show how to properly manage shareholders
  3. Ensure data consistency between grants and shareholders
*/

DO $$
DECLARE
  v_company_id uuid;
  rec RECORD;
  employee_shares numeric;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Financial company not found';
  END IF;
  
  RAISE NOTICE '=== RESTORING EMPLOYEE SHAREHOLDERS ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  
  -- 1. Check current state
  RAISE NOTICE 'Current Shareholders:';
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
  
  -- 2. Check grants data
  RAISE NOTICE 'Employee Grants:';
  FOR rec IN 
    SELECT 
      CONCAT(e.first_name_en, ' ', e.last_name_en) as employee_name,
      SUM(g.total_shares) as total_shares,
      g.status
    FROM grants g
    JOIN employees e ON g.employee_id = e.id
    WHERE g.company_id = v_company_id
    GROUP BY e.first_name_en, e.last_name_en, g.status
    ORDER BY employee_name
  LOOP
    RAISE NOTICE '  %: % shares (status: %)', 
      rec.employee_name, rec.total_shares, rec.status;
  END LOOP;
  
  -- 3. Create/Update employee shareholders based on grants
  RAISE NOTICE 'Creating/Updating Employee Shareholders:';
  
  FOR rec IN 
    SELECT 
      e.id as employee_id,
      CONCAT(e.first_name_en, ' ', e.last_name_en) as employee_name,
      SUM(g.total_shares) as total_shares
    FROM grants g
    JOIN employees e ON g.employee_id = e.id
    WHERE g.company_id = v_company_id
    GROUP BY e.id, e.first_name_en, e.last_name_en
  LOOP
    -- Check if employee shareholder already exists
    IF EXISTS (
      SELECT 1 FROM shareholders 
      WHERE company_id = v_company_id 
        AND name = rec.employee_name
        AND shareholder_type = 'employee'
    ) THEN
      -- Update existing employee shareholder
      UPDATE shareholders
      SET 
        shares_owned = rec.total_shares,
        updated_at = now()
      WHERE company_id = v_company_id 
        AND name = rec.employee_name
        AND shareholder_type = 'employee';
      
      RAISE NOTICE '  Updated %: % shares', rec.employee_name, rec.total_shares;
    ELSE
      -- Create new employee shareholder
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
        rec.employee_name,
        'employee',
        rec.total_shares,
        0, -- Will be calculated later
        'Common',
        true,
        now(),
        now()
      );
      
      RAISE NOTICE '  Created %: % shares', rec.employee_name, rec.total_shares;
    END IF;
  END LOOP;
  
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
  
  -- 5. Show final state
  RAISE NOTICE 'Final Shareholders (including employees):';
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
  
  RAISE NOTICE '=== EMPLOYEE SHAREHOLDERS RESTORED ===';
  RAISE NOTICE 'Employees with shares are now properly shown in cap table';
  
END $$;
