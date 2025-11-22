/*
  Check Existing Shareholders
  
  Problem: The previous migration incorrectly created new shareholder records for employees
  instead of using existing shareholder data in the cap table.
  
  Solution: Check what shareholders already exist and understand the current cap table structure.
*/

DO $$
DECLARE
  v_company_id uuid;
  rec RECORD;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Financial company not found';
  END IF;
  
  RAISE NOTICE '=== CHECKING EXISTING SHAREHOLDERS ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  
  -- Check all existing shareholders
  RAISE NOTICE 'All Existing Shareholders:';
  FOR rec IN 
    SELECT 
      id,
      name,
      shareholder_type,
      shares_owned,
      ownership_percentage,
      share_class,
      is_active,
      created_at
    FROM shareholders
    WHERE company_id = v_company_id
    ORDER BY shares_owned DESC
  LOOP
    RAISE NOTICE '  %: % shares (% ownership) - Type: %, Class: %, Active: %', 
      rec.name, rec.shares_owned, rec.ownership_percentage, rec.shareholder_type, rec.share_class, rec.is_active;
  END LOOP;
  
  -- Check if there are any employee-type shareholders
  RAISE NOTICE 'Employee Shareholders:';
  FOR rec IN 
    SELECT 
      name,
      shareholder_type,
      shares_owned,
      ownership_percentage
    FROM shareholders
    WHERE company_id = v_company_id 
      AND shareholder_type = 'employee'
      AND is_active = true
    ORDER BY shares_owned DESC
  LOOP
    RAISE NOTICE '  %: % shares (% ownership)', 
      rec.name, rec.shares_owned, rec.ownership_percentage;
  END LOOP;
  
  -- Check total shares in cap table
  SELECT COALESCE(SUM(shares_owned), 0)
  INTO rec
  FROM shareholders
  WHERE company_id = v_company_id AND is_active = true;
  
  RAISE NOTICE 'Total Shares in Cap Table: %', rec;
  
  -- Check grants data for comparison
  RAISE NOTICE 'Grants Data:';
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
  
  -- Check if there are any duplicate entries
  RAISE NOTICE 'Checking for duplicates:';
  FOR rec IN 
    SELECT 
      name,
      COUNT(*) as count
    FROM shareholders
    WHERE company_id = v_company_id
    GROUP BY name
    HAVING COUNT(*) > 1
  LOOP
    RAISE NOTICE '  DUPLICATE: % appears % times', rec.name, rec.count;
  END LOOP;
  
  RAISE NOTICE '=== EXISTING SHAREHOLDERS CHECK COMPLETE ===';
  
END $$;
