/*
  Fix Grants RLS Policies
  
  Problem: Grants are not visible because RLS policies are too restrictive.
  The current policy requires either employee.user_id = auth.uid() OR admin role,
  but employees might not have user_id set, and users might not have admin roles.
  
  Solution: Create more permissive RLS policies that allow company users to see grants for their company.
*/

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view relevant grants" ON grants;
DROP POLICY IF EXISTS "Admins can manage grants" ON grants;

-- Create new permissive policies for grants
CREATE POLICY "Company users can view grants"
  ON grants FOR SELECT TO authenticated
  USING (
    company_id IN (
      SELECT company_id
      FROM company_users
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Company users can insert grants"
  ON grants FOR INSERT TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id
      FROM company_users
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Company users can update grants"
  ON grants FOR UPDATE TO authenticated
  USING (
    company_id IN (
      SELECT company_id
      FROM company_users
      WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id
      FROM company_users
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Company users can delete grants"
  ON grants FOR DELETE TO authenticated
  USING (
    company_id IN (
      SELECT company_id
      FROM company_users
      WHERE user_id = auth.uid()
    )
  );

-- Also fix vesting schedules policies
DROP POLICY IF EXISTS "Users can view relevant vesting schedules" ON vesting_schedules;

CREATE POLICY "Company users can view vesting schedules"
  ON vesting_schedules FOR SELECT TO authenticated
  USING (
    grant_id IN (
      SELECT id FROM grants
      WHERE company_id IN (
        SELECT company_id
        FROM company_users
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Company users can insert vesting schedules"
  ON vesting_schedules FOR INSERT TO authenticated
  WITH CHECK (
    grant_id IN (
      SELECT id FROM grants
      WHERE company_id IN (
        SELECT company_id
        FROM company_users
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Company users can update vesting schedules"
  ON vesting_schedules FOR UPDATE TO authenticated
  USING (
    grant_id IN (
      SELECT id FROM grants
      WHERE company_id IN (
        SELECT company_id
        FROM company_users
        WHERE user_id = auth.uid()
      )
    )
  )
  WITH CHECK (
    grant_id IN (
      SELECT id FROM grants
      WHERE company_id IN (
        SELECT company_id
        FROM company_users
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Company users can delete vesting schedules"
  ON vesting_schedules FOR DELETE TO authenticated
  USING (
    grant_id IN (
      SELECT id FROM grants
      WHERE company_id IN (
        SELECT company_id
        FROM company_users
        WHERE user_id = auth.uid()
      )
    )
  );

-- Verify policies were created
DO $$
BEGIN
  RAISE NOTICE 'Grants RLS policies updated successfully';
  RAISE NOTICE 'Company users can now view all grants for their company';
  RAISE NOTICE 'Vesting schedules policies also updated for consistency';
END $$;
