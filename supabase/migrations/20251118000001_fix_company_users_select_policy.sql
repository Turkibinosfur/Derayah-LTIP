/*
  # Fix Company Users SELECT Policy
  
  This fixes the issue where company admins can only see their own record.
  Now company admins can see all users in companies they manage.
*/

-- Drop the existing policy
DROP POLICY IF EXISTS "Users can view their company association" ON company_users;

-- Create new policy that allows:
-- 1. Users to see their own record
-- 2. Super admins to see all users in companies they manage
-- 3. Company admins to see all users in companies they manage
CREATE POLICY "Users can view their company association"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see their own record
    user_id = auth.uid()
    -- OR super admins can see all users in companies they manage
    OR EXISTS (
      SELECT 1
      FROM company_super_admin_memberships m
      WHERE m.company_id = company_users.company_id
        AND m.user_id = auth.uid()
    )
    -- OR company admins can see all users in companies they manage
    OR EXISTS (
      SELECT 1
      FROM company_admin_memberships m
      WHERE m.company_id = company_users.company_id
        AND m.user_id = auth.uid()
    )
  );

