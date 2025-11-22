/*
  Auto-create Company Reserved Portfolio
  
  Problem: Companies don't automatically get a reserved portfolio when created
  
  Solution: 
  1. Create a trigger function that automatically creates a company_reserved portfolio
     when a company is created
  2. Sync the portfolio shares with ESOP pool totals (or incentive plans if no ESOP pools)
  3. Ensure existing companies get portfolios created
  4. Sync portfolio when grants change (to track locked/available shares)
*/

-- 1. Function to create company reserved portfolio
CREATE OR REPLACE FUNCTION create_company_reserved_portfolio()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_portfolio_id uuid;
  v_total_shares numeric;
BEGIN
  -- Calculate total shares from ESOP pools for this company (priority)
  SELECT COALESCE(SUM(total_shares_allocated), 0)
  INTO v_total_shares
  FROM esop_pools
  WHERE company_id = NEW.id AND status = 'active';
  
  -- If no ESOP pools exist, use incentive plans total
  IF v_total_shares = 0 THEN
    SELECT COALESCE(SUM(total_shares_allocated), 0)
    INTO v_total_shares
    FROM incentive_plans
    WHERE company_id = NEW.id AND status = 'active';
  END IF;
  
  -- If still no shares, use company's total_reserved_shares as fallback
  IF v_total_shares = 0 THEN
    v_total_shares := COALESCE(NEW.total_reserved_shares, 0);
  END IF;
  
  -- Create company reserved portfolio
  INSERT INTO portfolios (
    id,
    portfolio_type,
    company_id,
    employee_id,  -- NULL for company portfolios
    total_shares,
    available_shares,
    locked_shares,
    portfolio_number,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    'company_reserved',
    NEW.id,
    NULL,
    v_total_shares,
    v_total_shares,  -- Initially all shares are available
    0,               -- Initially no shares are locked
    'PORT-COMPANY-RESERVED-' || NEW.id::text,
    now(),
    now()
  ) RETURNING id INTO v_portfolio_id;
  
  RAISE NOTICE 'Created company reserved portfolio % for company %', v_portfolio_id, NEW.company_name_en;
  
  RETURN NEW;
END;
$$;

-- 2. Trigger to auto-create portfolio when company is created
DROP TRIGGER IF EXISTS trigger_create_company_portfolio ON companies;
CREATE TRIGGER trigger_create_company_portfolio
  AFTER INSERT ON companies
  FOR EACH ROW
  EXECUTE FUNCTION create_company_reserved_portfolio();

-- 3. Function to sync portfolio with ESOP pools/incentive plans and grants
CREATE OR REPLACE FUNCTION sync_company_portfolio_with_pools()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_allocated numeric;
  v_total_granted numeric;
  v_portfolio_id uuid;
  v_company_id uuid;
