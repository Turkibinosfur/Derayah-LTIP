/*
  Migration to properly link Khalid Al-Zahrani employee record to wajehah.com@gmail.com auth user.
  This migration will:
  1. Check if Khalid has an auth user linked
  2. Create auth user for wajehah.com@gmail.com if needed
  3. Link Khalid's employee record to the auth user
  4. Ensure portal access is enabled
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
  RAISE NOTICE 'Linking Khalid Al-Zahrani to auth user: %', v_user_email;

  -- Get Khalid's employee ID
  SELECT id INTO v_khalid_id
  FROM employees
  WHERE first_name_en = 'Khalid' AND last_name_en = 'Al-Zahrani' AND company_id = v_company_id;

  IF v_khalid_id IS NULL THEN
    RAISE NOTICE 'Khalid Al-Zahrani not found. Exiting migration.';
    RETURN;
  END IF;

  RAISE NOTICE 'Khalid Al-Zahrani ID: %', v_khalid_id;

  -- Check Khalid's current auth status
  RAISE NOTICE '=== KHALID CURRENT AUTH STATUS ===';
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
      RAISE NOTICE '  → Khalid already has auth user: %', rec.user_id;
    ELSE
      RAISE NOTICE '  → Khalid does NOT have auth user - this is the problem!';
    END IF;
  END LOOP;

  -- Check if auth user exists for wajehah.com@gmail.com
  SELECT id INTO v_auth_user_id
  FROM auth.users
  WHERE email = v_user_email;

  IF v_auth_user_id IS NOT NULL THEN
    v_auth_user_exists := true;
    RAISE NOTICE 'Auth user already exists for % with ID: %', v_user_email, v_auth_user_id;
  ELSE
    RAISE NOTICE 'No auth user exists for % - will create one', v_user_email;
  END IF;

  -- Show Khalid's data before linking
  RAISE NOTICE '=== KHALID GRANTS DATA ===';
  FOR rec IN
    SELECT id, grant_number, total_shares, vested_shares, remaining_unvested_shares, status, grant_date
    FROM grants
    WHERE employee_id = v_khalid_id
  LOOP
    RAISE NOTICE 'Grant: % | Shares: % | Vested: % | Unvested: % | Status: % | Granted: %', 
      rec.grant_number, rec.total_shares, rec.vested_shares, rec.remaining_unvested_shares, rec.status, rec.grant_date;
  END LOOP;

  RAISE NOTICE '=== KHALID PORTFOLIO DATA ===';
  FOR rec IN
    SELECT id, portfolio_type, total_shares, available_shares, locked_shares, portfolio_number
    FROM portfolios
    WHERE employee_id = v_khalid_id
  LOOP
    RAISE NOTICE 'Portfolio: % | Type: % | Total: % | Available: % | Locked: % | Number: %', 
      rec.id, rec.portfolio_type, rec.total_shares, rec.available_shares, rec.locked_shares, rec.portfolio_number;
  END LOOP;

  -- Create auth user if it doesn't exist
  IF NOT v_auth_user_exists THEN
    RAISE NOTICE '=== CREATING AUTH USER ===';
    
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
      crypt('Wajehah2025!', gen_salt('bf')),
      now(),
      now(),
      now(),
      '',
      '',
      '',
      ''
    ) RETURNING id INTO v_auth_user_id;
    
    RAISE NOTICE '✓ Created auth user with ID: %', v_auth_user_id;
  ELSE
    RAISE NOTICE '✓ Auth user already exists with ID: %', v_auth_user_id;
  END IF;

  -- Link Khalid's employee record to the auth user
  RAISE NOTICE '=== LINKING KHALID TO AUTH USER ===';
  
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

  -- Show updated data
  RAISE NOTICE '=== UPDATED EMPLOYEE DATA ===';
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

  RAISE NOTICE '=== LINKING COMPLETE ===';
  RAISE NOTICE 'Khalid Al-Zahrani is now properly linked to %', v_user_email;
  RAISE NOTICE '';
  RAISE NOTICE 'Login credentials:';
  RAISE NOTICE '• Email: %', v_user_email;
  RAISE NOTICE '• Password: Wajehah2025!';
  RAISE NOTICE '';
  RAISE NOTICE 'All existing data is preserved and linked:';
  RAISE NOTICE '• Grants: All grant data remains unchanged';
  RAISE NOTICE '• Portfolio: All portfolio data remains unchanged';
  RAISE NOTICE '• Documents: All document data remains unchanged';
  RAISE NOTICE '• Notifications: All notification data remains unchanged';
  RAISE NOTICE '• Vesting Schedules: All vesting data remains unchanged';
  RAISE NOTICE '';
  RAISE NOTICE 'The user can now login and see the dashboard with all existing data!';
  RAISE NOTICE 'This fixes the issue where Khalid and wajehah.com@gmail.com were not linked.';

END $$;
