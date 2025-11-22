-- FINAL FIX: Re-enable RLS on share_transfers with proper policy
-- This migration ensures foreign key validation works by fixing RLS on all referenced tables

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
-- (Check if policy exists that includes company_admin, if not, update it)
DO $$
BEGIN
  -- Drop existing policies that might not include company_admin
  DROP POLICY IF EXISTS "Users can view relevant portfolios" ON portfolios;
  
  -- Create comprehensive SELECT policy
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
  
  RAISE NOTICE '✅ Updated portfolios SELECT policy';
END $$;

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

-- Step 8: Verification
DO $$
BEGIN
  RAISE NOTICE '✅ Re-enabled RLS on share_transfers';
  RAISE NOTICE '✅ Fixed employees, grants, companies, and portfolios SELECT policies';
  RAISE NOTICE '✅ Created share_transfers INSERT policy';
  RAISE NOTICE '';
  RAISE NOTICE 'The transfer should now work! Foreign key validation can access all referenced tables.';
END $$;

