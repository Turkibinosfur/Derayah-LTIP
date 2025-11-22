/*
  # Realign Derayah Company User Assignments

  Ensures the seeded Derayah admin accounts are correctly linked to the
  Derayah Financial company after the SaaS role split and that they retain
  full module permissions.

  - Upserts company_users entries for:
      • admin@derayah.com       → company_admin with full access
      • superadmin@derayah.com  → super_admin with dashboard access
      • HR@derayah.com          → hr_admin with operational access
  - Keeps existing permission flags by merging instead of replacing.
  - Re-applies companies.admin_user_id when possible.
*/

DO $$
DECLARE
  v_company_id uuid;
  v_admin_user_id uuid;
  v_super_admin_user_id uuid;
  v_hr_user_id uuid;
BEGIN
  -- Locate the Derayah Financial company
  SELECT id
  INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial'
  ORDER BY created_at
  LIMIT 1;

  IF v_company_id IS NULL THEN
    RAISE NOTICE 'Derayah Financial company not found; skipping realignment.';
    RETURN;
  END IF;

  -- Fetch seeded auth users if they exist
  SELECT id INTO v_admin_user_id
  FROM auth.users
  WHERE email = 'admin@derayah.com';

  SELECT id INTO v_super_admin_user_id
  FROM auth.users
  WHERE email = 'superadmin@derayah.com';

  SELECT id INTO v_hr_user_id
  FROM auth.users
  WHERE email = 'HR@derayah.com';

  -- Ensure admin@derayah.com is the configured company admin
  IF v_admin_user_id IS NOT NULL THEN
    INSERT INTO company_users (company_id, user_id, role, permissions, is_active)
    VALUES (
      v_company_id,
      v_admin_user_id,
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
    SET
      role = 'company_admin',
      permissions = COALESCE(company_users.permissions, '{}'::jsonb)
        || COALESCE(EXCLUDED.permissions, '{}'::jsonb),
      is_active = true,
      updated_at = now();

    -- Ensure the company references this admin
    UPDATE companies
    SET admin_user_id = v_admin_user_id,
        updated_at = now()
    WHERE id = v_company_id
      AND (admin_user_id IS NULL OR admin_user_id <> v_admin_user_id);
  ELSE
    RAISE NOTICE 'admin@derayah.com auth user not found; skipping company admin link.';
  END IF;

  -- Ensure HR admin mapping retains module access
  IF v_hr_user_id IS NOT NULL THEN
    INSERT INTO company_users (company_id, user_id, role, permissions, is_active)
    VALUES (
      v_company_id,
      v_hr_user_id,
      'hr_admin',
      jsonb_build_object(
        'dashboard', true,
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
        'portfolio', true
      ),
      true
    )
    ON CONFLICT (company_id, user_id) DO UPDATE
    SET
      role = 'hr_admin',
      permissions = COALESCE(company_users.permissions, '{}'::jsonb)
        || COALESCE(EXCLUDED.permissions, '{}'::jsonb),
      is_active = true,
      updated_at = now();
  END IF;

  -- Ensure SaaS super admin entry remains present for role detection
  IF v_super_admin_user_id IS NOT NULL THEN
    INSERT INTO company_users (company_id, user_id, role, permissions, is_active)
    VALUES (
      v_company_id,
      v_super_admin_user_id,
      'super_admin',
      jsonb_build_object('dashboard', true),
      true
    )
    ON CONFLICT (company_id, user_id) DO UPDATE
    SET
      role = 'super_admin',
      permissions = COALESCE(company_users.permissions, '{}'::jsonb)
        || COALESCE(EXCLUDED.permissions, '{}'::jsonb),
      is_active = true,
      updated_at = now();
  END IF;
END;
$$;



