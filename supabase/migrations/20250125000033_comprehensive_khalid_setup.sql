/*
  Comprehensive migration to set up Khalid Al-Zahrani's complete employee portal data.
  This migration will ensure Khalid has all necessary data to see shares, documents, and notifications.
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
  v_preference_id uuid;
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

  RAISE NOTICE '=== COMPREHENSIVE KHALID SETUP ===';

  -- 1. Enable portal access and set credentials
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
    UPDATE grants SET status = 'active', updated_at = now() WHERE id = v_grant_id;
    RAISE NOTICE '✓ Updated existing grant for Khalid: %', v_grant_id;
  END IF;

  -- 4. Create grant_documents for Khalid (if table exists)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'grant_documents') THEN
    IF NOT EXISTS (SELECT 1 FROM grant_documents WHERE employee_id = v_khalid_id) THEN
      INSERT INTO grant_documents (
        id, company_id, employee_id, grant_id, document_name, document_type,
        document_content, status, generated_at, created_at, updated_at
      ) VALUES (
        gen_random_uuid(), v_company_id, v_khalid_id, v_grant_id,
        'Stock Option Agreement - Khalid Al-Zahrani', 'contract',
        'STOCK OPTION AGREEMENT

This agreement is between Derayah Financial and Khalid Al-Zahrani for the grant of 350,000 stock options.

Grant Details:
- Total Shares: 350,000
- Vesting Period: 4 years (36 months)
- Vesting Start Date: January 1, 2026
- Vesting End Date: January 1, 2029
- Monthly Vesting: 9,722 shares per month

Terms and Conditions:
1. The options vest monthly over 36 months
2. Employee must remain employed during vesting period
3. Options expire 10 years from grant date
4. Subject to company performance conditions

Please review and sign this agreement to accept the grant.',
        'pending_signature', now(), now(), now()
      ) RETURNING id INTO v_document_id;
      
      RAISE NOTICE '✓ Created grant document for Khalid: %', v_document_id;
    ELSE
      RAISE NOTICE '✓ Grant documents already exist for Khalid';
    END IF;
  ELSE
    RAISE NOTICE '⚠ grant_documents table does not exist - creating in documents table';
    
    -- Create document in documents table
    INSERT INTO documents (
      id, company_id, employee_id, document_type, file_path, created_at, updated_at
    ) VALUES (
      gen_random_uuid(), v_company_id, v_khalid_id, 'contract', 
      '/documents/contracts/khalid_alzahrani_contract.pdf', now(), now()
    ) RETURNING id INTO v_document_id;
    
    RAISE NOTICE '✓ Created document for Khalid: %', v_document_id;
  END IF;

  -- 5. Create notifications for Khalid
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

  -- 6. Create additional notifications
  INSERT INTO employee_notifications (
    id, company_id, employee_id, notification_type, title, message,
    status, created_at, updated_at
  ) VALUES 
  (gen_random_uuid(), v_company_id, v_khalid_id, 'vesting_reminder',
   'Vesting Schedule Available',
   'Your 36-month vesting schedule is now available. You can view your monthly vesting dates and share amounts.',
   'unread', now(), now()),
  (gen_random_uuid(), v_company_id, v_khalid_id, 'document_ready',
   'Contract Document Ready',
   'Your stock option agreement is ready for review and signature. Please access the Documents section to view.',
   'unread', now(), now());

  RAISE NOTICE '✓ Created additional notifications for Khalid';

  -- 7. Create notification preferences for Khalid
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'employee_notification_preferences') THEN
    IF NOT EXISTS (SELECT 1 FROM employee_notification_preferences WHERE employee_id = v_khalid_id) THEN
      INSERT INTO employee_notification_preferences (
        id, company_id, employee_id, email_notifications, vesting_reminders,
        document_alerts, price_alerts, tax_reminders, price_alert_threshold,
        reminder_days_before, created_at, updated_at
      ) VALUES (
        gen_random_uuid(), v_company_id, v_khalid_id, true, true,
        true, false, true, 0, 7, now(), now()
      ) RETURNING id INTO v_preference_id;
      
      RAISE NOTICE '✓ Created notification preferences for Khalid: %', v_preference_id;
    ELSE
      RAISE NOTICE '✓ Notification preferences already exist for Khalid';
    END IF;
  ELSE
    RAISE NOTICE '⚠ employee_notification_preferences table does not exist';
  END IF;

  -- 8. Create vesting schedule for Khalid (36 months)
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

  -- 9. Update grant with proper share calculations
  UPDATE grants 
  SET vested_shares = 0,
      remaining_unvested_shares = 350000,
      updated_at = now()
  WHERE id = v_grant_id;

  RAISE NOTICE '✓ Updated grant with share calculations';

  RAISE NOTICE '=== KHALID COMPREHENSIVE SETUP COMPLETE ===';
  RAISE NOTICE 'Khalid now has:';
  RAISE NOTICE '• Portal access enabled (username: khalid.alzahrani, password: Khalid2025!)';
  RAISE NOTICE '• 350,000 shares grant (active status)';
  RAISE NOTICE '• Portfolio with 350,000 shares (0 available, 350,000 locked)';
  RAISE NOTICE '• Contract document (pending signature)';
  RAISE NOTICE '• 3 notifications (grant approval, vesting schedule, document ready)';
  RAISE NOTICE '• Notification preferences';
  RAISE NOTICE '• 36-month vesting schedule (9,722 shares/month)';
  RAISE NOTICE '';
  RAISE NOTICE 'Khalid should now see all data in the employee portal!';
  RAISE NOTICE 'Login with: khalid.alzahrani@derayah.com (or his email) and password';

END $$;
