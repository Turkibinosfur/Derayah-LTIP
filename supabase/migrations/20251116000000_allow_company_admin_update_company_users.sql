/*
  # Allow Company Admin to Update Company Users
  
  Company admin users should be able to update company_users records,
  including permissions, to manage their team members.
  
  This updates the RLS policy to allow both super_admin and company_admin
  users to update company_users records.
  
  Note: We use a helper function with RLS bypass to avoid infinite recursion.
*/

-- Create a helper function to check if user is admin for a company
-- This function bypasses RLS to avoid infinite recursion
CREATE OR REPLACE FUNCTION public.is_admin_for_company(p_company_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
SET row_security = off
AS $$
DECLARE
  v_is_super_admin boolean;
  v_is_company_admin boolean;
BEGIN
  -- Check for super_admin via membership table (no RLS on this table)
  SELECT EXISTS (
    SELECT 1
    FROM company_super_admin_memberships m
    WHERE m.company_id = p_company_id
      AND m.user_id = auth.uid()
  ) INTO v_is_super_admin;
  
  IF v_is_super_admin THEN
    RETURN true;
  END IF;
  
  -- Check for company_admin by querying company_users
  -- row_security = off ensures RLS is bypassed
  SELECT EXISTS (
    SELECT 1
    FROM company_users cu
    WHERE cu.company_id = p_company_id
      AND cu.user_id = auth.uid()
      AND cu.role = 'company_admin'
      AND cu.is_active = true
  ) INTO v_is_company_admin;
  
  RETURN v_is_company_admin;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.is_admin_for_company(uuid) TO authenticated;

-- Drop the existing UPDATE policy
DROP POLICY IF EXISTS "Super admins can update company users" ON company_users;

-- Create a new policy that allows both super_admin and company_admin to update
-- The function uses SECURITY DEFINER to bypass RLS when checking permissions
CREATE POLICY "Admins can update company users"
  ON company_users
  FOR UPDATE
  TO authenticated
  USING (
    public.is_admin_for_company(company_users.company_id)
  );

