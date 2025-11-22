-- FINAL FIX: Use direct portfolio checks in policy (no function)
-- Since portfolios are visible, we can check them directly in WITH CHECK
-- This avoids SECURITY DEFINER function issues in policy context

-- Step 1: Drop all existing policies and functions
DROP POLICY IF EXISTS "Company users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Authenticated users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Test: Company users only" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow authenticated inserts" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow all authenticated inserts" ON share_transfers;

-- Step 2: Ensure RLS is enabled
ALTER TABLE share_transfers ENABLE ROW LEVEL SECURITY;

-- Step 3: Create simple policy with direct portfolio checks
-- Since portfolios are visible to company_admin, this should work
CREATE POLICY "Company users can create transfers"
  ON share_transfers
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Both portfolios must exist and belong to the same company
    -- Direct EXISTS check (no function) - should work since portfolios are visible
    EXISTS (
      SELECT 1 FROM portfolios
      WHERE id = share_transfers.from_portfolio_id
      AND company_id = share_transfers.company_id
    )
    AND EXISTS (
      SELECT 1 FROM portfolios
      WHERE id = share_transfers.to_portfolio_id
      AND company_id = share_transfers.company_id
    )
  );

-- Step 4: Verification
SELECT 
  '=== VERIFICATION: RLS Status ===' as info,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'share_transfers';

SELECT 
  '=== VERIFICATION: INSERT Policy ===' as info,
  policyname,
  cmd,
  with_check::text as policy_check
FROM pg_policies
WHERE tablename = 'share_transfers'
AND cmd = 'INSERT';

-- Step 5: Test if we can see portfolios (should work)
SELECT 
  '=== TEST: Can see portfolios? ===' as info,
  COUNT(*) as portfolio_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see portfolios - Direct check should work!'
    ELSE '❌ Cannot see portfolios - Direct check will fail'
  END as status
FROM portfolios
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid;

-- Step 6: Find the specific portfolios
SELECT 
  '=== SPECIFIC PORTFOLIOS ===' as info,
  id as portfolio_id,
  portfolio_number,
  portfolio_type,
  company_id,
  employee_id
FROM portfolios
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
AND (
  portfolio_number = 'PORT-COMPANY-RESERVED-b7c082c7-79ff-4a62-8c79-a2b2a08110b1'
  OR portfolio_number = 'PORT-EMPLOYEE-EMP-2025-007'
);

