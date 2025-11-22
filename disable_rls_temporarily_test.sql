-- TEMPORARY TEST: Disable RLS on share_transfers to test if it's the issue
-- This will help us determine if RLS policies or foreign keys are the problem

-- Step 1: Check current RLS status
SELECT 
  '=== CURRENT RLS STATUS ===' as info,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'share_transfers';

-- Step 2: List all current policies
SELECT 
  '=== ALL CURRENT POLICIES ===' as info,
  policyname,
  cmd,
  qual::text as using_clause,
  with_check::text as with_check_clause
FROM pg_policies
WHERE tablename = 'share_transfers'
ORDER BY cmd, policyname;

-- Step 3: Drop ALL policies on share_transfers
DROP POLICY IF EXISTS "Company users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Authenticated users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Test: Company users only" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow authenticated inserts" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow all authenticated inserts" ON share_transfers;

-- Step 4: TEMPORARILY DISABLE RLS (FOR TESTING ONLY)
ALTER TABLE share_transfers DISABLE ROW LEVEL SECURITY;

-- Step 5: Verify RLS is disabled
SELECT 
  '=== RLS DISABLED ===' as info,
  tablename,
  rowsecurity as rls_enabled,
  CASE 
    WHEN rowsecurity = false THEN '✅ RLS is disabled - Try transfer now'
    ELSE '❌ RLS is still enabled'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'share_transfers';

-- INSTRUCTIONS:
-- 1. Try the transfer now with RLS disabled
-- 2. If it works, the issue is definitely RLS policies
-- 3. If it still fails, it's foreign keys, triggers, or constraints
-- 4. After testing, we'll re-enable RLS and fix the policies properly

-- Step 6: After testing, re-enable RLS (uncomment when ready)
/*
ALTER TABLE share_transfers ENABLE ROW LEVEL SECURITY;

-- Then create a proper policy that works
CREATE POLICY "Company users can create transfers"
  ON share_transfers
  FOR INSERT
  TO authenticated
  WITH CHECK (
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
*/

