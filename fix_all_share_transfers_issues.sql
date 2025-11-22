-- COMPREHENSIVE FIX: Fix all RLS issues for share_transfers INSERT
-- This addresses both the INSERT policy and foreign key validation

-- Step 1: Fix employees SELECT policy to include company_admin
DROP POLICY IF EXISTS "Employees can view own data" ON employees;

CREATE POLICY "Employees can view own data"
  ON employees FOR SELECT TO authenticated
  USING (
    (user_id = auth.uid())
    OR
    EXISTS (
      SELECT 1 FROM company_users cu
      WHERE cu.company_id = employees.company_id
      AND cu.user_id = auth.uid()
      AND cu.is_active = true
      AND cu.role IN ('super_admin', 'hr_admin', 'finance_admin', 'legal_admin', 'company_admin')
    )
  );

-- Step 2: Ensure grants SELECT policy includes company_admin
-- Check current grants policies
DO $$
BEGIN
  -- Drop existing grants SELECT policies that might exclude company_admin
  DROP POLICY IF EXISTS "Company admins can view company grants" ON grants;
  DROP POLICY IF EXISTS "Employees can view own grants" ON grants;
  
  -- Create comprehensive grants SELECT policy
  CREATE POLICY "Employees can view own grants"
    ON grants FOR SELECT TO authenticated
    USING (
      employee_id IN (
        SELECT id FROM employees WHERE user_id = auth.uid()
      )
    );
  
  CREATE POLICY "Company admins can view company grants"
    ON grants FOR SELECT TO authenticated
    USING (
      company_id IN (
        SELECT company_id FROM company_users
        WHERE user_id = auth.uid()
        AND is_active = true
        AND role IN ('super_admin', 'hr_admin', 'finance_admin', 'legal_admin', 'company_admin')
      )
    );
  
  RAISE NOTICE '✅ Updated grants SELECT policies to include company_admin';
END $$;

-- Step 3: Ensure companies SELECT policy allows access (should already allow all authenticated)
-- Just verify
SELECT 
  '=== COMPANIES SELECT POLICIES ===' as info,
  policyname,
  cmd,
  qual::text as policy_condition
FROM pg_policies
WHERE tablename = 'companies'
AND cmd = 'SELECT'
ORDER BY policyname;

-- Step 4: Ensure portfolios SELECT policy includes company_admin (should already have it)
-- Just verify
SELECT 
  '=== PORTFOLIOS SELECT POLICIES ===' as info,
  policyname,
  cmd,
  qual::text as policy_condition
FROM pg_policies
WHERE tablename = 'portfolios'
AND cmd = 'SELECT'
ORDER BY policyname;

-- Step 5: Drop all existing INSERT policies on share_transfers
DROP POLICY IF EXISTS "Company users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Authenticated users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Test: Company users only" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow authenticated inserts" ON share_transfers;

-- Step 6: Create the simplest working INSERT policy
-- Since foreign keys will validate access to referenced tables, we just need to ensure
-- the user can see the portfolios (which they can, based on RLS on portfolios)
CREATE POLICY "Company users can create transfers"
  ON share_transfers
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Just check that portfolios exist and match company
    -- RLS on portfolios ensures users can only see portfolios they have access to
    EXISTS (
      SELECT 1 FROM portfolios
      WHERE id = share_transfers.from_portfolio_id
      AND company_id = share_transfers.company_id
    )
    AND
    EXISTS (
      SELECT 1 FROM portfolios
      WHERE id = share_transfers.to_portfolio_id
      AND company_id = share_transfers.company_id
    )
    AND
    -- Ensure both portfolios belong to same company
    (
      SELECT company_id FROM portfolios WHERE id = share_transfers.from_portfolio_id
    ) = (
      SELECT company_id FROM portfolios WHERE id = share_transfers.to_portfolio_id
    )
  );

-- Step 7: Verify everything
SELECT 
  '=== VERIFICATION: All Fixes Applied ===' as info;

-- Verify employees policy
SELECT 
  'employees' as table_name,
  policyname,
  CASE 
    WHEN qual::text LIKE '%company_admin%' THEN '✅ Includes company_admin'
    ELSE '❌ Missing company_admin'
  END as status
FROM pg_policies
WHERE tablename = 'employees'
AND cmd = 'SELECT'
AND policyname = 'Employees can view own data';

-- Verify grants policies
SELECT 
  'grants' as table_name,
  policyname,
  CASE 
    WHEN qual::text LIKE '%company_admin%' OR policyname = 'Company admins can view company grants' THEN '✅ Includes company_admin'
    ELSE '⚠️ Check manually'
  END as status
FROM pg_policies
WHERE tablename = 'grants'
AND cmd = 'SELECT'
ORDER BY policyname;

-- Verify share_transfers INSERT policy
SELECT 
  'share_transfers' as table_name,
  policyname,
  cmd,
  '✅ Policy created' as status
FROM pg_policies
WHERE tablename = 'share_transfers'
AND cmd = 'INSERT';

-- Step 8: Test if we can see employees now
SELECT 
  '=== TEST: Can we see employees? ===' as info,
  COUNT(*) as employee_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see employees - Foreign key validation should work!'
    ELSE '❌ Still cannot see employees'
  END as status
FROM employees
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid;

-- Step 9: Test if we can see grants
SELECT 
  '=== TEST: Can we see grants? ===' as info,
  COUNT(*) as grant_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see grants - Foreign key validation should work!'
    ELSE '❌ Still cannot see grants'
  END as status
FROM grants
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
LIMIT 5;

