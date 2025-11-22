/*
  # Fix Shareholders Insert Policy

  1. Changes
    - Drop the restrictive INSERT policy that only allows super_admin and finance_admin
    - Create a new INSERT policy that allows all authenticated company users to add shareholders
    
  2. Security
    - Users can only insert shareholders for their own company
    - Authentication is still required
*/

-- Drop the existing restrictive policy
DROP POLICY IF EXISTS "Company admins can insert shareholders" ON shareholders;

-- Create a new policy that allows all authenticated company users
CREATE POLICY "Company users can insert shareholders"
  ON shareholders
  FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id
      FROM company_users
      WHERE user_id = auth.uid()
    )
  );
