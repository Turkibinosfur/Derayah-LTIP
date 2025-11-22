-- RE-ENABLE RLS ON share_transfers WITH PROPER FIXES
-- Run this after confirming transfer works with RLS disabled
-- This fixes all foreign key validation issues

-- Step 1: Fix employees SELECT policy (for employee_id foreign key validation)
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

-- Step 2: Fix grants SELECT policy (for grant_id foreign key validation)
DROP POLICY IF EXISTS "Company admins can view company grants" ON grants;
DROP POLICY IF EXISTS "Employees can view own grants" ON grants;
DROP POLICY IF EXISTS "Users can view relevant grants" ON grants;

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

-- Step 3: Ensure companies SELECT policy allows all authenticated users
DROP POLICY IF EXISTS "Authenticated users can view companies" ON companies;
DROP POLICY IF EXISTS "Company admins can view own company" ON companies;

CREATE POLICY "Authenticated users can view companies"
  ON companies FOR SELECT TO authenticated
  USING (true);

-- Step 4: Ensure portfolios policies allow company_admin to see portfolios
DROP POLICY IF EXISTS "Users can view relevant portfolios" ON portfolios;

CREATE POLICY "Users can view relevant portfolios"
  ON portfolios FOR SELECT TO authenticated
  USING (
    -- Employee can see their own portfolio
    (employee_id IS NOT NULL AND employee_id IN (
      SELECT id FROM employees WHERE user_id = auth.uid()
    ))
    OR
    -- Company admins can see company reserved portfolio (employee_id IS NULL)
    (employee_id IS NULL AND company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND is_active = true
      AND role IN ('super_admin', 'hr_admin', 'finance_admin', 'legal_admin', 'company_admin')
    ))
    OR
    -- Company admins can see employee portfolios in their company
    (employee_id IS NOT NULL AND company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND is_active = true
      AND role IN ('super_admin', 'hr_admin', 'finance_admin', 'legal_admin', 'company_admin')
    ))
  );

-- Step 5: Drop all existing INSERT policies on share_transfers
DROP POLICY IF EXISTS "Company users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Authenticated users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Test: Company users only" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow authenticated inserts" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow all authenticated inserts" ON share_transfers;

-- Step 6: Re-enable RLS on share_transfers
ALTER TABLE share_transfers ENABLE ROW LEVEL SECURITY;

-- Step 7: Create simple INSERT policy that validates portfolios
-- Foreign key validation will now work because RLS on referenced tables allows access
CREATE POLICY "Company users can create transfers"
  ON share_transfers
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Both portfolios must exist and belong to the same company
    -- This check uses portfolio visibility as the access control
    EXISTS (
      SELECT 1 FROM portfolios
      WHERE id = share_transfers.from_portfolio_id
      AND company_id = share_transfers.company_id
    )
    AND EXISTS (
      SELECT 1 FROM portfolios
      WHERE id = share_transfers.to_portfolio_id
      AND company_id = share_transfers.company_id
    )
  );

-- Step 8: Verification queries
SELECT 
  '=== VERIFICATION: RLS Status ===' as info,
  tablename,
  rowsecurity as rls_enabled,
  CASE 
    WHEN rowsecurity = true THEN '✅ RLS is ENABLED'
    ELSE '❌ RLS is DISABLED'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'share_transfers';

SELECT 
  '=== VERIFICATION: share_transfers INSERT Policy ===' as info,
  policyname,
  cmd,
  with_check::text as policy_check
FROM pg_policies
WHERE tablename = 'share_transfers'
AND cmd = 'INSERT';

SELECT 
  '=== VERIFICATION: Can see employees? ===' as info,
  COUNT(*) as employee_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see employees - Foreign keys will work!'
    ELSE '❌ Cannot see employees - Foreign keys may fail'
  END as status
FROM employees
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid;

SELECT 
  '=== VERIFICATION: Can see grants? ===' as info,
  COUNT(*) as grant_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see grants - Foreign keys will work!'
    ELSE '❌ Cannot see grants - Foreign keys may fail'
  END as status
FROM grants
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
LIMIT 1;

