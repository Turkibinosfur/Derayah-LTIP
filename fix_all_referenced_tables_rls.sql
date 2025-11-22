-- FIX: Ensure ALL referenced tables allow company_admin for foreign key validation
-- When inserting into share_transfers, foreign keys check: companies, employees, grants, portfolios

-- Step 1: Fix employees SELECT policy (for employee_id foreign key)
DROP POLICY IF EXISTS "Employees can view own data" ON employees;
DROP POLICY IF EXISTS "Users can view own employee data" ON employees;

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

-- Step 2: Fix grants SELECT policy (for grant_id foreign key)
-- Check current grants policies
DO $$
BEGIN
  DROP POLICY IF EXISTS "Company admins can view company grants" ON grants;
  DROP POLICY IF EXISTS "Employees can view own grants" ON grants;
  DROP POLICY IF EXISTS "Users can view relevant grants" ON grants;
  
  -- Create policy that includes company_admin
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
  
  RAISE NOTICE '✅ Updated grants SELECT policies';
END $$;

-- Step 3: Fix companies SELECT policy (for company_id foreign key)
-- Should already allow all authenticated users, but verify
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'companies'
    AND cmd = 'SELECT'
    AND (qual::text LIKE '%true%' OR qual::text IS NULL)
  ) THEN
    DROP POLICY IF EXISTS "Authenticated users can view companies" ON companies;
    DROP POLICY IF EXISTS "Company admins can view own company" ON companies;
    
    CREATE POLICY "Authenticated users can view companies"
      ON companies FOR SELECT TO authenticated
      USING (true);
    
    RAISE NOTICE '✅ Created companies SELECT policy';
  ELSE
    RAISE NOTICE '✅ Companies SELECT policy already allows all authenticated users';
  END IF;
END $$;

-- Step 4: Portfolios should already work (we verified we can see 8 portfolios)
-- Just verify
SELECT 
  '=== PORTFOLIOS POLICY CHECK ===' as info,
  policyname,
  cmd,
  CASE 
    WHEN qual::text LIKE '%company_admin%' OR qual::text LIKE '%true%' THEN '✅ Policy allows access'
    ELSE '⚠️ Check policy'
  END as status
FROM pg_policies
WHERE tablename = 'portfolios'
AND cmd = 'SELECT'
LIMIT 5;

-- Step 5: Fix share_transfers INSERT policy (simple version)
DROP POLICY IF EXISTS "Company users can create transfers" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow authenticated inserts" ON share_transfers;
DROP POLICY IF EXISTS "Test: Allow all authenticated inserts" ON share_transfers;

CREATE POLICY "Company users can create transfers"
  ON share_transfers
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Just check portfolios exist and match
    -- Foreign keys will validate referenced records (now that RLS allows access)
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

-- Step 6: Re-enable RLS if it was disabled
ALTER TABLE share_transfers ENABLE ROW LEVEL SECURITY;

-- Step 7: Verify everything
SELECT 
  '=== VERIFICATION: All Fixes Applied ===' as info;

-- Check employees policy
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

-- Check grants policies
SELECT 
  'grants' as table_name,
  policyname,
  CASE 
    WHEN qual::text LIKE '%company_admin%' THEN '✅ Includes company_admin'
    WHEN policyname = 'Company admins can view company grants' THEN '✅ Policy created'
    ELSE '⚠️ Check manually'
  END as status
FROM pg_policies
WHERE tablename = 'grants'
AND cmd = 'SELECT'
ORDER BY policyname;

-- Check share_transfers policy
SELECT 
  'share_transfers' as table_name,
  policyname,
  cmd,
  '✅ Policy created' as status
FROM pg_policies
WHERE tablename = 'share_transfers'
AND cmd = 'INSERT';

-- Test if we can see employees
SELECT 
  '=== FINAL TEST: Can see employees? ===' as info,
  COUNT(*) as employee_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see employees - Foreign keys should work!'
    ELSE '❌ Cannot see employees - Foreign keys will fail'
  END as status
FROM employees
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid;

-- Test if we can see grants
SELECT 
  '=== FINAL TEST: Can see grants? ===' as info,
  COUNT(*) as grant_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see grants - Foreign keys should work!'
    ELSE '❌ Cannot see grants - Foreign keys will fail'
  END as status
FROM grants
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
LIMIT 5;

