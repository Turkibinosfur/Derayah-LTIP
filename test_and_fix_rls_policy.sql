-- TEST AND FIX: Check current policy state and fix if needed

-- Step 1: Check current INSERT policy
SELECT 
  '=== CURRENT INSERT POLICY ===' as info,
  policyname,
  cmd,
  with_check::text as policy_check
FROM pg_policies
WHERE tablename = 'share_transfers'
AND cmd = 'INSERT';

-- Step 2: Check if the SECURITY DEFINER function exists
SELECT 
  '=== FUNCTION CHECK ===' as info,
  proname as function_name,
  CASE 
    WHEN prosecdef = true THEN '✅ SECURITY DEFINER'
    ELSE '❌ Not SECURITY DEFINER'
  END as security_definer_status,
  pg_get_functiondef(oid) as function_definition
FROM pg_proc
WHERE proname = 'check_user_company_access';

-- Step 3: Test the function directly
SELECT 
  '=== TEST FUNCTION ===' as info,
  check_user_company_access(
    'b5d44a86-875f-42dc-970f-1a324318887c'::uuid,
    'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
  ) as has_access,
  CASE 
    WHEN check_user_company_access(
      'b5d44a86-875f-42dc-970f-1a324318887c'::uuid,
      'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
    ) = true THEN '✅ Function returns true'
    ELSE '❌ Function returns false - This is the problem!'
  END as status;

-- Step 4: Check company_users directly (to see if function should work)
SELECT 
  '=== DIRECT company_users CHECK ===' as info,
  COUNT(*) as count,
  role,
  is_active
FROM company_users
WHERE user_id = 'b5d44a86-875f-42dc-970f-1a324318887c'::uuid
AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
GROUP BY role, is_active;

-- Step 5: Drop the policy FIRST (it depends on the function)
DROP POLICY IF EXISTS "Company users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Authenticated users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Test: Company users only" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow authenticated inserts" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow all authenticated inserts" ON share_transfers;

-- Step 6: Now drop and recreate the function with better error handling
DROP FUNCTION IF EXISTS check_user_company_access(uuid, uuid);

CREATE OR REPLACE FUNCTION check_user_company_access(
  p_user_id uuid,
  p_company_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
  v_has_access boolean;
  v_count integer;
BEGIN
  -- Check if user has access to company (bypass RLS with SECURITY DEFINER)
  SELECT COUNT(*) INTO v_count
  FROM company_users
  WHERE user_id = p_user_id
  AND company_id = p_company_id
  AND is_active = true
  AND role IN ('super_admin', 'hr_admin', 'finance_admin', 'legal_admin', 'company_admin');
  
  v_has_access := (v_count > 0);
  
  RETURN v_has_access;
END;
$$;

-- Step 7: Grant execute permission
GRANT EXECUTE ON FUNCTION check_user_company_access(uuid, uuid) TO authenticated;

-- Step 8: Recreate the policy with the function
DROP POLICY IF EXISTS "Company users can create transfers" ON share_transfers;

CREATE POLICY "Company users can create transfers"
  ON share_transfers
  FOR INSERT
  TO authenticated
  WITH CHECK (
    check_user_company_access(auth.uid(), share_transfers.company_id)
  );

-- Step 9: Test the function again after recreation
SELECT 
  '=== TEST FUNCTION (After Fix) ===' as info,
  check_user_company_access(
    'b5d44a86-875f-42dc-970f-1a324318887c'::uuid,
    'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
  ) as has_access,
  CASE 
    WHEN check_user_company_access(
      'b5d44a86-875f-42dc-970f-1a324318887c'::uuid,
      'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
    ) = true THEN '✅ Function works - Transfer should work now!'
    ELSE '❌ Function still returns false - Need to check company_users table'
  END as status;

-- Step 10: Verify policy is created
SELECT 
  '=== FINAL POLICY CHECK ===' as info,
  policyname,
  cmd,
  with_check::text as policy_check
FROM pg_policies
WHERE tablename = 'share_transfers'
AND cmd = 'INSERT';

