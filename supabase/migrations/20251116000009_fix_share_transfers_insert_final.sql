/*
  Fix share_transfers INSERT Policy - Final Solution
  
  Problem: The INSERT policy on share_transfers can't see company_users records
  because RLS on company_users blocks the check when called from another RLS policy.
  
  Solution: Use a comprehensive SECURITY DEFINER function that bypasses RLS on all tables
  and validates everything in one place. The function only checks data integrity (portfolio
  existence, company matching) and doesn't rely on user access checks in the policy context.
*/

-- Step 1: Create a simplified SECURITY DEFINER function that validates portfolios exist and match
-- This function bypasses RLS and only checks data integrity
CREATE OR REPLACE FUNCTION validate_share_transfer_data(
  p_company_id uuid,
  p_from_portfolio_id uuid,
  p_to_portfolio_id uuid,
  p_employee_id uuid DEFAULT NULL,
  p_grant_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
  v_from_company_id uuid;
  v_to_company_id uuid;
BEGIN
  -- Check if both portfolios exist and belong to the same company
  -- SECURITY DEFINER bypasses RLS on portfolios
  SELECT company_id INTO v_from_company_id
  FROM portfolios
  WHERE id = p_from_portfolio_id;
  
  SELECT company_id INTO v_to_company_id
  FROM portfolios
  WHERE id = p_to_portfolio_id;
  
  -- If either portfolio doesn't exist, return false
  IF v_from_company_id IS NULL OR v_to_company_id IS NULL THEN
    RETURN false;
  END IF;
  
  -- If portfolios don't match the company, return false
  IF v_from_company_id != p_company_id OR v_to_company_id != p_company_id THEN
    RETURN false;
  END IF;
  
  -- If portfolios belong to different companies, return false
  IF v_from_company_id != v_to_company_id THEN
    RETURN false;
  END IF;
  
  -- If employee_id is provided, validate it belongs to the company
  IF p_employee_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 
      FROM employees
      WHERE id = p_employee_id
      AND company_id = p_company_id
    ) THEN
      RETURN false;
    END IF;
  END IF;
  
  -- If grant_id is provided, validate it belongs to the company
  IF p_grant_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 
      FROM grants
      WHERE id = p_grant_id
      AND company_id = p_company_id
    ) THEN
      RETURN false;
    END IF;
  END IF;
  
  -- If we got here, everything is valid
  RETURN true;
END;
$$;

-- Step 2: Grant execute permission on function
GRANT EXECUTE ON FUNCTION validate_share_transfer_data(uuid, uuid, uuid, uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION validate_share_transfer_data(uuid, uuid, uuid, uuid, uuid) TO anon;
GRANT EXECUTE ON FUNCTION validate_share_transfer_data(uuid, uuid, uuid, uuid, uuid) TO service_role;

-- Step 3: Drop all existing INSERT policies on share_transfers
DROP POLICY IF EXISTS "Company users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Authenticated users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Test: Company users only" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow authenticated inserts" ON share_transfers;

-- Step 4: Create a policy that checks company_users access using SECURITY DEFINER
-- We'll use a function that checks company_users to bypass its RLS
CREATE OR REPLACE FUNCTION check_company_user_access(
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
    SELECT 1 
    FROM company_users
    WHERE user_id = p_user_id
    AND company_id = p_company_id
    AND is_active = true
  );
$$;

GRANT EXECUTE ON FUNCTION check_company_user_access(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION check_company_user_access(uuid, uuid) TO anon;
GRANT EXECUTE ON FUNCTION check_company_user_access(uuid, uuid) TO service_role;

-- Step 5: Create the INSERT policy using both functions
CREATE POLICY "Company users can create transfers"
  ON share_transfers
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Check if user has access to the company (SECURITY DEFINER bypasses RLS)
    check_company_user_access(auth.uid(), share_transfers.company_id)
    AND
    -- Validate portfolios exist and match company (SECURITY DEFINER bypasses RLS)
    validate_share_transfer_data(
      share_transfers.company_id,
      share_transfers.from_portfolio_id,
      share_transfers.to_portfolio_id,
      share_transfers.employee_id,
      share_transfers.grant_id
    )
  );

-- Step 6: Verify the policy was created
SELECT 
  '=== VERIFICATION: share_transfers INSERT policy ===' as info;

SELECT 
  policyname,
  cmd,
  CASE 
    WHEN with_check IS NOT NULL THEN '✅ Policy has WITH CHECK clause'
    ELSE '❌ No WITH CHECK'
  END as status,
  substring(with_check::text, 1, 200) as policy_preview
FROM pg_policies
WHERE tablename = 'share_transfers'
AND cmd = 'INSERT';

-- Step 7: Verify functions were created
SELECT 
  '=== VERIFICATION: Functions created ===' as info;

SELECT 
  routine_name,
  routine_type,
  '✅ Created' as status
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('validate_share_transfer_data', 'check_company_user_access')
ORDER BY routine_name;

