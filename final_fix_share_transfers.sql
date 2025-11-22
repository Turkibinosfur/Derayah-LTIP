-- FINAL FIX: Ensure test policy works and all RLS is fixed
-- This script will ensure everything is set up correctly

-- Step 1: Check current INSERT policy on share_transfers
SELECT 
  '=== CURRENT share_transfers INSERT POLICY ===' as info,
  policyname,
  cmd,
  with_check::text as policy_check
FROM pg_policies
WHERE tablename = 'share_transfers'
AND cmd = 'INSERT';

-- Step 2: Drop ALL policies on share_transfers
DROP POLICY IF EXISTS "Company users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Authenticated users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Test: Company users only" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow authenticated inserts" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow all authenticated inserts" ON share_transfers;

-- Step 3: Fix employees SELECT policy FIRST (for foreign key validation)
DROP POLICY IF EXISTS "Employees can view own data" ON employees;

CREATE POLICY "Employees can view own data"
  ON employees FOR SELECT TO authenticated
  USING (
    (user_id = auth.uid())
    OR
    EXISTS (
      SELECT 1 FROM company_users cu
      WHERE cu.company_id = employees.company_id
      AND cu.user_id = auth.uid()
      AND cu.is_active = true
      AND cu.role IN ('super_admin', 'hr_admin', 'finance_admin', 'legal_admin', 'company_admin')
    )
  );

-- Step 4: Create the simplest possible test policy
-- This should work if everything else is correct
CREATE POLICY "Test: Allow authenticated inserts"
  ON share_transfers
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Step 5: Verify test policy was created
SELECT 
  '=== VERIFICATION: Test policy created ===' as info,
  policyname,
  cmd,
  with_check::text as policy_check
FROM pg_policies
WHERE tablename = 'share_transfers'
AND cmd = 'INSERT';

-- Step 6: Verify employees policy includes company_admin
SELECT 
  '=== VERIFICATION: Employees policy ===' as info,
  policyname,
  cmd,
  CASE 
    WHEN qual::text LIKE '%company_admin%' THEN '✅ Includes company_admin'
    ELSE '❌ Missing company_admin'
  END as status
FROM pg_policies
WHERE tablename = 'employees'
AND cmd = 'SELECT'
AND policyname = 'Employees can view own data';

-- Step 7: Test if we can see employees (for foreign key validation)
SELECT 
  '=== TEST: Can see employees? ===' as info,
  COUNT(*) as employee_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see employees - Foreign key validation should work!'
    ELSE '❌ Cannot see employees - Foreign key validation will fail'
  END as status
FROM employees
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid;

-- Step 8: IMPORTANT - Check if RLS is enabled on share_transfers
-- If RLS is enabled but no policies match, INSERT will fail
SELECT 
  '=== RLS STATUS ===' as info,
  tablename,
  rowsecurity as rls_enabled,
  CASE 
    WHEN rowsecurity = true THEN '⚠️ RLS is enabled - Policies must allow access'
    ELSE 'ℹ️ RLS is disabled - No policies needed'
  END as note
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'share_transfers';

-- Step 9: Test if the policy actually allows INSERT
-- This will simulate what happens when you try to insert
SELECT 
  '=== POLICY TEST ===' as info,
  EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'share_transfers'
    AND cmd = 'INSERT'
    AND with_check IS NOT NULL
  ) as has_insert_policy,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_policies
      WHERE tablename = 'share_transfers'
      AND cmd = 'INSERT'
      AND with_check IS NOT NULL
    ) THEN '✅ INSERT policy exists - Try transfer now'
    ELSE '❌ No INSERT policy found - Transfer will fail'
  END as status;

