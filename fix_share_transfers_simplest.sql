-- SIMPLEST FIX: share_transfers INSERT Policy
-- Use direct EXISTS checks without functions
-- Since RLS on portfolios already restricts access, if user can see portfolios, they can create transfers

-- Step 1: Drop all existing INSERT policies
DROP POLICY IF EXISTS "Company users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Authenticated users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Test: Company users only" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow authenticated inserts" ON share_transfers;

-- Step 2: Create the simplest possible policy
-- Just check that portfolios exist and belong to the same company
-- RLS on portfolios will ensure users can only see portfolios they have access to
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

-- Step 3: Verify the policy was created
SELECT 
  '=== VERIFICATION: share_transfers INSERT policy ===' as info;

SELECT 
  policyname,
  cmd,
  CASE 
    WHEN with_check IS NOT NULL THEN '✅ Policy has WITH CHECK clause'
    ELSE '❌ No WITH CHECK'
  END as status,
  substring(with_check::text, 1, 300) as policy_preview
FROM pg_policies
WHERE tablename = 'share_transfers'
AND cmd = 'INSERT';

-- Step 4: Test if we can see portfolios (this simulates what the policy will do)
SELECT 
  '=== TEST: Can we see portfolios? ===' as info,
  COUNT(*) as portfolio_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see portfolios - Policy should work'
    ELSE '❌ Cannot see portfolios - RLS is blocking'
  END as status
FROM portfolios
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
AND (
  portfolio_type = 'company_reserved' AND employee_id IS NULL
  OR portfolio_type = 'employee_vested'
);

