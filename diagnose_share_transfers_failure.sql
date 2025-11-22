-- DETAILED DIAGNOSTIC: Find out which function is failing
-- Run this to see which check is causing the policy to fail

-- Step 1: Test check_company_user_access function individually
SELECT 
  '=== DIAGNOSTIC: Company User Access ===' as step,
  auth.uid() as current_user_id,
  'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid as company_id,
  check_company_user_access(
    auth.uid(),
    'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
  ) as function_result,
  CASE 
    WHEN check_company_user_access(
      auth.uid(),
      'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
    ) THEN '✅ PASS'
    ELSE '❌ FAIL - User does NOT have access to company'
  END as status;

-- Step 2: Manually check company_users table (to see if record exists)
SELECT 
  '=== DIAGNOSTIC: Manual company_users Check ===' as step,
  user_id,
  company_id,
  role,
  is_active,
  CASE 
    WHEN user_id = auth.uid() AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid AND is_active = true THEN '✅ Record exists and is active'
    WHEN user_id = auth.uid() AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid AND is_active = false THEN '⚠️ Record exists but is NOT active'
    WHEN user_id = auth.uid() THEN '⚠️ User exists but wrong company'
    ELSE '❌ No record found'
  END as status
FROM company_users
WHERE user_id = auth.uid()
AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid;

-- Step 3: Test validate_share_transfer_data function individually
SELECT 
  '=== DIAGNOSTIC: Transfer Data Validation ===' as step,
  validate_share_transfer_data(
    'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid,
    (SELECT id FROM portfolios WHERE portfolio_type = 'company_reserved' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' AND employee_id IS NULL LIMIT 1),
    (SELECT id FROM portfolios WHERE portfolio_type = 'employee_vested' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' LIMIT 1),
    NULL::uuid,
    NULL::uuid
  ) as function_result,
  CASE 
    WHEN validate_share_transfer_data(
      'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid,
      (SELECT id FROM portfolios WHERE portfolio_type = 'company_reserved' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' AND employee_id IS NULL LIMIT 1),
      (SELECT id FROM portfolios WHERE portfolio_type = 'employee_vested' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' LIMIT 1),
      NULL::uuid,
      NULL::uuid
    ) THEN '✅ PASS'
    ELSE '❌ FAIL - Portfolios or data validation failed'
  END as status;

-- Step 4: Check portfolios exist (manual check)
SELECT 
  '=== DIAGNOSTIC: Portfolios Check ===' as step,
  id as portfolio_id,
  portfolio_type,
  company_id,
  employee_id,
  portfolio_number,
  CASE 
    WHEN portfolio_type = 'company_reserved' AND employee_id IS NULL THEN '✅ Company reserved portfolio found'
    WHEN portfolio_type = 'employee_vested' AND employee_id IS NOT NULL THEN '✅ Employee vested portfolio found'
    ELSE '⚠️ Unexpected portfolio'
  END as status
FROM portfolios
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
AND (
  (portfolio_type = 'company_reserved' AND employee_id IS NULL)
  OR portfolio_type = 'employee_vested'
)
ORDER BY portfolio_type, employee_id NULLS FIRST;

-- Step 5: Check if functions exist and are correct
SELECT 
  '=== DIAGNOSTIC: Functions Check ===' as step,
  routine_name,
  routine_type,
  CASE 
    WHEN routine_name = 'check_company_user_access' THEN '✅ Function exists'
    WHEN routine_name = 'validate_share_transfer_data' THEN '✅ Function exists'
    ELSE '⚠️ Unexpected function'
  END as status
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('check_company_user_access', 'validate_share_transfer_data')
ORDER BY routine_name;

-- Step 6: Check current policy definition
SELECT 
  '=== DIAGNOSTIC: Current Policy ===' as step,
  policyname,
  cmd,
  substring(with_check::text, 1, 300) as policy_check
FROM pg_policies
WHERE tablename = 'share_transfers'
AND cmd = 'INSERT';

-- Step 7: Test if SECURITY DEFINER is working by checking if we can see company_users
-- This will tell us if the function can bypass RLS
SELECT 
  '=== DIAGNOSTIC: SECURITY DEFINER Test ===' as step,
  COUNT(*) as company_users_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ SECURITY DEFINER can see company_users'
    ELSE '❌ SECURITY DEFINER CANNOT see company_users - RLS is blocking'
  END as status
FROM company_users
WHERE user_id = auth.uid()
AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
AND is_active = true;

