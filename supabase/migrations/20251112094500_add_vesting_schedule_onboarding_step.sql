/*
  # Add Vesting Schedule Step to Onboarding

  - Adds a dedicated onboarding flag for vesting schedule templates
  - Updates the onboarding completion function to account for the new step
*/

ALTER TABLE company_onboarding_progress
  ADD COLUMN IF NOT EXISTS has_vesting_schedule boolean DEFAULT false;

UPDATE company_onboarding_progress
SET has_vesting_schedule = COALESCE(has_vesting_schedule, false);

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
    has_vesting_schedule = CASE WHEN p_step = 'vesting_schedule' THEN true ELSE has_vesting_schedule END,
    has_plan = CASE WHEN p_step = 'plan' THEN true ELSE has_plan END,
    has_employee = CASE WHEN p_step = 'employee' THEN true ELSE has_employee END,
    has_grant = CASE WHEN p_step = 'grant' THEN true ELSE has_grant END,
    completed_at = CASE
      WHEN
        (CASE WHEN p_step = 'pool' THEN true ELSE has_pool END) AND
        (CASE WHEN p_step = 'vesting_schedule' THEN true ELSE has_vesting_schedule END) AND
        (CASE WHEN p_step = 'plan' THEN true ELSE has_plan END) AND
        (CASE WHEN p_step = 'employee' THEN true ELSE has_employee END) AND
        (CASE WHEN p_step = 'grant' THEN true ELSE has_grant END)
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
      has_vesting_schedule,
      has_plan,
      has_employee,
      has_grant,
      completed_at
    ) VALUES (
      v_company_id,
      p_step = 'pool',
      p_step = 'vesting_schedule',
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


