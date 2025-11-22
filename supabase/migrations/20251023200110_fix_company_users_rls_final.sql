/*
  # Fix Company Users RLS - Remove Recursive Policy

  ## Problem
  The "Users can view company user associations" policy still causes infinite recursion.
  It tries to query company_users to determine access to company_users.

  ## Solution
  Drop the recursive policy. Keep only the simple policy that checks user_id = auth.uid()
  which allows users to see their own company associations without recursion.

  ## Changes
  1. Drop the recursive "Users can view company user associations" policy
  2. Keep the simple "Users can view own company associations" policy
*/

-- Drop the recursive policy
DROP POLICY IF EXISTS "Users can view company user associations" ON company_users;

-- The "Users can view own company associations" policy is sufficient:
-- It allows users to see company_users records where user_id = auth.uid()
-- This is all that's needed for the dashboard queries to work
