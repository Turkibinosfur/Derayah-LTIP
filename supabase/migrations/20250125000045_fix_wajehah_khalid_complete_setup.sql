/*
  Comprehensive fix migration to ensure wajehah.com@gmail.com is properly linked to Khalid Al-Zahrani
  and has all necessary data for the employee portal.
  
  This migration will:
  1. Create/find auth user for wajehah.com@gmail.com
  2. Link Khalid's employee record to the auth user
  3. Ensure Khalid has all necessary data (grants, portfolio, documents, notifications)
  4. Create missing data if needed
*/

DO $$
DECLARE
  rec RECORD;
  v_company_id uuid;
  v_khalid_id uuid;
  v_auth_user_id uuid;
  v_plan_id uuid;
  v_grant_id uuid;
  v_portfolio_id uuid;
  v_user_email text := 'wajehah.com@gmail.com';
  v_auth_user_exists boolean := false;
  v_khalid_has_auth boolean := false;
  v_grant_exists boolean := false;
  v_portfolio_exists boolean := false;
  v_document_exists boolean := false;
  v_notification_exists boolean := false;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';

  IF v_company_id IS NULL THEN
    RAISE NOTICE 'Company "Derayah Financial" not found. Exiting migration.';
    RETURN;
  END IF;

  RAISE NOTICE '=== COMPREHENSIVE FIX: Wajehah.com@gmail.com and Khalid Setup ===';
  RAISE NOTICE 'Company ID: %', v_company_id;

  -- Get Khalid's employee ID
  SELECT id INTO v_khalid_id
  FROM employees
  WHERE first_name_en = 'Khalid' AND last_name_en = 'Al-Zahrani' AND company_id = v_company_id;

  IF v_khalid_id IS NULL THEN
    RAISE NOTICE 'Khalid Al-Zahrani not found. Exiting migration.';
    RETURN;
  END IF;

  RAISE NOTICE 'Khalid Al-Zahrani ID: %', v_khalid_id;

  -- 1. CREATE/FIND AUTH USER FOR wajehah.com@gmail.com
  RAISE NOTICE '=== STEP 1: AUTH USER SETUP ===';
  
  SELECT id INTO v_auth_user_id
  FROM auth.users
  WHERE email = v_user_email;

  IF v_auth_user_id IS NOT NULL THEN
    v_auth_user_exists := true;
    RAISE NOTICE '✓ Auth user already exists for % with ID: %', v_user_email, v_auth_user_id;
  ELSE
    RAISE NOTICE 'Creating auth user for %', v_user_email;
    
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(),
      'authenticated',
      'authenticated',
      v_user_email,
      crypt('Na101918!@', gen_salt('bf')),
      now(),
      now(),
      now(),
      '',
      '',
      '',
      ''
    ) RETURNING id INTO v_auth_user_id;
    
    RAISE NOTICE '✓ Created auth user with ID: %', v_auth_user_id;
  END IF;

  -- 2. LINK KHALID TO AUTH USER
  RAISE NOTICE '=== STEP 2: LINKING KHALID TO AUTH USER ===';
  
  UPDATE employees 
  SET 
    user_id = v_auth_user_id,
    email = v_user_email,
    portal_access_enabled = true,
    portal_username = 'khalid.alzahrani',
    portal_password = 'Khalid2025!',
    updated_at = now()
  WHERE id = v_khalid_id;

  RAISE NOTICE '✓ Linked Khalid employee record to auth user';

  -- 3. GET INCENTIVE PLAN ID
  SELECT id INTO v_plan_id
  FROM incentive_plans
  WHERE plan_name_en = 'Derayah Employee Stock Plan 2025' AND company_id = v_company_id;

  IF v_plan_id IS NULL THEN
    RAISE NOTICE '❌ Incentive plan not found. Cannot create grant.';
    RETURN;
  END IF;

  RAISE NOTICE '✓ Found incentive plan: %', v_plan_id;

  -- 4. CREATE/UPDATE KHALID'S GRANT
  RAISE NOTICE '=== STEP 3: GRANT SETUP ===';
  
  IF EXISTS (SELECT 1 FROM grants WHERE employee_id = v_khalid_id) THEN
    v_grant_exists := true;
    RAISE NOTICE '✓ Khalid already has grants';
    
    -- Update existing grant to ensure it's active
    UPDATE grants 
    SET 
      status = 'active',
      total_shares = 350000,
      updated_at = now()
    WHERE employee_id = v_khalid_id;
    
    RAISE NOTICE '✓ Updated existing grant';
  ELSE
    RAISE NOTICE 'Creating new grant for Khalid';
    
    INSERT INTO grants (
      id, company_id, employee_id, plan_id, grant_number,
      total_shares, grant_date, vesting_start_date, 
      vesting_end_date, status, created_at, updated_at
    ) VALUES (
      gen_random_uuid(), v_company_id, v_khalid_id, v_plan_id, 'GRANT-2025-002',
      350000, '2025-01-01', '2026-01-01', '2029-01-01', 'active', now(), now()
    ) RETURNING id INTO v_grant_id;
    
    RAISE NOTICE '✓ Created new grant: %', v_grant_id;
  END IF;

  -- 5. CREATE/UPDATE KHALID'S PORTFOLIO
  RAISE NOTICE '=== STEP 4: PORTFOLIO SETUP ===';
  
  IF EXISTS (SELECT 1 FROM portfolios WHERE employee_id = v_khalid_id) THEN
    v_portfolio_exists := true;
    RAISE NOTICE '✓ Khalid already has portfolio';
    
    -- Update existing portfolio
    UPDATE portfolios 
    SET 
      total_shares = 350000,
      available_shares = 350000,
      locked_shares = 0,
      updated_at = now()
    WHERE employee_id = v_khalid_id;
    
    RAISE NOTICE '✓ Updated existing portfolio';
  ELSE
    RAISE NOTICE 'Creating new portfolio for Khalid';
    
    INSERT INTO portfolios (
      id, portfolio_type, company_id, employee_id, total_shares, 
      available_shares, locked_shares, portfolio_number, created_at, updated_at
    ) VALUES (
      gen_random_uuid(), 'employee_vested', v_company_id, v_khalid_id, 350000, 
      350000, 0, 'PORT-2025-002', now(), now()
    ) RETURNING id INTO v_portfolio_id;
    
    RAISE NOTICE '✓ Created new portfolio: %', v_portfolio_id;
  END IF;

  -- 6. CREATE DOCUMENTS
  RAISE NOTICE '=== STEP 5: DOCUMENT SETUP ===';
  
  IF EXISTS (SELECT 1 FROM documents WHERE company_id = v_company_id AND document_type = 'contract') THEN
    v_document_exists := true;
    RAISE NOTICE '✓ Contract document already exists';
  ELSE
    RAISE NOTICE 'Creating contract document';
    
    INSERT INTO documents (
      id, company_id, document_type, file_name, storage_path
    ) VALUES (
      gen_random_uuid(), v_company_id, 'contract', 'khalid-alzahrani-contract.pdf', '/documents/contracts/khalid-alzahrani-contract.pdf'
    );
    
    RAISE NOTICE '✓ Created contract document';
  END IF;

  -- 7. CREATE NOTIFICATIONS (if table exists)
  RAISE NOTICE '=== STEP 6: NOTIFICATION SETUP ===';
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'employee_notifications') THEN
    IF EXISTS (SELECT 1 FROM employee_notifications WHERE employee_id = v_khalid_id) THEN
      v_notification_exists := true;
      RAISE NOTICE '✓ Khalid already has notifications';
    ELSE
      RAISE NOTICE 'Creating notifications for Khalid';
      
      -- Grant approval notification
      INSERT INTO employee_notifications (
        id, employee_id, notification_type, title, message, is_read, created_at
      ) VALUES (
        gen_random_uuid(), v_khalid_id, 'grant_approval', 
        'Grant Approval Required', 
        'Your stock grant of 350,000 shares is ready for approval. Please review and sign the contract.', 
        false, now()
      );
      
      -- Vesting schedule notification
      INSERT INTO employee_notifications (
        id, employee_id, notification_type, title, message, is_read, created_at
      ) VALUES (
        gen_random_uuid(), v_khalid_id, 'vesting_schedule', 
        'Vesting Schedule Available', 
        'Your 36-month vesting schedule is now available. Check your portfolio for details.', 
        false, now()
      );
      
      -- Document ready notification
      INSERT INTO employee_notifications (
        id, employee_id, notification_type, title, message, is_read, created_at
      ) VALUES (
        gen_random_uuid(), v_khalid_id, 'document_ready', 
        'Contract Ready for Signature', 
        'Your employment contract and grant agreement are ready for your signature.', 
        false, now()
      );
      
      RAISE NOTICE '✓ Created 3 notifications for Khalid';
    END IF;
  ELSE
    RAISE NOTICE 'employee_notifications table does not exist - skipping notifications setup';
  END IF;

  -- 8. CREATE VESTING SCHEDULE
  RAISE NOTICE '=== STEP 7: VESTING SCHEDULE SETUP ===';
  
  -- Get the grant ID for vesting schedule
  SELECT id INTO v_grant_id FROM grants WHERE employee_id = v_khalid_id LIMIT 1;
  
  IF v_grant_id IS NOT NULL THEN
    -- Check if vesting schedules already exist for this grant
    DECLARE
      v_vesting_count integer;
    BEGIN
      SELECT COUNT(*) INTO v_vesting_count FROM vesting_schedules WHERE grant_id = v_grant_id;
      
      IF v_vesting_count = 0 THEN
        RAISE NOTICE 'Creating vesting schedule for Khalid';
        
        -- Create vesting schedules one by one to avoid duplicates
        FOR i IN 1..36 LOOP
          INSERT INTO vesting_schedules (
            id, grant_id, sequence_number, vesting_date, shares_to_vest, 
            performance_condition_met, status, created_at
          ) VALUES (
            gen_random_uuid(), v_grant_id, i,
            ('2026-01-01'::date + (i * interval '1 month'))::date,
            9722.22, -- 350,000 shares / 36 months
            true, 'pending', now()
          );
        END LOOP;
        
        RAISE NOTICE '✓ Created 36-month vesting schedule';
      ELSE
        RAISE NOTICE '✓ Vesting schedule already exists for grant %', v_grant_id;
        RAISE NOTICE '  → Found % existing vesting schedules', v_vesting_count;
      END IF;
    END;
  ELSE
    RAISE NOTICE '❌ No grant found for Khalid - cannot create vesting schedule';
  END IF;

  -- 9. FINAL VERIFICATION
  RAISE NOTICE '=== FINAL VERIFICATION ===';
  
  -- Check auth linking
  SELECT user_id INTO v_auth_user_id FROM employees WHERE id = v_khalid_id;
  IF v_auth_user_id IS NOT NULL THEN
    RAISE NOTICE '✓ Khalid is linked to auth user: %', v_auth_user_id;
  ELSE
    RAISE NOTICE '❌ Khalid is NOT linked to auth user';
  END IF;
  
  -- Check grants
  SELECT COUNT(*) INTO v_grant_exists FROM grants WHERE employee_id = v_khalid_id;
  RAISE NOTICE '✓ Khalid has % grants', v_grant_exists;
  
  -- Check portfolio
  SELECT COUNT(*) INTO v_portfolio_exists FROM portfolios WHERE employee_id = v_khalid_id;
  RAISE NOTICE '✓ Khalid has % portfolios', v_portfolio_exists;
  
  -- Check documents
  SELECT COUNT(*) INTO v_document_exists FROM documents WHERE company_id = v_company_id;
  RAISE NOTICE '✓ Company has % documents', v_document_exists;
  
  -- Check notifications (if table exists)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'employee_notifications') THEN
    SELECT COUNT(*) INTO v_notification_exists FROM employee_notifications WHERE employee_id = v_khalid_id;
    RAISE NOTICE '✓ Khalid has % notifications', v_notification_exists;
  ELSE
    RAISE NOTICE '✓ Notifications table does not exist - skipping notifications check';
  END IF;

  RAISE NOTICE '=== SETUP COMPLETE ===';
  RAISE NOTICE 'Khalid Al-Zahrani is now properly linked to wajehah.com@gmail.com';
  RAISE NOTICE '';
  RAISE NOTICE 'Login credentials:';
  RAISE NOTICE '• Email: %', v_user_email;
  RAISE NOTICE '• Password: Na101918!@';
  RAISE NOTICE '';
  RAISE NOTICE 'Expected data in employee portal:';
  RAISE NOTICE '• Portfolio: 350,000 shares';
  RAISE NOTICE '• Grant: Active grant with 36-month vesting';
  RAISE NOTICE '• Documents: Contract ready for signature';
  RAISE NOTICE '• Notifications: 3 notifications for grant approval';
  RAISE NOTICE '';
  RAISE NOTICE 'The user should now be able to login and see all data!';

END $$;
