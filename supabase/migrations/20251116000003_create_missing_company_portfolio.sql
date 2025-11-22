/*
  Create Missing Company Reserved Portfolio
  
  Problem: The migration 20250128000007_auto_create_company_portfolio.sql references
  the old 'esop_pools' table, but it was renamed to 'ltip_pools' in a later migration.
  This causes the DO block that creates portfolios for existing companies to fail silently
  or create portfolios with 0 shares because the table doesn't exist.
  
  Solution: 
  - Create company reserved portfolios for companies that don't have one
  - Use 'ltip_pools' instead of 'esop_pools'
  - Properly calculate total shares from LTIP pools or incentive plans
  - Calculate locked shares from existing grants
*/

-- Create company reserved portfolio for companies that don't have one
DO $$
DECLARE
  company_rec RECORD;
  v_portfolio_id uuid;
  v_total_shares numeric;
  v_locked_shares numeric;
  portfolio_exists boolean;
BEGIN
  FOR company_rec IN 
    SELECT id, company_name_en, total_reserved_shares
    FROM companies
  LOOP
    -- Check if portfolio already exists
    SELECT EXISTS (
      SELECT 1 FROM portfolios 
      WHERE company_id = company_rec.id 
        AND portfolio_type = 'company_reserved'
        AND employee_id IS NULL
    ) INTO portfolio_exists;
    
    -- Skip if portfolio already exists
    IF portfolio_exists THEN
      RAISE NOTICE 'Portfolio already exists for company: % (ID: %)', company_rec.company_name_en, company_rec.id;
      CONTINUE;
    END IF;
    
    -- Calculate total from LTIP pools (priority) - using correct table name
    SELECT COALESCE(SUM(total_shares_allocated), 0)
    INTO v_total_shares
    FROM ltip_pools
    WHERE company_id = company_rec.id AND status = 'active';
    
    RAISE NOTICE 'Company: %, LTIP pools total: %', company_rec.company_name_en, v_total_shares;
    
    -- If no LTIP pools, use incentive plans
    IF v_total_shares = 0 THEN
      SELECT COALESCE(SUM(total_shares_allocated), 0)
      INTO v_total_shares
      FROM incentive_plans
      WHERE company_id = company_rec.id AND status = 'active';
      
      RAISE NOTICE 'Company: %, Incentive plans total: %', company_rec.company_name_en, v_total_shares;
    END IF;
    
    -- Fallback to company total_reserved_shares (with a reasonable default if null)
    IF v_total_shares = 0 THEN
      v_total_shares := COALESCE(company_rec.total_reserved_shares, 500000);
      RAISE NOTICE 'Company: %, Using company total_reserved_shares as fallback: %', company_rec.company_name_en, v_total_shares;
    END IF;
    
    -- Calculate locked shares (granted but not yet transferred)
    SELECT COALESCE(SUM(total_shares), 0)
    INTO v_locked_shares
    FROM grants
    WHERE company_id = company_rec.id
      AND status IN ('active', 'pending_signature');
    
    RAISE NOTICE 'Company: %, Locked shares (from grants): %', company_rec.company_name_en, v_locked_shares;
    
    -- Create portfolio
    INSERT INTO portfolios (
      id,
      portfolio_type,
      company_id,
      employee_id,
      total_shares,
      available_shares,
      locked_shares,
      portfolio_number,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      'company_reserved',
      company_rec.id,
      NULL,
      v_total_shares,
      GREATEST(0, v_total_shares - v_locked_shares),
      v_locked_shares,
      'PORT-COMPANY-RESERVED-' || company_rec.id::text,
      now(),
      now()
    ) RETURNING id INTO v_portfolio_id;
    
    RAISE NOTICE '✅ Created company reserved portfolio for company: % (ID: %, Portfolio ID: %)', 
      company_rec.company_name_en, company_rec.id, v_portfolio_id;
    RAISE NOTICE '   Total: %, Locked: %, Available: %', 
      v_total_shares, v_locked_shares, GREATEST(0, v_total_shares - v_locked_shares);
  END LOOP;
  
  RAISE NOTICE '=== Portfolio creation complete ===';
END;
$$;

-- Verify portfolios were created
SELECT 
  '=== VERIFICATION: Company Reserved Portfolios ===' as info;

SELECT 
  c.company_name_en,
  p.id as portfolio_id,
  p.portfolio_number,
  p.total_shares,
  p.locked_shares,
  p.available_shares,
  p.created_at
FROM companies c
LEFT JOIN portfolios p ON p.company_id = c.id 
  AND p.portfolio_type = 'company_reserved' 
  AND p.employee_id IS NULL
ORDER BY c.company_name_en;

