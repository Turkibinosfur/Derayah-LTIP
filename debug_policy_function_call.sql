-- DEBUG: Check if the function works in policy context
-- The issue might be that auth.uid() in policy context is different

-- Step 1: Check current auth.uid() context
SELECT 
  '=== CURRENT AUTH CONTEXT ===' as info,
  auth.uid() as current_user_id,
  'b5d44a86-875f-42dc-970f-1a324318887c'::uuid as expected_user_id,
  CASE 
    WHEN auth.uid() = 'b5d44a86-875f-42dc-970f-1a324318887c'::uuid THEN '✅ auth.uid() matches'
    WHEN auth.uid() IS NULL THEN '❌ auth.uid() is NULL - Not authenticated!'
    ELSE '⚠️ auth.uid() does not match - Different user context'
  END as auth_status;

-- Step 2: Test function with auth.uid() directly
SELECT 
  '=== TEST FUNCTION WITH auth.uid() ===' as info,
  auth.uid() as user_id,
  'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid as company_id,
  check_user_company_access(
    auth.uid(),
    'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
  ) as function_result,
  CASE 
    WHEN check_user_company_access(
      auth.uid(),
      'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
    ) = true THEN '✅ Function returns true with auth.uid()'
    WHEN auth.uid() IS NULL THEN '❌ auth.uid() is NULL - Cannot check'
    ELSE '❌ Function returns false with auth.uid()'
  END as status;

-- Step 3: Check what the policy would evaluate to
-- Simulate the WITH CHECK clause
SELECT 
  '=== SIMULATE POLICY CHECK ===' as info,
  check_user_company_access(
    auth.uid(),
    'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
  ) as policy_would_allow,
  CASE 
    WHEN check_user_company_access(
      auth.uid(),
      'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
    ) = true THEN '✅ Policy would ALLOW insert'
    WHEN auth.uid() IS NULL THEN '❌ Policy would DENY (auth.uid() is NULL)'
    ELSE '❌ Policy would DENY insert'
  END as policy_result;

-- Step 4: If auth.uid() is NULL, we need a different approach
-- Check if we can access company_users at all
SELECT 
  '=== DIRECT company_users ACCESS ===' as info,
  COUNT(*) as company_user_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see company_users directly'
    ELSE '❌ Cannot see company_users - RLS is blocking!'
  END as access_status
FROM company_users
WHERE user_id = auth.uid()
AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid;

-- Step 5: If auth.uid() is NULL in SQL Editor, we need to use a different strategy
-- Let's create a policy that doesn't rely on auth.uid() working correctly
-- Instead, check if portfolios exist (we know we can see those)

