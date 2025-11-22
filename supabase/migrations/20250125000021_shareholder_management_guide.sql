/*
  Shareholder Management Guide
  
  This migration shows how to properly manage shareholders in the cap table.
  It demonstrates how to delete shareholders and maintain data consistency.
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
  
  RAISE NOTICE '=== SHAREHOLDER MANAGEMENT GUIDE ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  
  -- 1. Show current shareholders
  RAISE NOTICE 'Current Shareholders:';
  FOR rec IN 
    SELECT 
      id,
      name,
      shareholder_type,
      shares_owned,
      ownership_percentage,
      is_active
    FROM shareholders
    WHERE company_id = v_company_id
    ORDER BY shares_owned DESC
  LOOP
    RAISE NOTICE '  ID: % | %: % shares (% ownership) - Type: %, Active: %', 
      rec.id, rec.name, rec.shares_owned, rec.ownership_percentage, rec.shareholder_type, rec.is_active;
  END LOOP;
  
  -- 2. Show how to delete a shareholder (example)
  RAISE NOTICE '=== HOW TO DELETE A SHAREHOLDER ===';
  RAISE NOTICE 'To delete a shareholder, you can:';
  RAISE NOTICE '1. Soft delete (recommended): Set is_active = false';
  RAISE NOTICE '2. Hard delete: DELETE FROM shareholders WHERE id = ?';
  
  -- Example of soft delete (safer)
  RAISE NOTICE 'Example - Soft delete a shareholder:';
  RAISE NOTICE 'UPDATE shareholders SET is_active = false WHERE id = ?';
  
  -- Example of hard delete (permanent)
  RAISE NOTICE 'Example - Hard delete a shareholder:';
  RAISE NOTICE 'DELETE FROM shareholders WHERE id = ?';
  
  -- 3. Show how to add a new shareholder
  RAISE NOTICE '=== HOW TO ADD A NEW SHAREHOLDER ===';
  RAISE NOTICE 'INSERT INTO shareholders (';
  RAISE NOTICE '  company_id,';
  RAISE NOTICE '  name,';
  RAISE NOTICE '  shareholder_type,';
  RAISE NOTICE '  shares_owned,';
  RAISE NOTICE '  ownership_percentage,';
  RAISE NOTICE '  share_class,';
  RAISE NOTICE '  is_active';
  RAISE NOTICE ') VALUES (';
  RAISE NOTICE '  ?, -- company_id';
  RAISE NOTICE '  ?, -- name';
  RAISE NOTICE '  ?, -- shareholder_type (founder, investor, employee, advisor, other)';
  RAISE NOTICE '  ?, -- shares_owned';
  RAISE NOTICE '  ?, -- ownership_percentage (will be calculated)';
  RAISE NOTICE '  ?, -- share_class (Common, Preferred, etc.)';
  RAISE NOTICE '  true -- is_active';
  RAISE NOTICE ');';
  
  -- 4. Show how to update shareholder shares
  RAISE NOTICE '=== HOW TO UPDATE SHAREHOLDER SHARES ===';
  RAISE NOTICE 'UPDATE shareholders SET';
  RAISE NOTICE '  shares_owned = ?,';
  RAISE NOTICE '  updated_at = now()';
  RAISE NOTICE 'WHERE id = ?;';
  
  -- 5. Show how to recalculate ownership percentages
  RAISE NOTICE '=== HOW TO RECALCULATE OWNERSHIP PERCENTAGES ===';
  RAISE NOTICE '-- First, get total shares';
  RAISE NOTICE 'SELECT SUM(shares_owned) FROM shareholders WHERE company_id = ? AND is_active = true;';
  RAISE NOTICE '';
  RAISE NOTICE '-- Then update all percentages';
  RAISE NOTICE 'UPDATE shareholders SET';
  RAISE NOTICE '  ownership_percentage = (shares_owned / total_shares) * 100,';
  RAISE NOTICE '  updated_at = now()';
  RAISE NOTICE 'WHERE company_id = ? AND is_active = true;';
  
  -- 6. Show current shareholder types
  RAISE NOTICE '=== CURRENT SHAREHOLDER TYPES ===';
  FOR rec IN 
    SELECT 
      shareholder_type,
      COUNT(*) as count,
      SUM(shares_owned) as total_shares
    FROM shareholders
    WHERE company_id = v_company_id AND is_active = true
    GROUP BY shareholder_type
    ORDER BY total_shares DESC
  LOOP
    RAISE NOTICE '  %: % shareholders, % total shares', 
      rec.shareholder_type, rec.count, rec.total_shares;
  END LOOP;
  
  RAISE NOTICE '=== SHAREHOLDER MANAGEMENT GUIDE COMPLETE ===';
  
END $$;
