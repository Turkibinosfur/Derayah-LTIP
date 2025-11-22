-- COMPREHENSIVE CHECK AND FIX: share_transfers INSERT Policy
-- This will check current state, clean up, and create a working policy

-- Step 1: Check all current policies on share_transfers
SELECT 
  '=== CURRENT POLICIES ON share_transfers ===' as info;

SELECT 
  policyname,
  cmd,
  qual::text as using_clause,
  with_check::text as with_check_clause
FROM pg_policies
WHERE tablename = 'share_transfers'
ORDER BY cmd, policyname;

-- Step 2: Drop ALL policies on share_transfers (clean slate)
DROP POLICY IF EXISTS "Company users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Authenticated users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Test: Company users only" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow authenticated inserts" ON share_transfers;

-- Step 3: Check if RLS is enabled
SELECT 
  '=== RLS STATUS ===' as info,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'share_transfers';

-- Step 4: Create a simple test policy first (to verify table works)
-- This allows any authenticated user to insert - just for testing
-- Drop it first to ensure clean state
DROP POLICY IF EXISTS "Test: Allow all authenticated inserts" ON share_transfers;

CREATE POLICY "Test: Allow all authenticated inserts"
  ON share_transfers
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Step 5: Verify test policy was created
SELECT 
  '=== TEST POLICY CREATED ===' as info,
  policyname,
  cmd,
  with_check::text as policy_check
FROM pg_policies
WHERE tablename = 'share_transfers'
AND cmd = 'INSERT';

-- Step 5.1: Check for triggers on share_transfers (might block inserts)
SELECT 
  '=== TRIGGERS ON share_transfers ===' as info;

SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'share_transfers'
ORDER BY trigger_name;

-- Step 5.2: Check for constraints on share_transfers (might block inserts)
SELECT 
  '=== CONSTRAINTS ON share_transfers ===' as info;

SELECT 
  constraint_name,
  constraint_type,
  table_name
FROM information_schema.table_constraints
WHERE table_name = 'share_transfers'
AND constraint_type IN ('CHECK', 'FOREIGN KEY', 'UNIQUE', 'NOT NULL')
ORDER BY constraint_type, constraint_name;

-- INSTRUCTIONS:
-- Now try the transfer. If it works with this test policy, then the issue is with the validation logic.
-- If it still fails, there's something else blocking (maybe triggers, constraints, etc.)

-- Step 6: If test policy works, create the real policy with validation
-- (Comment out until after testing)
/*
DROP POLICY IF EXISTS "Test: Allow all authenticated inserts" ON share_transfers;

CREATE POLICY "Company users can create transfers"
  ON share_transfers
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Check that from_portfolio exists and belongs to the company
    EXISTS (
      SELECT 1 FROM portfolios
      WHERE id = share_transfers.from_portfolio_id
      AND company_id = share_transfers.company_id
    )
    AND
    -- Check that to_portfolio exists and belongs to the company
    EXISTS (
      SELECT 1 FROM portfolios
      WHERE id = share_transfers.to_portfolio_id
      AND company_id = share_transfers.company_id
    )
    AND
    -- Ensure both portfolios belong to the same company
    (
      SELECT company_id FROM portfolios WHERE id = share_transfers.from_portfolio_id
    ) = (
      SELECT company_id FROM portfolios WHERE id = share_transfers.to_portfolio_id
    )
    AND
    -- If employee_id is provided, validate it belongs to the company
    (
      share_transfers.employee_id IS NULL
      OR EXISTS (
        SELECT 1 FROM employees
        WHERE id = share_transfers.employee_id
        AND company_id = share_transfers.company_id
      )
    )
    AND
    -- If grant_id is provided, validate it belongs to the company
    (
      share_transfers.grant_id IS NULL
      OR EXISTS (
        SELECT 1 FROM grants
        WHERE id = share_transfers.grant_id
        AND company_id = share_transfers.company_id
      )
    )
  );
*/

