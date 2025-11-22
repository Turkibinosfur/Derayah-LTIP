-- DIAGNOSTIC: Check current RLS status and policies after re-enabling

-- Step 1: Check RLS status
SELECT 
  '=== RLS STATUS ===' as info,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'share_transfers';

-- Step 2: Check all policies on share_transfers
SELECT 
  '=== ALL share_transfers POLICIES ===' as info,
  policyname,
  cmd,
  qual::text as using_clause,
  with_check::text as with_check_clause
FROM pg_policies
WHERE tablename = 'share_transfers'
ORDER BY cmd, policyname;

-- Step 3: Check if we can see portfolios (the policy check)
SELECT 
  '=== CAN SEE PORTFOLIOS? ===' as info,
  COUNT(*) as portfolio_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see portfolios'
    ELSE '❌ Cannot see portfolios - Policy check will fail!'
  END as status
FROM portfolios
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid;

-- Step 4: Check specific portfolios that would be used in transfer
SELECT 
  '=== SPECIFIC PORTFOLIOS FOR TRANSFER ===' as info,
  id,
  portfolio_type,
  portfolio_number,
  company_id,
  employee_id,
  CASE 
    WHEN employee_id IS NULL THEN 'company_reserved'
    ELSE 'employee_vested'
  END as expected_type
FROM portfolios
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
AND (
  (portfolio_type = 'company_reserved' AND employee_id IS NULL)
  OR 
  portfolio_type = 'employee_vested'
)
ORDER BY portfolio_type, employee_id;

-- Step 5: Test the policy check manually (simulate what the policy does)
-- Replace these IDs with actual portfolio IDs from Step 4
SELECT 
  '=== TEST POLICY CHECK ===' as info,
  'Run this with actual portfolio IDs from above' as instruction;

-- Step 6: Check employees policy
SELECT 
  '=== EMPLOYEES POLICY ===' as info,
  policyname,
  qual::text as policy_condition,
  CASE 
    WHEN qual::text LIKE '%company_admin%' THEN '✅ Includes company_admin'
    ELSE '❌ Missing company_admin'
  END as status
FROM pg_policies
WHERE tablename = 'employees'
AND cmd = 'SELECT';

-- Step 7: Check grants policy
SELECT 
  '=== GRANTS POLICIES ===' as info,
  policyname,
  qual::text as policy_condition,
  CASE 
    WHEN qual::text LIKE '%company_admin%' THEN '✅ Includes company_admin'
    ELSE '⚠️ Check manually'
  END as status
FROM pg_policies
WHERE tablename = 'grants'
AND cmd = 'SELECT'
ORDER BY policyname;

-- Step 8: Check companies policy
SELECT 
  '=== COMPANIES POLICY ===' as info,
  policyname,
  qual::text as policy_condition,
  CASE 
    WHEN qual::text LIKE '%true%' OR qual::text IS NULL THEN '✅ Allows all authenticated'
    ELSE '⚠️ Check manually'
  END as status
FROM pg_policies
WHERE tablename = 'companies'
AND cmd = 'SELECT';

-- Step 9: Check portfolios policy
SELECT 
  '=== PORTFOLIOS POLICY ===' as info,
  policyname,
  qual::text as policy_condition,
  CASE 
    WHEN qual::text LIKE '%company_admin%' THEN '✅ Includes company_admin'
    ELSE '⚠️ Check manually'
  END as status
FROM pg_policies
WHERE tablename = 'portfolios'
AND cmd = 'SELECT'
ORDER BY policyname;

-- Step 10: Test if we can see employees (for foreign key validation)
SELECT 
  '=== CAN SEE EMPLOYEES? (For FK validation) ===' as info,
  COUNT(*) as employee_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see employees - FK validation should work'
    ELSE '❌ Cannot see employees - FK validation will fail!'
  END as status
FROM employees
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid;

-- Step 11: Test if we can see grants (for foreign key validation)
SELECT 
  '=== CAN SEE GRANTS? (For FK validation) ===' as info,
  COUNT(*) as grant_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see grants - FK validation should work'
    ELSE '❌ Cannot see grants - FK validation will fail!'
  END as status
FROM grants
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
LIMIT 1;

