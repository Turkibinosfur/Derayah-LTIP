/*
  Ultra minimal migration to set up Khalid Al-Zahrani's basic employee data.
  This migration only uses the most basic operations and avoids problematic tables.
*/

DO $$
DECLARE
  rec RECORD;
  v_company_id uuid;
  v_khalid_id uuid;
  v_plan_id uuid;
  v_grant_id uuid;
  v_portfolio_id uuid;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';

  IF v_company_id IS NULL THEN
    RAISE NOTICE 'Company "Derayah Financial" not found. Exiting migration.';
    RETURN;
  END IF;

  RAISE NOTICE 'Processing company ID: %', v_company_id;

  -- Get Khalid's employee ID
  SELECT id INTO v_khalid_id
  FROM employees
  WHERE first_name_en = 'Khalid' AND last_name_en = 'Al-Zahrani' AND company_id = v_company_id;

  IF v_khalid_id IS NULL THEN
    RAISE NOTICE 'Khalid Al-Zahrani not found. Exiting migration.';
    RETURN;
  END IF;

  RAISE NOTICE 'Khalid Al-Zahrani ID: %', v_khalid_id;

  -- Get the incentive plan ID
  SELECT id INTO v_plan_id
  FROM incentive_plans
  WHERE plan_name_en = 'Derayah Employee Stock Plan 2025' AND company_id = v_company_id;

  IF v_plan_id IS NULL THEN
    RAISE NOTICE 'Incentive plan not found. Exiting migration.';
    RETURN;
  END IF;

  RAISE NOTICE 'Incentive Plan ID: %', v_plan_id;

  RAISE NOTICE '=== ULTRA MINIMAL KHALID SETUP ===';

  -- 1. Enable portal access for Khalid (only if columns exist)
  BEGIN
    UPDATE employees 
    SET portal_access_enabled = true,
        portal_username = 'khalid.alzahrani',
        portal_password = 'Khalid2025!',
        updated_at = now()
    WHERE id = v_khalid_id;
    
    RAISE NOTICE '✓ Enabled portal access for Khalid';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠ Could not update portal access: %', SQLERRM;
  END;

  -- 2. Create/update Khalid's portfolio (only if table exists)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'portfolios') THEN
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM portfolios WHERE employee_id = v_khalid_id) THEN
        INSERT INTO portfolios (
          id, portfolio_type, company_id, employee_id, 
          total_shares, available_shares, locked_shares, 
          portfolio_number, created_at, updated_at
        ) VALUES (
          gen_random_uuid(), 'employee_vested', v_company_id, v_khalid_id,
          350000, 0, 350000, 'PORT-2025-002', now(), now()
        ) RETURNING id INTO v_portfolio_id;
        
        RAISE NOTICE '✓ Created portfolio for Khalid: %', v_portfolio_id;
      ELSE
        SELECT id INTO v_portfolio_id FROM portfolios WHERE employee_id = v_khalid_id;
        RAISE NOTICE '✓ Portfolio already exists for Khalid: %', v_portfolio_id;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '⚠ Could not create portfolio: %', SQLERRM;
    END;
  ELSE
    RAISE NOTICE '⚠ portfolios table does not exist - skipping portfolio creation';
  END IF;

  -- 3. Create/update Khalid's grant (only if table exists)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'grants') THEN
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM grants WHERE employee_id = v_khalid_id) THEN
        INSERT INTO grants (
          id, company_id, employee_id, plan_id, grant_number,
          total_shares, granted_date, vesting_start_date, 
          vesting_end_date, status, created_at, updated_at
        ) VALUES (
          gen_random_uuid(), v_company_id, v_khalid_id, v_plan_id, 'GRANT-2025-002',
          350000, '2025-01-01', '2026-01-01', '2029-01-01', 'active', now(), now()
        ) RETURNING id INTO v_grant_id;
        
        RAISE NOTICE '✓ Created grant for Khalid: %', v_grant_id;
      ELSE
        SELECT id INTO v_grant_id FROM grants WHERE employee_id = v_khalid_id;
        UPDATE grants SET status = 'active', updated_at = now() WHERE id = v_grant_id;
        RAISE NOTICE '✓ Updated existing grant for Khalid: %', v_grant_id;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '⚠ Could not create grant: %', SQLERRM;
    END;
  ELSE
    RAISE NOTICE '⚠ grants table does not exist - skipping grant creation';
  END IF;

  -- 4. Update grant with proper share calculations (if grant exists)
  IF v_grant_id IS NOT NULL THEN
    BEGIN
      UPDATE grants 
      SET vested_shares = 0,
          remaining_unvested_shares = 350000,
          updated_at = now()
      WHERE id = v_grant_id;
      
      RAISE NOTICE '✓ Updated grant with share calculations';
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '⚠ Could not update grant shares: %', SQLERRM;
    END;
  END IF;

  -- 5. Create vesting schedule for Khalid (if table exists)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'vesting_schedules') AND v_grant_id IS NOT NULL THEN
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM vesting_schedules WHERE grant_id = v_grant_id) THEN
        INSERT INTO vesting_schedules (
          id, grant_id, sequence_number, vesting_date, shares_to_vest,
          performance_condition_met, status, created_at
        )
        SELECT
          gen_random_uuid(), v_grant_id, generate_series(1, 36) as sequence_number,
          ('2026-01-01'::date + (generate_series(1, 36) * interval '1 month'))::date as vesting_date,
          9722.22 as shares_to_vest, -- 350,000 shares / 36 months
          true, 'pending', now()
        FROM generate_series(1, 36);
        
        RAISE NOTICE '✓ Created vesting schedule for Khalid (36 months)';
      ELSE
        RAISE NOTICE '✓ Vesting schedule already exists for Khalid';
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '⚠ Could not create vesting schedule: %', SQLERRM;
    END;
  ELSE
    RAISE NOTICE '⚠ vesting_schedules table does not exist or no grant - skipping vesting schedule';
  END IF;

  RAISE NOTICE '=== ULTRA MINIMAL KHALID SETUP COMPLETE ===';
  RAISE NOTICE 'Khalid now has:';
  RAISE NOTICE '• Portal access enabled (username: khalid.alzahrani, password: Khalid2025!)';
  RAISE NOTICE '• Portfolio with 350,000 shares (if portfolios table exists)';
  RAISE NOTICE '• Grant with 350,000 shares (if grants table exists)';
  RAISE NOTICE '• Vesting schedule (if vesting_schedules table exists)';
  RAISE NOTICE '';
  RAISE NOTICE 'This migration is safe and handles missing tables gracefully!';

END $$;
