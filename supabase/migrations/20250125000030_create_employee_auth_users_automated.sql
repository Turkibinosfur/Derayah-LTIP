/*
  Migration to create Supabase auth users for employees automatically.
  This migration will create auth users and link them to employee records.
  
  NOTE: This uses Supabase's auth.users table directly, which is the recommended approach.
*/

DO $$
DECLARE
  rec RECORD;
  v_company_id uuid;
  v_auth_user_id uuid;
  v_employee_count integer;
  v_created_count integer := 0;
  v_default_password text := 'Derayah2025!'; -- Default password for employees
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

  -- Count employees without auth users
  SELECT COUNT(*) INTO v_employee_count
  FROM employees
  WHERE company_id = v_company_id
  AND user_id IS NULL;

  RAISE NOTICE 'Employees without auth users: %', v_employee_count;

  IF v_employee_count = 0 THEN
    RAISE NOTICE 'All employees already have auth users. Exiting.';
    RETURN;
  END IF;

  RAISE NOTICE '=== CREATING AUTH USERS FOR EMPLOYEES ===';
  RAISE NOTICE 'Default password for new users: %', v_default_password;
  RAISE NOTICE '';

  -- Create auth users for employees
  FOR rec IN
    SELECT id, employee_number, first_name_en, last_name_en, email, portal_password
    FROM employees
    WHERE company_id = v_company_id
    AND user_id IS NULL
    ORDER BY employee_number
  LOOP
    RAISE NOTICE 'Creating auth user for: % % (Email: %)', 
      rec.first_name_en, rec.last_name_en, rec.email;
    
    -- Check if auth user already exists with this email
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = rec.email) THEN
      RAISE NOTICE '  → Auth user already exists for email: %', rec.email;
      
      -- Get the existing auth user ID
      SELECT id INTO v_auth_user_id
      FROM auth.users
      WHERE email = rec.email;
      
      -- Update employee record with existing auth user ID
      UPDATE employees 
      SET user_id = v_auth_user_id
      WHERE id = rec.id;
      
      RAISE NOTICE '  → Linked existing auth user to employee record';
    ELSE
      -- Create new auth user
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
        '00000000-0000-0000-0000-000000000000', -- Default instance ID
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        rec.email,
        crypt(COALESCE(rec.portal_password, v_default_password), gen_salt('bf')),
        now(),
        now(),
        now(),
        '',
        '',
        '',
        ''
      ) RETURNING id INTO v_auth_user_id;
      
      -- Update employee record with new auth user ID
      UPDATE employees 
      SET user_id = v_auth_user_id
      WHERE id = rec.id;
      
      RAISE NOTICE '  → Created new auth user with ID: %', v_auth_user_id;
      v_created_count := v_created_count + 1;
    END IF;
    
    RAISE NOTICE '  → Employee % % now linked to auth user', rec.first_name_en, rec.last_name_en;
    RAISE NOTICE '';
  END LOOP;

  RAISE NOTICE '=== AUTHENTICATION SETUP COMPLETE ===';
  RAISE NOTICE 'Total auth users created: %', v_created_count;
  RAISE NOTICE 'Total employees processed: %', v_employee_count;
  RAISE NOTICE '';
  RAISE NOTICE '=== LOGIN INSTRUCTIONS FOR EMPLOYEES ===';
  RAISE NOTICE 'Employees can now login using:';
  RAISE NOTICE '• Email: Their company email address';
  RAISE NOTICE '• Password: Their portal password (if set) or default password';
  RAISE NOTICE '';
  RAISE NOTICE 'Default password for employees without portal password: %', v_default_password;
  RAISE NOTICE '';
  RAISE NOTICE '=== NEXT STEPS ===';
  RAISE NOTICE '1. Test employee login with email + password';
  RAISE NOTICE '2. Employees can change their passwords after first login';
  RAISE NOTICE '3. Portal credentials remain as backup authentication method';
  RAISE NOTICE '4. Monitor authentication through Supabase dashboard';

END $$;
