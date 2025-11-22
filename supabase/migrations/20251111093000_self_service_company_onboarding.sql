/*
  # Self-Service Company Onboarding

  Enables SaaS-style self-service registration for new companies and tracks onboarding progress.

  Features:
  - Tracks onboarding steps (ESOP pool, incentive plan, employees, grants)
  - RPC to create company metadata and primary admin after Supabase auth sign-up
  - RPC to mark onboarding steps complete
  - RLS policies to ensure company isolation
*/

-- 1. Onboarding progress table
CREATE TABLE IF NOT EXISTS company_onboarding_progress (
  company_id uuid PRIMARY KEY REFERENCES companies(id) ON DELETE CASCADE,
  has_pool boolean DEFAULT false,
  has_plan boolean DEFAULT false,
  has_employee boolean DEFAULT false,
  has_grant boolean DEFAULT false,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE company_onboarding_progress ENABLE ROW LEVEL SECURITY;

-- Helper to update updated_at
CREATE OR REPLACE FUNCTION set_company_onboarding_progress_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_company_onboarding_progress_updated_at ON company_onboarding_progress;
CREATE TRIGGER trg_company_onboarding_progress_updated_at
BEFORE UPDATE ON company_onboarding_progress
FOR EACH ROW
EXECUTE FUNCTION set_company_onboarding_progress_updated_at();

-- 2. RLS policies
DROP POLICY IF EXISTS "Company users can view onboarding progress" ON company_onboarding_progress;
DROP POLICY IF EXISTS "Company users can update onboarding progress" ON company_onboarding_progress;

CREATE POLICY "Company users can view onboarding progress"
  ON company_onboarding_progress
  FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
        AND is_active = true
    )
  );

CREATE POLICY "Company users can update onboarding progress"
  ON company_onboarding_progress
  FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
        AND is_active = true
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
        AND is_active = true
    )
  );

-- 3. RPC: self-service onboarding
CREATE OR REPLACE FUNCTION public.onboard_self_service_company(
  p_company_name_en text,
  p_company_name_ar text,
  p_phone text,
  p_user_id uuid
)
RETURNS TABLE (company_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_company_id uuid;
  v_company_name_ar text;
  v_temp_symbol text;
  v_metadata jsonb;
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Not authorized to onboard for another user';
  END IF;

  IF p_company_name_en IS NULL OR length(trim(p_company_name_en)) = 0 THEN
    RAISE EXCEPTION 'Company name (English) is required';
  END IF;

  v_company_name_ar := COALESCE(NULLIF(p_company_name_ar, ''), p_company_name_en);
  v_temp_symbol := left(regexp_replace(upper(p_company_name_en), '[^A-Z0-9]', '', 'g') || '-' || substr(gen_random_uuid()::text, 1, 6), 16);
  v_metadata := jsonb_build_object(
    'phone', COALESCE(NULLIF(p_phone, ''), null),
    'onboarding_status', 'in_progress',
    'source', 'self_service'
  );

  INSERT INTO companies (
    company_name_en,
    company_name_ar,
    tadawul_symbol,
    commercial_registration_number,
    verification_status,
    total_reserved_shares,
    available_shares,
    status,
    metadata
  ) VALUES (
    p_company_name_en,
    v_company_name_ar,
    v_temp_symbol,
    'TEMP-' || gen_random_uuid()::text,
    'pending',
    0,
    0,
    'active',
    v_metadata
  )
  RETURNING id INTO v_company_id;

  INSERT INTO company_users (
    company_id,
    user_id,
    role,
    is_active,
    permissions
  ) VALUES (
    v_company_id,
    p_user_id,
    'company_admin',
    true,
    jsonb_build_object(
      'is_company_owner', true,
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
    )
  )
  ON CONFLICT ON CONSTRAINT company_users_company_id_user_id_key DO UPDATE
    SET
      role = EXCLUDED.role,
      is_active = EXCLUDED.is_active,
      permissions = COALESCE(company_users.permissions, '{}'::jsonb)
        || EXCLUDED.permissions;

  UPDATE companies
    SET admin_user_id = p_user_id,
        updated_at = now()
    WHERE id = v_company_id;

  INSERT INTO company_onboarding_progress (company_id)
  VALUES (v_company_id)
  ON CONFLICT ON CONSTRAINT company_onboarding_progress_pkey DO NOTHING;

  RETURN QUERY SELECT v_company_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.onboard_self_service_company(text, text, text, uuid) TO authenticated;

-- 4. RPC: complete onboarding step
CREATE OR REPLACE FUNCTION public.complete_company_onboarding_step(
  p_step text
)
RETURNS company_onboarding_progress
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_company_id uuid;
  v_progress company_onboarding_progress%ROWTYPE;
BEGIN
  SELECT company_id
    INTO v_company_id
  FROM company_users
  WHERE user_id = auth.uid()
    AND is_active = true
  ORDER BY created_at ASC
  LIMIT 1;

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'No active company association found for user';
  END IF;

  UPDATE company_onboarding_progress
  SET
    has_pool = CASE WHEN p_step = 'pool' THEN true ELSE has_pool END,
    has_plan = CASE WHEN p_step = 'plan' THEN true ELSE has_plan END,
    has_employee = CASE WHEN p_step = 'employee' THEN true ELSE has_employee END,
    has_grant = CASE WHEN p_step = 'grant' THEN true ELSE has_grant END,
    completed_at = CASE
      WHEN (CASE WHEN p_step = 'pool' THEN true ELSE has_pool END)
        AND (CASE WHEN p_step = 'plan' THEN true ELSE has_plan END)
        AND (CASE WHEN p_step = 'employee' THEN true ELSE has_employee END)
        AND (CASE WHEN p_step = 'grant' THEN true ELSE has_grant END)
      THEN COALESCE(completed_at, now())
      ELSE NULL
    END,
    updated_at = now()
  WHERE company_id = v_company_id
  RETURNING * INTO v_progress;

  IF NOT FOUND THEN
    INSERT INTO company_onboarding_progress (
      company_id,
      has_pool,
      has_plan,
      has_employee,
      has_grant,
      completed_at
    ) VALUES (
      v_company_id,
      p_step = 'pool',
      p_step = 'plan',
      p_step = 'employee',
      p_step = 'grant',
      CASE WHEN p_step = 'grant' THEN now() ELSE NULL END
    )
    RETURNING * INTO v_progress;
  END IF;

  RETURN v_progress;
END;
$$;

GRANT EXECUTE ON FUNCTION public.complete_company_onboarding_step(text) TO authenticated;


