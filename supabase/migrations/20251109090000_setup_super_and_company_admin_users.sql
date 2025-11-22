/*
  # Split Super Admin and Company Admin Accounts

  - Ensures Derayah Financial company exists
  - Creates/updates a company admin account: admin@derayah.com / Admin123!
  - Creates/updates a SaaS super admin account: superadmin@derayah.com / Superadmin123!
  - Links the company admin to Derayah as company_admin
  - Links the SaaS super admin to Derayah as super_admin (for role detection)
*/

DO $$
DECLARE
  v_company_id uuid;
  v_company_admin_user_id uuid;
  v_super_admin_user_id uuid;
BEGIN
  -- Ensure Derayah company exists
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';

  IF v_company_id IS NULL THEN
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
    )
    VALUES (
      gen_random_uuid(),
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
    )
    RETURNING id INTO v_company_id;
  END IF;

  -- Ensure company admin auth user exists (admin@derayah.com)
  SELECT id INTO v_company_admin_user_id
  FROM auth.users
  WHERE email = 'admin@derayah.com';

  IF v_company_admin_user_id IS NULL THEN
    v_company_admin_user_id := gen_random_uuid();

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
    )
    VALUES (
      v_company_admin_user_id,
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
      '{"name":"Company Admin"}'::jsonb,
      false,
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

    INSERT INTO auth.identities (
      provider_id,
      user_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    )
    VALUES (
      'admin@derayah.com',
      v_company_admin_user_id,
      jsonb_build_object(
        'sub', v_company_admin_user_id,
        'email', 'admin@derayah.com',
        'email_verified', true,
        'phone_verified', false
      ),
      'email',
      now(),
      now(),
      now()
    );
  ELSE
    UPDATE auth.users
    SET encrypted_password = crypt('Admin123!', gen_salt('bf', 10)),
        email_confirmed_at = COALESCE(email_confirmed_at, now()),
        updated_at = now()
    WHERE id = v_company_admin_user_id;
  END IF;

  -- Ensure SaaS super admin auth user exists (superadmin@derayah.com)
  SELECT id INTO v_super_admin_user_id
  FROM auth.users
  WHERE email = 'superadmin@derayah.com';

  IF v_super_admin_user_id IS NULL THEN
    v_super_admin_user_id := gen_random_uuid();

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
    )
    VALUES (
      v_super_admin_user_id,
      '00000000-0000-0000-0000-000000000000',
      'superadmin@derayah.com',
      crypt('Superadmin123!', gen_salt('bf', 10)),
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
      '{"name":"SaaS Super Admin"}'::jsonb,
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

    INSERT INTO auth.identities (
      provider_id,
      user_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    )
    VALUES (
      'superadmin@derayah.com',
      v_super_admin_user_id,
      jsonb_build_object(
        'sub', v_super_admin_user_id,
        'email', 'superadmin@derayah.com',
        'email_verified', true,
        'phone_verified', false
      ),
      'email',
      now(),
      now(),
      now()
    );
  ELSE
    UPDATE auth.users
    SET encrypted_password = crypt('Superadmin123!', gen_salt('bf', 10)),
        email_confirmed_at = COALESCE(email_confirmed_at, now()),
        updated_at = now()
    WHERE id = v_super_admin_user_id;
  END IF;

  -- Link admin@derayah.com to Derayah company as company_admin
  INSERT INTO company_users (company_id, user_id, role, permissions, is_active)
  VALUES (
    v_company_id,
    v_company_admin_user_id,
    'company_admin',
    jsonb_build_object(
      'dashboard', true,
      'users', true,
      'employees', true,
      'ltip_pools', true,
      'plans', true,
      'vesting_schedules', true,
      'vesting_events', true,
      'transfers', true,
      'performance_metrics', true,
      'grants', true,
      'documents', true,
      'cap_table', true,
      'portfolio', true,
      'settings', true
    ),
    true
  )
  ON CONFLICT (company_id, user_id) DO UPDATE
  SET role = EXCLUDED.role,
      permissions = COALESCE(company_users.permissions, '{}'::jsonb)
        || COALESCE(EXCLUDED.permissions, '{}'::jsonb),
      is_active = true;

  -- Link superadmin@derayah.com as super_admin (needed for role detection)
  INSERT INTO company_users (company_id, user_id, role, permissions, is_active)
  VALUES (
    v_company_id,
    v_super_admin_user_id,
    'super_admin',
    jsonb_build_object(
      'dashboard', true
    ),
    true
  )
  ON CONFLICT (company_id, user_id) DO UPDATE
  SET role = EXCLUDED.role,
      permissions = COALESCE(company_users.permissions, '{}'::jsonb)
        || COALESCE(EXCLUDED.permissions, '{}'::jsonb),
      is_active = true;

  -- Set company admin reference on the company
  UPDATE companies
  SET admin_user_id = v_company_admin_user_id,
      updated_at = now()
  WHERE id = v_company_id;
END;
$$;

