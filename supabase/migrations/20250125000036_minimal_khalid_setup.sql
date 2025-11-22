/*
  Minimal migration to set up Khalid Al-Zahrani's employee data.
  This migration uses only the most basic columns that are guaranteed to exist.
*/

DO $$
DECLARE
  rec RECORD;
  v_company_id uuid;
  v_khalid_id uuid;
  v_plan_id uuid;
  v_grant_id uuid;
  v_portfolio_id uuid;
  v_document_id uuid;
  v_notification_id uuid;
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

  RAISE NOTICE '=== MINIMAL KHALID SETUP ===';

  -- 1. Enable portal access for Khalid
  UPDATE employees 
  SET portal_access_enabled = true,
      portal_username = 'khalid.alzahrani',
      portal_password = 'Khalid2025!',
      updated_at = now()
  WHERE id = v_khalid_id;

  RAISE NOTICE '✓ Enabled portal access for Khalid';

  -- 2. Create/update Khalid's portfolio (minimal columns)
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

  -- 3. Create/update Khalid's grant (minimal columns)
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

  -- 4. Create document for Khalid (minimal columns only)
  IF NOT EXISTS (SELECT 1 FROM documents WHERE employee_id = v_khalid_id AND document_type = 'contract') THEN
    INSERT INTO documents (
      id, company_id, employee_id, document_type, file_path, created_at, updated_at
    ) VALUES (
      gen_random_uuid(), v_company_id, v_khalid_id, 'contract', 
      '/documents/contracts/khalid_alzahrani_contract.pdf', now(), now()
    ) RETURNING id INTO v_document_id;
    
    RAISE NOTICE '✓ Created document for Khalid: %', v_document_id;
  ELSE
    SELECT id INTO v_document_id FROM documents WHERE employee_id = v_khalid_id AND document_type = 'contract';
    RAISE NOTICE '✓ Document already exists for Khalid: %', v_document_id;
  END IF;

  -- 5. Create notification for Khalid (if table exists)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'employee_notifications') THEN
    INSERT INTO employee_notifications (
      id, company_id, employee_id, notification_type, title, message,
      status, created_at, updated_at
    ) VALUES (
      gen_random_uuid(), v_company_id, v_khalid_id, 'grant_approval',
      'Grant Approval Required',
      'Please review and approve your stock option grant of 350,000 shares.',
      'unread', now(), now()
    ) RETURNING id INTO v_notification_id;
    
    RAISE NOTICE '✓ Created notification for Khalid: %', v_notification_id;
  ELSE
    RAISE NOTICE '⚠ employee_notifications table does not exist - skipping notifications';
  END IF;

  -- 6. Create vesting schedule for Khalid (if table exists)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'vesting_schedules') THEN
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
  ELSE
    RAISE NOTICE '⚠ vesting_schedules table does not exist - skipping vesting schedule';
  END IF;

  -- 7. Update grant with proper share calculations
  UPDATE grants 
  SET vested_shares = 0,
      remaining_unvested_shares = 350000,
      updated_at = now()
  WHERE id = v_grant_id;

  RAISE NOTICE '✓ Updated grant with share calculations';

  RAISE NOTICE '=== MINIMAL KHALID SETUP COMPLETE ===';
  RAISE NOTICE 'Khalid now has:';
  RAISE NOTICE '• Portal access enabled (username: khalid.alzahrani, password: Khalid2025!)';
  RAISE NOTICE '• 350,000 shares grant (active status)';
  RAISE NOTICE '• Portfolio with 350,000 shares (0 available, 350,000 locked)';
  RAISE NOTICE '• Contract document';
  RAISE NOTICE '• Notification (if table exists)';
  RAISE NOTICE '• Vesting schedule (if table exists)';
  RAISE NOTICE '';
  RAISE NOTICE 'Khalid should now see data in the employee portal!';

END $$;
