/*
  # Fix Vesting Schedules DELETE Policy Conflict

  There are old DELETE policies that reference grant_id (which doesn't exist
  in the new vesting_schedules table structure). This migration drops all
  conflicting DELETE policies and ensures only the correct one exists.
*/

DO $$
BEGIN
  -- Drop ALL existing DELETE policies on vesting_schedules
  -- This ensures we start clean and avoid conflicts
  DROP POLICY IF EXISTS "Company users can delete vesting schedules" ON vesting_schedules;
  DROP POLICY IF EXISTS "Admins can delete vesting schedules" ON vesting_schedules;
  DROP POLICY IF EXISTS "Users can delete vesting schedules" ON vesting_schedules;

  RAISE NOTICE 'Dropped all existing DELETE policies on vesting_schedules';

  -- Create the correct DELETE policy using company_id
  -- This matches the new table structure and allows admins to delete schedules
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

  RAISE NOTICE 'Created new DELETE policy for vesting_schedules using company_id';

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error fixing DELETE policies: %', SQLERRM;
END;
$$;

