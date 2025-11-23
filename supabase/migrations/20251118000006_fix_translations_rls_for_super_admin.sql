/*
  # Fix Translations RLS Policy for Super Admin
  
  The translations table RLS policy is checking company_users for super_admin role,
  but super admins have been moved to company_super_admin_memberships.
  This migration updates the policy to check the correct table.
*/

-- Drop the old policy
DROP POLICY IF EXISTS "Only super_admin can manage translations" ON translations;

-- Create new policy that checks company_super_admin_memberships
CREATE POLICY "Only super_admin can manage translations"
  ON translations FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM company_super_admin_memberships m
      WHERE m.user_id = auth.uid()
    )
  );

