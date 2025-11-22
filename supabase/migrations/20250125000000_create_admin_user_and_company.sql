/*
  # Create Admin User and Company
  
  This migration creates:
  1. Derayah Financial company (if not exists)
  2. Admin user with proper authentication
  3. Links admin user to company with super_admin role
  
  Admin credentials:
  - Email: admin@derayah.com
  - Password: Admin123!
*/

DO $$
DECLARE
  v_company_id uuid;
  v_admin_user_id uuid;
  v_existing_company_id uuid;
  v_existing_user_id uuid;
BEGIN
  -- Check if Derayah Financial company already exists
  SELECT id INTO v_existing_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  -- Create company if it doesn't exist
  IF v_existing_company_id IS NULL THEN
    v_company_id := gen_random_uuid();
    
    INSERT INTO companies (
      id,
      company_name_en,
      company_name_ar,
      tadawul_symbol,
      commercial_registration_number,
      verification_status,
      total_reserved_shares,
      available_shares,
      status,
      created_at,
      updated_at
    ) VALUES (
      v_company_id,
      'Derayah Financial',
      'دارة المالية',
      'DERAYAH',
      '1010123456',
      'verified',
      10000000,
      10000000,
      'active',
      now(),
      now()
    );
    
    RAISE NOTICE 'Created Derayah Financial company with ID: %', v_company_id;
  ELSE
    v_company_id := v_existing_company_id;
    RAISE NOTICE 'Using existing Derayah Financial company with ID: %', v_company_id;
  END IF;
  
  -- Check if admin user already exists
  SELECT id INTO v_existing_user_id
  FROM auth.users
  WHERE email = 'admin@derayah.com';
  
  -- Create admin user if it doesn't exist
  IF v_existing_user_id IS NULL THEN
    v_admin_user_id := gen_random_uuid();
    
    -- Create auth user with complete structure
    INSERT INTO auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      invited_at,
      confirmation_token,
      confirmation_sent_at,
      recovery_token,
      recovery_sent_at,
      email_change_token_new,
      email_change,
      email_change_sent_at,
      last_sign_in_at,
      raw_app_meta_data,
      raw_user_meta_data,
      is_super_admin,
      created_at,
      updated_at,
      phone,
      phone_confirmed_at,
      phone_change,
      phone_change_token,
      phone_change_sent_at,
      email_change_token_current,
      email_change_confirm_status,
      banned_until,
      reauthentication_token,
      reauthentication_sent_at,
      is_sso_user,
      deleted_at,
      is_anonymous,
      role,
      aud
    ) VALUES (
      v_admin_user_id,
      '00000000-0000-0000-0000-000000000000',
      'admin@derayah.com',
      crypt('Admin123!', gen_salt('bf', 10)),
      now(),
      now(),
      '',
      now(),
      '',
      null,
      '',
      '',
      null,
      null,
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"name":"Admin User"}'::jsonb,
      true,
      now(),
      now(),
      null,
      null,
      '',
      '',
      null,
      '',
      0,
      null,
      '',
      null,
      false,
      null,
      false,
      'authenticated',
      'authenticated'
    );
    
    -- Create identity record
    INSERT INTO auth.identities (
      provider_id,
      user_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    ) VALUES (
      'admin@derayah.com',
      v_admin_user_id,
      jsonb_build_object(
        'sub', v_admin_user_id,
        'email', 'admin@derayah.com',
        'email_verified', true,
        'phone_verified', false
      ),
      'email',
      now(),
      now(),
      now()
    );
    
    RAISE NOTICE 'Created admin user with ID: %', v_admin_user_id;
  ELSE
    v_admin_user_id := v_existing_user_id;
    RAISE NOTICE 'Using existing admin user with ID: %', v_admin_user_id;
  END IF;
  
  -- Update company admin_user_id if not set
  UPDATE companies 
  SET admin_user_id = v_admin_user_id
  WHERE id = v_company_id AND admin_user_id IS NULL;
  
  -- Create company_users entry for super_admin role
  INSERT INTO company_users (
    company_id,
    user_id,
    role,
    permissions,
    is_active,
    created_at
  ) VALUES (
    v_company_id,
    v_admin_user_id,
    'super_admin',
    '{"can_manage_users": true, "can_manage_plans": true, "can_manage_grants": true, "can_export_data": true, "can_approve_plans": true}'::jsonb,
    true,
    now()
  ) ON CONFLICT (company_id, user_id) DO UPDATE SET
    role = 'super_admin',
    permissions = '{"can_manage_users": true, "can_manage_plans": true, "can_manage_grants": true, "can_export_data": true, "can_approve_plans": true}'::jsonb,
    is_active = true,
    updated_at = now();
  
  RAISE NOTICE 'Successfully created admin user and linked to company';
  RAISE NOTICE 'Admin login credentials:';
  RAISE NOTICE 'Email: admin@derayah.com';
  RAISE NOTICE 'Password: Admin123!';
  
END $$;
