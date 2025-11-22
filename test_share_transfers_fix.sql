-- TEST SCRIPT: Verify share_transfers INSERT fix is working
-- Run this in Supabase SQL Editor to test the functions and policy

-- Step 1: Check if functions exist
SELECT 
  '=== STEP 1: Check Functions ===' as step,
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('validate_share_transfer_data', 'check_company_user_access')
ORDER BY routine_name;

-- Step 2: Test check_company_user_access function
SELECT 
  '=== STEP 2: Test Company User Access Function ===' as step,
  check_company_user_access(
    auth.uid(),
    'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
  ) as result,
  CASE 
    WHEN check_company_user_access(
      auth.uid(),
      'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
    ) THEN '✅ User has access to company'
    ELSE '❌ User does NOT have access to company'
  END as status;

-- Step 3: Test validate_share_transfer_data function
SELECT 
  '=== STEP 3: Test Transfer Data Validation Function ===' as step,
  validate_share_transfer_data(
    'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid,
    (SELECT id FROM portfolios WHERE portfolio_type = 'company_reserved' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' AND employee_id IS NULL LIMIT 1),
    (SELECT id FROM portfolios WHERE portfolio_type = 'employee_vested' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' LIMIT 1),
    NULL::uuid,
    NULL::uuid
  ) as result,
  CASE 
    WHEN validate_share_transfer_data(
      'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid,
      (SELECT id FROM portfolios WHERE portfolio_type = 'company_reserved' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' AND employee_id IS NULL LIMIT 1),
      (SELECT id FROM portfolios WHERE portfolio_type = 'employee_vested' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' LIMIT 1),
      NULL::uuid,
      NULL::uuid
    ) THEN '✅ Transfer data is valid'
    ELSE '❌ Transfer data is NOT valid'
  END as status;

-- Step 4: Check current policy
SELECT 
  '=== STEP 4: Check Current Policy ===' as step,
  policyname,
  cmd,
  with_check::text as policy_check
FROM pg_policies
WHERE tablename = 'share_transfers'
AND cmd = 'INSERT';

-- Step 5: Check if RLS is enabled on share_transfers
SELECT 
  '=== STEP 5: Check RLS Status ===' as step,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'share_transfers';

-- Step 6: Try to manually test the policy check (simulate what happens during INSERT)
-- This will show us if the policy check passes or fails
SELECT 
  '=== STEP 6: Simulate Policy Check ===' as step,
  check_company_user_access(
    auth.uid(),
    'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
  ) AND
  validate_share_transfer_data(
    'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid,
    (SELECT id FROM portfolios WHERE portfolio_type = 'company_reserved' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' AND employee_id IS NULL LIMIT 1),
    (SELECT id FROM portfolios WHERE portfolio_type = 'employee_vested' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' LIMIT 1),
    NULL::uuid,
    NULL::uuid
  ) as policy_check_result,
  CASE 
    WHEN (
      check_company_user_access(
        auth.uid(),
        'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
      ) AND
      validate_share_transfer_data(
        'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid,
        (SELECT id FROM portfolios WHERE portfolio_type = 'company_reserved' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' AND employee_id IS NULL LIMIT 1),
        (SELECT id FROM portfolios WHERE portfolio_type = 'employee_vested' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' LIMIT 1),
        NULL::uuid,
        NULL::uuid
      )
    ) THEN '✅ Policy check would PASS'
    ELSE '❌ Policy check would FAIL'
  END as status;

