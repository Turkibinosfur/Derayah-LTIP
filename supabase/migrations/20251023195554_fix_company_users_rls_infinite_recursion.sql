/*
  # Fix Company Users RLS Infinite Recursion

  ## Problem
  The "Super admins can manage company users" policy causes infinite recursion because it 
  queries the same table it's protecting, creating a circular dependency.

  ## Solution
  Split the policy into separate policies for SELECT, INSERT, UPDATE, and DELETE operations.
  The SELECT policy only checks if the user is associated with the company (no role check needed).
  Other operations check for super_admin role but don't conflict with SELECT.

  ## Changes
  1. Drop the problematic policy
  2. Create separate policies for each operation type
*/

-- Drop the problematic policy
DROP POLICY IF EXISTS "Super admins can manage company users" ON company_users;

-- Allow users to view company_users records for their own companies
-- This is separate from the "Users can view own company associations" policy
CREATE POLICY "Users can view company user associations"
  ON company_users FOR SELECT TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
    )
  );

-- Super admins can insert new company users
CREATE POLICY "Super admins can add company users"
  ON company_users FOR INSERT TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() AND role = 'super_admin'
    )
  );

-- Super admins can update company users
CREATE POLICY "Super admins can update company users"
  ON company_users FOR UPDATE TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() AND role = 'super_admin'
    )
  );

-- Super admins can delete company users
CREATE POLICY "Super admins can delete company users"
  ON company_users FOR DELETE TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() AND role = 'super_admin'
    )
  );
