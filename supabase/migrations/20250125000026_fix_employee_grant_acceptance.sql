/*
  Fix Employee Grant Acceptance Issue
  
  Problem: Employees cannot update their own grants to accept contracts because there's no RLS policy
  that allows employees to update grants. The current policies only allow company users and HR admins
  to update grants, but employees need to be able to update their own grants for contract acceptance.
  
  Solution: Add a specific RLS policy that allows employees to update their own grants for contract acceptance.
*/

-- First, let's check the current grants policies
SELECT 
  'CURRENT GRANTS POLICIES' as info,
  policyname, 
  cmd, 
  roles, 
  qual, 
  with_check
FROM pg_policies 
WHERE tablename = 'grants'
ORDER BY policyname;

-- Add a policy that allows employees to update their own grants for contract acceptance
CREATE POLICY "Employees can accept their own grants"
  ON grants FOR UPDATE TO authenticated
  USING (
    employee_id IN (
      SELECT id FROM employees WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    employee_id IN (
      SELECT id FROM employees WHERE user_id = auth.uid()
    )
  );

-- Also add a policy for employees to view their own grants (if not already exists)
CREATE POLICY "Employees can view their own grants"
  ON grants FOR SELECT TO authenticated
  USING (
    employee_id IN (
      SELECT id FROM employees WHERE user_id = auth.uid()
    )
  );

-- Test the fix by checking if the specific grant exists and is accessible
SELECT 
  'TESTING GRANT ACCESS' as info,
  g.id,
  g.grant_number,
  g.status,
  g.employee_acceptance_at,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id
FROM grants g
JOIN employees e ON g.employee_id = e.id
WHERE g.grant_number = 'GR-20251025-000005';

-- Check if there are any grants with pending signature status
SELECT 
  'PENDING SIGNATURE GRANTS' as info,
  g.id,
  g.grant_number,
  g.status,
  g.employee_acceptance_at,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id
FROM grants g
JOIN employees e ON g.employee_id = e.id
WHERE g.status = 'pending_signature'
ORDER BY g.created_at DESC;

-- Verify the new policies are in place
SELECT 
  'UPDATED GRANTS POLICIES' as info,
  policyname, 
  cmd, 
  roles, 
  qual, 
  with_check
FROM pg_policies 
WHERE tablename = 'grants'
ORDER BY policyname;
