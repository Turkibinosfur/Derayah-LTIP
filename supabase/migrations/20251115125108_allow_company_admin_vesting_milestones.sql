/*
  # Allow Company Admin to Create Vesting Milestones

  Updates RLS policies on vesting_milestones to allow company_admin users
  to create and manage vesting milestones, matching the permissions already
  granted for vesting_schedules.
*/

-- First, ensure company_admin is in the user_role enum if not already present
DO $$
BEGIN
  -- Try to add company_admin to the enum if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_enum 
    WHERE enumlabel = 'company_admin' 
    AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'user_role')
  ) THEN
    ALTER TYPE user_role ADD VALUE 'company_admin';
    RAISE NOTICE 'Added company_admin to user_role enum';
  ELSE
    RAISE NOTICE 'company_admin already exists in user_role enum';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    -- If enum already has the value or other error, just continue
    RAISE NOTICE 'company_admin enum value check completed: %', SQLERRM;
END;
$$;

-- Update vesting_milestones policies to include company_admin
DO $$
BEGIN
  -- Drop existing policy if it exists
  DROP POLICY IF EXISTS "Admins can manage milestones" ON vesting_milestones;

  -- Create updated policy with company_admin included
  CREATE POLICY "Admins can manage milestones"
    ON vesting_milestones FOR ALL
    TO authenticated
    USING (
      vesting_schedule_id IN (
        SELECT vs.id FROM vesting_schedules vs
        JOIN company_users cu ON cu.company_id = vs.company_id
        WHERE cu.user_id = auth.uid() 
        AND cu.role IN ('super_admin', 'company_admin', 'hr_admin', 'finance_admin')
      )
    )
    WITH CHECK (
      vesting_schedule_id IN (
        SELECT vs.id FROM vesting_schedules vs
        JOIN company_users cu ON cu.company_id = vs.company_id
        WHERE cu.user_id = auth.uid() 
        AND cu.role IN ('super_admin', 'company_admin', 'hr_admin', 'finance_admin')
      )
    );

  RAISE NOTICE 'Updated vesting_milestones policy to include company_admin';
END;
$$;

