-- TEST: Verify policy checks work in the same context as the policy
-- This simulates what the policy will check during INSERT

-- Step 1: Test the exact EXISTS check that the policy uses
SELECT 
  '=== TEST: Policy EXISTS Check ===' as info,
  EXISTS (
    SELECT 1 FROM portfolios
    WHERE id = (SELECT id FROM portfolios WHERE portfolio_type = 'company_reserved' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' AND employee_id IS NULL LIMIT 1)
    AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
  ) as from_portfolio_exists,
  EXISTS (
    SELECT 1 FROM portfolios
    WHERE id = (SELECT id FROM portfolios WHERE portfolio_type = 'employee_vested' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' LIMIT 1)
    AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
  ) as to_portfolio_exists;

-- Step 2: Check if policy was created correctly
SELECT 
  '=== CURRENT POLICY ===' as info,
  policyname,
  cmd,
  with_check::text as policy_definition
FROM pg_policies
WHERE tablename = 'share_transfers'
AND cmd = 'INSERT';

-- Step 3: Try to manually execute the policy check (simulate what happens during INSERT)
-- Get the actual portfolio IDs
WITH portfolio_ids AS (
  SELECT 
    (SELECT id FROM portfolios WHERE portfolio_type = 'company_reserved' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' AND employee_id IS NULL LIMIT 1) as from_id,
    (SELECT id FROM portfolios WHERE portfolio_type = 'employee_vested' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' LIMIT 1) as to_id,
    'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid as company_id
)
SELECT 
  '=== MANUAL POLICY CHECK ===' as info,
  -- Simulate the policy checks
  (
    EXISTS (
      SELECT 1 FROM portfolios
      WHERE id = portfolio_ids.from_id
      AND company_id = portfolio_ids.company_id
    )
    AND
    EXISTS (
      SELECT 1 FROM portfolios
      WHERE id = portfolio_ids.to_id
      AND company_id = portfolio_ids.company_id
    )
    AND
    (
      SELECT company_id FROM portfolios WHERE id = portfolio_ids.from_id
    ) = (
      SELECT company_id FROM portfolios WHERE id = portfolio_ids.to_id
    )
  ) as policy_check_result,
  CASE 
    WHEN (
      EXISTS (
        SELECT 1 FROM portfolios
        WHERE id = portfolio_ids.from_id
        AND company_id = portfolio_ids.company_id
      )
      AND
      EXISTS (
        SELECT 1 FROM portfolios
        WHERE id = portfolio_ids.to_id
        AND company_id = portfolio_ids.company_id
      )
      AND
      (
        SELECT company_id FROM portfolios WHERE id = portfolio_ids.from_id
      ) = (
        SELECT company_id FROM portfolios WHERE id = portfolio_ids.to_id
      )
    ) THEN '✅ Policy check PASSES - Transfer should work'
    ELSE '❌ Policy check FAILS - Check why'
  END as status
FROM portfolio_ids;

