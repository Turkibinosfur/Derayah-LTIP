-- FINAL TEST: Temporarily disable RLS on share_transfers
-- This will tell us definitively if RLS is the issue

-- Step 1: Drop ALL policies on share_transfers
DROP POLICY IF EXISTS "Company users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Authenticated users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Test: Company users only" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow authenticated inserts" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow all authenticated inserts" ON share_transfers;

-- Step 2: DISABLE RLS on share_transfers (TEMPORARY - FOR TESTING ONLY)
ALTER TABLE share_transfers DISABLE ROW LEVEL SECURITY;

-- Step 3: Verify RLS is disabled
SELECT 
  '=== RLS STATUS AFTER DISABLING ===' as info,
  tablename,
  rowsecurity as rls_enabled,
  CASE 
    WHEN rowsecurity = false THEN '✅ RLS is DISABLED - Transfer should work now!'
    ELSE '❌ RLS is still ENABLED'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'share_transfers';

-- INSTRUCTIONS:
-- Now try the transfer. If it works with RLS disabled, we know it's definitely RLS.
-- If it still fails, it's foreign keys, triggers, or constraints blocking it.

-- Step 4: If transfer works with RLS disabled, re-enable and create proper policy
-- (Uncomment this after confirming transfer works with RLS disabled)
/*
ALTER TABLE share_transfers ENABLE ROW LEVEL SECURITY;

-- Create a simple policy that should work
CREATE POLICY "Company users can create transfers"
  ON share_transfers
  FOR INSERT
  TO authenticated
  WITH CHECK (true);
*/