BEGIN
  -- Get company_id from the trigger context
  IF TG_TABLE_NAME = 'esop_pools' THEN
    v_company_id := COALESCE(NEW.company_id, OLD.company_id);
  ELSIF TG_TABLE_NAME = 'incentive_plans' THEN
    v_company_id := COALESCE(NEW.company_id, OLD.company_id);
  ELSIF TG_TABLE_NAME = 'grants' THEN
    v_company_id := COALESCE(NEW.company_id, OLD.company_id);
  END IF;
  
  IF v_company_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;
  
  -- Get total allocated from ESOP pools (priority) or incentive plans
  SELECT COALESCE(SUM(total_shares_allocated), 0)
  INTO v_total_allocated
  FROM esop_pools
  WHERE company_id = v_company_id AND status = 'active';
  
  -- If no ESOP pools, use incentive plans
  IF v_total_allocated = 0 THEN
    SELECT COALESCE(SUM(total_shares_allocated), 0)
    INTO v_total_allocated
    FROM incentive_plans
    WHERE company_id = v_company_id AND status = 'active';
  END IF;
  
  -- Get total granted (locked in grants - pending, active, or completed grants count as locked until transferred)
  SELECT COALESCE(SUM(total_shares), 0)
  INTO v_total_granted
  FROM grants
  WHERE company_id = v_company_id
    AND status IN ('active', 'pending_signature');
  
  -- Find company reserved portfolio
  SELECT id INTO v_portfolio_id
  FROM portfolios
  WHERE company_id = v_company_id
    AND portfolio_type = 'company_reserved'
    AND employee_id IS NULL;
  
  -- Update portfolio if it exists
  IF v_portfolio_id IS NOT NULL THEN
    UPDATE portfolios
    SET 
      total_shares = v_total_allocated,
      locked_shares = v_total_granted,
      available_shares = GREATEST(0, v_total_allocated - v_total_granted),
      updated_at = now()
    WHERE id = v_portfolio_id;
    
    RAISE NOTICE 'Synced company portfolio %: Total=%, Granted (Locked)=%, Available=%', 
      v_portfolio_id, v_total_allocated, v_total_granted, GREATEST(0, v_total_allocated - v_total_granted);
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- 4. Trigger to sync portfolio when ESOP pools change
DROP TRIGGER IF EXISTS trigger_sync_portfolio_on_esop_pool_change ON esop_pools;
CREATE TRIGGER trigger_sync_portfolio_on_esop_pool_change
  AFTER INSERT OR UPDATE OR DELETE ON esop_pools
  FOR EACH ROW
  EXECUTE FUNCTION sync_company_portfolio_with_pools();

-- 5. Trigger to sync portfolio when incentive plans change
DROP TRIGGER IF EXISTS trigger_sync_portfolio_on_plan_change ON incentive_plans;
CREATE TRIGGER trigger_sync_portfolio_on_plan_change
  AFTER INSERT OR UPDATE OR DELETE ON incentive_plans
  FOR EACH ROW
  EXECUTE FUNCTION sync_company_portfolio_with_pools();

-- 6. Trigger to sync portfolio when grants change
DROP TRIGGER IF EXISTS trigger_sync_portfolio_on_grant_change ON grants;
CREATE TRIGGER trigger_sync_portfolio_on_grant_change
  AFTER INSERT OR UPDATE OR DELETE ON grants
  FOR EACH ROW
  EXECUTE FUNCTION sync_company_portfolio_with_pools();

-- 7. Create portfolios for existing companies that don't have one
DO $$
DECLARE
  company_rec RECORD;
  v_portfolio_id uuid;
  v_total_shares numeric;
  v_locked_shares numeric;
BEGIN
  FOR company_rec IN 
    SELECT id, company_name_en, total_reserved_shares
    FROM companies
    WHERE NOT EXISTS (
      SELECT 1 FROM portfolios 
      WHERE portfolios.company_id = companies.id 
        AND portfolios.portfolio_type = 'company_reserved'
        AND portfolios.employee_id IS NULL
    )
  LOOP
    -- Calculate total from ESOP pools (priority)
    SELECT COALESCE(SUM(total_shares_allocated), 0)
    INTO v_total_shares
    FROM esop_pools
    WHERE company_id = company_rec.id AND status = 'active';
    
    -- If no ESOP pools, use incentive plans
    IF v_total_shares = 0 THEN
      SELECT COALESCE(SUM(total_shares_allocated), 0)
      INTO v_total_shares
      FROM incentive_plans
      WHERE company_id = company_rec.id AND status = 'active';
    END IF;
    
    -- Fallback to company total_reserved_shares
    IF v_total_shares = 0 THEN
      v_total_shares := COALESCE(company_rec.total_reserved_shares, 0);
    END IF;
    
    -- Calculate locked shares (granted but not yet transferred)
    SELECT COALESCE(SUM(total_shares), 0)
    INTO v_locked_shares
    FROM grants
    WHERE company_id = company_rec.id
      AND status IN ('active', 'pending_signature');
    
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
    );
    
    RAISE NOTICE 'Created company reserved portfolio for existing company: % (Total: %, Locked: %, Available: %)', 
      company_rec.company_name_en, v_total_shares, v_locked_shares, GREATEST(0, v_total_shares - v_locked_shares);
  END LOOP;
END;
$$;



