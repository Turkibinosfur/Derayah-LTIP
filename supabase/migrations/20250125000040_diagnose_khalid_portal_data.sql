/*
  Diagnostic migration to check what data Khalid has for the employee portal.
  This will help identify why the portal is not showing data.
*/

DO $$
DECLARE
  rec RECORD;
  v_company_id uuid;
  v_khalid_id uuid;
  v_grant_count integer;
  v_portfolio_count integer;
  v_document_count integer;
  v_notification_count integer;
  v_vesting_count integer;
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

  RAISE NOTICE '=== KHALID PORTAL DATA DIAGNOSIS ===';

  -- Check Khalid's basic info
  RAISE NOTICE '=== KHALID BASIC INFO ===';
  FOR rec IN
    SELECT id, employee_number, first_name_en, last_name_en, email,
           portal_access_enabled, portal_username, portal_password
    FROM employees
    WHERE id = v_khalid_id
  LOOP
    RAISE NOTICE 'Employee: % % (ID: %) | Email: % | Portal Enabled: % | Username: % | Password: %', 
      rec.first_name_en, rec.last_name_en, rec.id, rec.email, 
      rec.portal_access_enabled, rec.portal_username, rec.portal_password;
  END LOOP;

  -- Check Khalid's grants
  RAISE NOTICE '=== KHALID GRANTS ===';
  SELECT COUNT(*) INTO v_grant_count FROM grants WHERE employee_id = v_khalid_id;
  RAISE NOTICE 'Number of grants: %', v_grant_count;
  
  FOR rec IN
    SELECT id, grant_number, total_shares, vested_shares, remaining_unvested_shares, status, grant_date
    FROM grants
    WHERE employee_id = v_khalid_id
  LOOP
    RAISE NOTICE 'Grant: % | Shares: % | Vested: % | Unvested: % | Status: % | Granted: %', 
      rec.grant_number, rec.total_shares, rec.vested_shares, rec.remaining_unvested_shares, rec.status, rec.grant_date;
  END LOOP;

  -- Check Khalid's portfolio
  RAISE NOTICE '=== KHALID PORTFOLIO ===';
  SELECT COUNT(*) INTO v_portfolio_count FROM portfolios WHERE employee_id = v_khalid_id;
  RAISE NOTICE 'Number of portfolios: %', v_portfolio_count;
  
  FOR rec IN
    SELECT id, portfolio_type, total_shares, available_shares, locked_shares, portfolio_number
    FROM portfolios
    WHERE employee_id = v_khalid_id
  LOOP
    RAISE NOTICE 'Portfolio: % | Type: % | Total: % | Available: % | Locked: % | Number: %', 
      rec.id, rec.portfolio_type, rec.total_shares, rec.available_shares, rec.locked_shares, rec.portfolio_number;
  END LOOP;

  -- Check Khalid's documents
  RAISE NOTICE '=== KHALID DOCUMENTS ===';
  SELECT COUNT(*) INTO v_document_count FROM documents WHERE company_id = v_company_id;
  RAISE NOTICE 'Number of documents for company: %', v_document_count;
  
  FOR rec IN
    SELECT id, document_type, file_path, created_at
    FROM documents
    WHERE company_id = v_company_id
  LOOP
    RAISE NOTICE 'Document: % | Type: % | Path: % | Created: %', 
      rec.id, rec.document_type, rec.file_path, rec.created_at;
  END LOOP;

  -- Check Khalid's notifications
  RAISE NOTICE '=== KHALID NOTIFICATIONS ===';
  SELECT COUNT(*) INTO v_notification_count FROM employee_notifications WHERE employee_id = v_khalid_id;
  RAISE NOTICE 'Number of notifications: %', v_notification_count;
  
  FOR rec IN
    SELECT id, notification_type, title, message, status, created_at
    FROM employee_notifications
    WHERE employee_id = v_khalid_id
    ORDER BY created_at DESC
  LOOP
    RAISE NOTICE 'Notification: % | Type: % | Title: % | Status: % | Created: %', 
      rec.id, rec.notification_type, rec.title, rec.status, rec.created_at;
  END LOOP;

  -- Check Khalid's vesting schedules
  RAISE NOTICE '=== KHALID VESTING SCHEDULES ===';
  SELECT COUNT(*) INTO v_vesting_count 
  FROM vesting_schedules vs
  JOIN grants g ON vs.grant_id = g.id
  WHERE g.employee_id = v_khalid_id;
  RAISE NOTICE 'Number of vesting schedules: %', v_vesting_count;
  
  FOR rec IN
    SELECT vs.sequence_number, vs.vesting_date, vs.shares_to_vest, vs.status
    FROM vesting_schedules vs
    JOIN grants g ON vs.grant_id = g.id
    WHERE g.employee_id = v_khalid_id
    ORDER BY vs.sequence_number
    LIMIT 5
  LOOP
    RAISE NOTICE 'Vesting %: Date: % | Shares: % | Status: %', 
      rec.sequence_number, rec.vesting_date, rec.shares_to_vest, rec.status;
  END LOOP;

  -- Check if Khalid has auth user
  RAISE NOTICE '=== KHALID AUTH USER ===';
  FOR rec IN
    SELECT user_id FROM employees WHERE id = v_khalid_id
  LOOP
    IF rec.user_id IS NOT NULL THEN
      RAISE NOTICE '✓ Khalid has auth user: %', rec.user_id;
    ELSE
      RAISE NOTICE '✗ Khalid does not have auth user - this will prevent login!';
    END IF;
  END LOOP;

  RAISE NOTICE '=== DIAGNOSIS SUMMARY ===';
  RAISE NOTICE 'Grants: % | Portfolio: % | Documents: % | Notifications: % | Vesting: %', 
    v_grant_count, v_portfolio_count, v_document_count, v_notification_count, v_vesting_count;
  
  IF v_grant_count = 0 THEN
    RAISE NOTICE '⚠ ISSUE: Khalid has no grants - this will cause empty dashboard';
  END IF;
  
  IF v_portfolio_count = 0 THEN
    RAISE NOTICE '⚠ ISSUE: Khalid has no portfolio - this will cause empty portfolio view';
  END IF;
  
  IF v_document_count = 0 THEN
    RAISE NOTICE '⚠ ISSUE: Khalid has no documents - this will cause empty documents view';
  END IF;
  
  IF v_notification_count = 0 THEN
    RAISE NOTICE '⚠ ISSUE: Khalid has no notifications - this will cause empty notifications';
  END IF;

  RAISE NOTICE '=== RECOMMENDATIONS ===';
  RAISE NOTICE '1. Run the complete portal data setup migration';
  RAISE NOTICE '2. Ensure Khalid has an auth user for login';
  RAISE NOTICE '3. Check RLS policies allow employee to see their own data';
  RAISE NOTICE '4. Verify frontend components are loading data correctly';

END $$;
