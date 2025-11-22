/*
  # Add DELETE Policy for Vesting Schedules

  Allows company_admin and other admin roles to delete vesting schedules.
  Milestones will be automatically deleted via CASCADE constraint when the
  schedule is deleted.
*/

DO $$
BEGIN
  -- Create DELETE policy for vesting_schedules
  -- This allows admins to delete schedules, and CASCADE will handle milestone deletion
  CREATE POLICY "Admins can delete vesting schedules"
    ON vesting_schedules FOR DELETE
    TO authenticated
    USING (
      company_id IN (
        SELECT company_id
        FROM company_users
        WHERE user_id = auth.uid()
          AND role IN ('super_admin', 'company_admin', 'hr_admin', 'finance_admin')
      )
    );

  RAISE NOTICE 'Added DELETE policy for vesting_schedules';
EXCEPTION
  WHEN duplicate_object THEN
    RAISE NOTICE 'DELETE policy already exists for vesting_schedules';
  WHEN OTHERS THEN
    RAISE NOTICE 'Error creating DELETE policy: %', SQLERRM;
END;
$$;

