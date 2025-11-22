/*
  Migration to set up complete employee data for Khalid Al-Zahrani.
  This migration will:
  1. Check Khalid's current data
  2. Set up his shares, grants, and documents
  3. Ensure he has proper portal access
*/

DO $$
DECLARE
  rec RECORD;
  v_company_id uuid;
  v_khalid_id uuid;
  v_plan_id uuid;
  v_grant_id uuid;
  v_portfolio_id uuid;
  v_contract_doc_id uuid;
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

  -- Check Khalid's current data
  RAISE NOTICE '=== KHALID CURRENT DATA ===';
  FOR rec IN
    SELECT 
      id, employee_number, first_name_en, last_name_en, email,
      user_id, portal_username, portal_password, portal_access_enabled,
      employment_status, hire_date
    FROM employees
    WHERE id = v_khalid_id
  LOOP
    RAISE NOTICE 'Employee: % % (ID: %) | Email: % | Auth User: % | Portal Enabled: % | Status: %', 
      rec.first_name_en, rec.last_name_en, rec.id, rec.email, 
      COALESCE(rec.user_id::text, 'NULL'),
      rec.portal_access_enabled,
      rec.employment_status;
  END LOOP;

  -- Check Khalid's grants
  RAISE NOTICE '=== KHALID GRANTS ===';
  FOR rec IN
    SELECT id, grant_number, total_shares, status, plan_id
    FROM grants
    WHERE employee_id = v_khalid_id
  LOOP
    RAISE NOTICE 'Grant: % | Shares: % | Status: % | Plan ID: %', 
      rec.grant_number, rec.total_shares, rec.status, rec.plan_id;
  END LOOP;

  -- Check Khalid's portfolio
  RAISE NOTICE '=== KHALID PORTFOLIO ===';
  FOR rec IN
    SELECT id, portfolio_type, total_shares, available_shares, locked_shares
    FROM portfolios
    WHERE employee_id = v_khalid_id
  LOOP
    RAISE NOTICE 'Portfolio: % | Type: % | Total: % | Available: % | Locked: %', 
      rec.id, rec.portfolio_type, rec.total_shares, rec.available_shares, rec.locked_shares;
  END LOOP;

  -- Check Khalid's documents
  RAISE NOTICE '=== KHALID DOCUMENTS ===';
  FOR rec IN
    SELECT id, document_type, file_path, created_at
    FROM documents
    WHERE employee_id = v_khalid_id
  LOOP
    RAISE NOTICE 'Document: % | Type: % | File: % | Created: %', 
      rec.id, rec.document_type, rec.file_path, rec.created_at;
  END LOOP;

  -- Check Khalid's notifications
  RAISE NOTICE '=== KHALID NOTIFICATIONS ===';
  FOR rec IN
    SELECT id, notification_type, title, message, status, created_at
    FROM employee_notifications
    WHERE employee_id = v_khalid_id
    ORDER BY created_at DESC
  LOOP
    RAISE NOTICE 'Notification: % | Type: % | Title: % | Status: % | Created: %', 
      rec.id, rec.notification_type, rec.title, rec.status, rec.created_at;
  END LOOP;

  -- Get the incentive plan ID
  SELECT id INTO v_plan_id
  FROM incentive_plans
  WHERE plan_name_en = 'Derayah Employee Stock Plan 2025' AND company_id = v_company_id;

  IF v_plan_id IS NULL THEN
    RAISE NOTICE 'Incentive plan not found. Exiting migration.';
    RETURN;
  END IF;

  RAISE NOTICE 'Incentive Plan ID: %', v_plan_id;

  -- Set up Khalid's complete profile
  RAISE NOTICE '=== SETTING UP KHALID COMPLETE PROFILE ===';

  -- 1. Enable portal access for Khalid
  UPDATE employees 
  SET portal_access_enabled = true,
      portal_username = 'khalid.alzahrani',
      portal_password = 'Khalid2025!',
      updated_at = now()
  WHERE id = v_khalid_id;

  RAISE NOTICE '✓ Enabled portal access for Khalid';

  -- 2. Create/update Khalid's portfolio
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

  -- 3. Create/update Khalid's grant
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
    RAISE NOTICE '✓ Grant already exists for Khalid: %', v_grant_id;
  END IF;

  -- 4. Create contract document for Khalid
  IF NOT EXISTS (SELECT 1 FROM documents WHERE employee_id = v_khalid_id AND document_type = 'contract') THEN
    INSERT INTO documents (
      id, company_id, employee_id, document_type, file_path, created_at, updated_at
    ) VALUES (
      gen_random_uuid(), v_company_id, v_khalid_id, 'contract', 
      '/documents/contracts/khalid_alzahrani_contract.pdf', now(), now()
    ) RETURNING id INTO v_contract_doc_id;
    
    RAISE NOTICE '✓ Created contract document for Khalid: %', v_contract_doc_id;
  ELSE
    SELECT id INTO v_contract_doc_id FROM documents WHERE employee_id = v_khalid_id AND document_type = 'contract';
    RAISE NOTICE '✓ Contract document already exists for Khalid: %', v_contract_doc_id;
  END IF;

  -- 5. Create notification for Khalid about grant approval
  INSERT INTO employee_notifications (
    id, company_id, employee_id, notification_type, title, message,
    status, created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_company_id, v_khalid_id, 'grant_approval',
    'Grant Approval Required',
    'Please review and approve your stock option grant of 350,000 shares. Click to view the contract document.',
    'unread', now(), now()
  ) RETURNING id INTO v_notification_id;

  RAISE NOTICE '✓ Created notification for Khalid: %', v_notification_id;

  -- 6. Create vesting schedule for Khalid (36 months)
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

  RAISE NOTICE '=== KHALID SETUP COMPLETE ===';
  RAISE NOTICE 'Khalid now has:';
  RAISE NOTICE '• Portal access enabled';
  RAISE NOTICE '• 350,000 shares grant';
  RAISE NOTICE '• Portfolio with shares';
  RAISE NOTICE '• Contract document pending approval';
  RAISE NOTICE '• Notification about grant approval';
  RAISE NOTICE '• 36-month vesting schedule';
  RAISE NOTICE '';
  RAISE NOTICE 'Khalid can now login and see his shares, documents, and notifications!';

END $$;
