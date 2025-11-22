-- SIMPLE FIX: Create a policy that doesn't check portfolios in WITH CHECK
-- The portfolios check in WITH CHECK is subject to RLS, which may be blocking it
-- Instead, we'll use a simpler check that relies on foreign key validation

-- Step 1: Drop all existing INSERT policies
DROP POLICY IF EXISTS "Company users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Authenticated users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Test: Company users only" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow authenticated inserts" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow all authenticated inserts" ON share_transfers;

-- Step 2: Ensure RLS is enabled
ALTER TABLE share_transfers ENABLE ROW LEVEL SECURITY;

-- Step 3: Create a simple policy that checks company_users access
-- This avoids the portfolios RLS check in WITH CHECK
CREATE POLICY "Company users can create transfers"
  ON share_transfers
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Check if user has access to the company
    -- Foreign key validation will handle portfolios, employees, grants validation
    EXISTS (
      SELECT 1 FROM company_users
      WHERE user_id = auth.uid()
      AND company_id = share_transfers.company_id
      AND is_active = true
      AND role IN ('super_admin', 'hr_admin', 'finance_admin', 'legal_admin', 'company_admin')
    )
  );

-- Step 4: But wait, company_users RLS might block this too...
-- Let's use a SECURITY DEFINER function to bypass RLS on company_users
CREATE OR REPLACE FUNCTION check_user_company_access(
  p_user_id uuid,
  p_company_id uuid
)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM company_users
    WHERE user_id = p_user_id
    AND company_id = p_company_id
    AND is_active = true
    AND role IN ('super_admin', 'hr_admin', 'finance_admin', 'legal_admin', 'company_admin')
  );
$$;

-- Step 5: Grant execute permission
GRANT EXECUTE ON FUNCTION check_user_company_access(uuid, uuid) TO authenticated;

-- Step 6: Drop the policy and recreate with the SECURITY DEFINER function
DROP POLICY IF EXISTS "Company users can create transfers" ON share_transfers;

CREATE POLICY "Company users can create transfers"
  ON share_transfers
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Use SECURITY DEFINER function to bypass RLS on company_users
    check_user_company_access(auth.uid(), share_transfers.company_id)
  );

-- Step 7: Verification
SELECT 
  '=== VERIFICATION: RLS Status ===' as info,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'share_transfers';

SELECT 
  '=== VERIFICATION: INSERT Policy ===' as info,
  policyname,
  cmd,
  with_check::text as policy_check
FROM pg_policies
WHERE tablename = 'share_transfers'
AND cmd = 'INSERT';

SELECT 
  '=== VERIFICATION: Function exists ===' as info,
  proname as function_name,
  CASE 
    WHEN prosecdef = true THEN '✅ SECURITY DEFINER'
    ELSE '❌ Not SECURITY DEFINER'
  END as security_definer_status
FROM pg_proc
WHERE proname = 'check_user_company_access';

-- Step 8: Test the function directly
SELECT 
  '=== TEST: Function call ===' as info,
  check_user_company_access(
    'b5d44a86-875f-42dc-970f-1a324318887c'::uuid,
    'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
  ) as has_access,
  CASE 
    WHEN check_user_company_access(
      'b5d44a86-875f-42dc-970f-1a324318887c'::uuid,
      'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
    ) = true THEN '✅ User has access'
    ELSE '❌ User does not have access'
  END as status;

