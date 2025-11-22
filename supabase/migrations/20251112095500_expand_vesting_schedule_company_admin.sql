/*
  # Expand Vesting Schedule Permissions for Company Admins

  Ensures self-service company_admin users can create and manage vesting schedule
  templates during onboarding and beyond.
*/
DO $$
BEGIN
  DROP POLICY IF EXISTS "Admins can insert vesting schedules" ON vesting_schedules;
  CREATE POLICY "Admins can insert vesting schedules"
    ON vesting_schedules FOR INSERT
    TO authenticated
    WITH CHECK (
      company_id IN (
        SELECT company_id
        FROM company_users
        WHERE user_id = auth.uid()
          AND role IN ('super_admin', 'company_admin', 'hr_admin', 'finance_admin')
      )
    );

  DROP POLICY IF EXISTS "Admins can update vesting schedules" ON vesting_schedules;
  CREATE POLICY "Admins can update vesting schedules"
    ON vesting_schedules FOR UPDATE
    TO authenticated
    USING (
      company_id IN (
        SELECT company_id
        FROM company_users
        WHERE user_id = auth.uid()
          AND role IN ('super_admin', 'company_admin', 'hr_admin', 'finance_admin')
      )
    )
    WITH CHECK (
      company_id IN (
        SELECT company_id
        FROM company_users
        WHERE user_id = auth.uid()
          AND role IN ('super_admin', 'company_admin', 'hr_admin', 'finance_admin')
      )
    );
END;
$$;

