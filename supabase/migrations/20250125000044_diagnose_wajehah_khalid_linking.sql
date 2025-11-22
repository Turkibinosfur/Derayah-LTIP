/*
  Diagnostic migration to check the linking between wajehah.com@gmail.com and Khalid Al-Zahrani.
  This will help identify why the employee portal is not showing data.
*/

DO $$
DECLARE
  rec RECORD;
  v_company_id uuid;
  v_khalid_id uuid;
  v_auth_user_id uuid;
  v_user_email text := 'wajehah.com@gmail.com';
  v_auth_user_exists boolean := false;
  v_khalid_has_auth boolean := false;
  v_grant_count integer := 0;
  v_portfolio_count integer := 0;
  v_document_count integer := 0;
  v_notification_count integer := 0;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';

  IF v_company_id IS NULL THEN
    RAISE NOTICE 'Company "Derayah Financial" not found. Exiting migration.';
    RETURN;
  END IF;

  RAISE NOTICE '=== DIAGNOSTIC: Wajehah.com@gmail.com and Khalid Linking ===';
  RAISE NOTICE 'Company ID: %', v_company_id;

  -- Check if auth user exists for wajehah.com@gmail.com
  SELECT id INTO v_auth_user_id
  FROM auth.users
  WHERE email = v_user_email;

  IF v_auth_user_id IS NOT NULL THEN
    v_auth_user_exists := true;
    RAISE NOTICE '✓ Auth user exists for % with ID: %', v_user_email, v_auth_user_id;
  ELSE
    RAISE NOTICE '❌ No auth user exists for %', v_user_email;
  END IF;

  -- Get Khalid's employee ID
  SELECT id INTO v_khalid_id
  FROM employees
  WHERE first_name_en = 'Khalid' AND last_name_en = 'Al-Zahrani' AND company_id = v_company_id;

  IF v_khalid_id IS NULL THEN
    RAISE NOTICE '❌ Khalid Al-Zahrani not found.';
    RETURN;
  END IF;

  RAISE NOTICE '✓ Khalid Al-Zahrani ID: %', v_khalid_id;

  -- Check Khalid's current auth status
  RAISE NOTICE '=== KHALID AUTH STATUS ===';
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
    
    IF rec.user_id IS NOT NULL THEN
      v_khalid_has_auth := true;
      RAISE NOTICE '  → Khalid has auth user: %', rec.user_id;
      
      -- Check if this auth user matches wajehah.com@gmail.com
      IF rec.user_id = v_auth_user_id THEN
        RAISE NOTICE '  ✓ Auth user matches wajehah.com@gmail.com - LINKING IS CORRECT!';
      ELSE
        RAISE NOTICE '  ❌ Auth user does NOT match wajehah.com@gmail.com - THIS IS THE PROBLEM!';
        RAISE NOTICE '  Expected: % | Actual: %', v_auth_user_id, rec.user_id;
      END IF;
    ELSE
      RAISE NOTICE '  ❌ Khalid does NOT have auth user - THIS IS THE PROBLEM!';
    END IF;
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
    SELECT id, document_type, file_name
    FROM documents
    WHERE company_id = v_company_id
  LOOP
    RAISE NOTICE 'Document: % | Type: % | Name: %', 
      rec.id, rec.document_type, rec.file_name;
  END LOOP;

  -- Check if employee_notifications table exists
  RAISE NOTICE '=== KHALID NOTIFICATIONS ===';
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'employee_notifications') THEN
    SELECT COUNT(*) INTO v_notification_count FROM employee_notifications WHERE employee_id = v_khalid_id;
    RAISE NOTICE 'Number of notifications: %', v_notification_count;
    
    FOR rec IN
      SELECT id, notification_type, title, message, is_read, created_at
      FROM employee_notifications
      WHERE employee_id = v_khalid_id
    LOOP
      RAISE NOTICE 'Notification: % | Type: % | Title: % | Read: % | Created: %', 
        rec.id, rec.notification_type, rec.title, rec.is_read, rec.created_at;
    END LOOP;
  ELSE
    RAISE NOTICE 'employee_notifications table does not exist - skipping notifications check';
  END IF;

  -- Summary
  RAISE NOTICE '=== DIAGNOSTIC SUMMARY ===';
  RAISE NOTICE 'Auth user exists: %', v_auth_user_exists;
  RAISE NOTICE 'Khalid has auth: %', v_khalid_has_auth;
  RAISE NOTICE 'Grants: %', v_grant_count;
  RAISE NOTICE 'Portfolios: %', v_portfolio_count;
  RAISE NOTICE 'Documents: %', v_document_count;
  RAISE NOTICE 'Notifications: %', v_notification_count;
  
  IF v_khalid_has_auth AND v_auth_user_exists THEN
    RAISE NOTICE '✓ Khalid is properly linked to auth user';
  ELSE
    RAISE NOTICE '❌ Khalid is NOT properly linked to auth user';
  END IF;
  
  IF v_grant_count > 0 THEN
    RAISE NOTICE '✓ Khalid has grants data';
  ELSE
    RAISE NOTICE '❌ Khalid has NO grants data';
  END IF;
  
  IF v_portfolio_count > 0 THEN
    RAISE NOTICE '✓ Khalid has portfolio data';
  ELSE
    RAISE NOTICE '❌ Khalid has NO portfolio data';
  END IF;
  
  IF v_document_count > 0 THEN
    RAISE NOTICE '✓ Company has documents';
  ELSE
    RAISE NOTICE '❌ Company has NO documents';
  END IF;
  
  IF v_notification_count > 0 THEN
    RAISE NOTICE '✓ Khalid has notifications';
  ELSE
    RAISE NOTICE '❌ Khalid has NO notifications';
  END IF;

END $$;
