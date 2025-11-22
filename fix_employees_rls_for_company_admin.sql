-- FIX: Update employees SELECT RLS policy to include company_admin role
-- This allows foreign key validation to work when inserting into share_transfers

-- Step 1: Check current employees SELECT policies
SELECT 
  '=== CURRENT EMPLOYEES SELECT POLICIES ===' as info,
  policyname,
  cmd,
  qual::text as policy_condition
FROM pg_policies
WHERE tablename = 'employees'
AND cmd = 'SELECT'
ORDER BY policyname;

-- Step 2: Drop existing "Employees can view own data" policy
DROP POLICY IF EXISTS "Employees can view own data" ON employees;

-- Step 3: Create new policy that includes company_admin role
-- This directly checks company_users table instead of using views
CREATE POLICY "Employees can view own data"
  ON employees FOR SELECT TO authenticated
  USING (
    -- Employee can see their own data
    (user_id = auth.uid())
    OR
    -- Company admins (including company_admin) can see employees in their company
    EXISTS (
      SELECT 1 FROM company_users cu
      WHERE cu.company_id = employees.company_id
      AND cu.user_id = auth.uid()
      AND cu.is_active = true
      AND cu.role IN ('super_admin', 'hr_admin', 'finance_admin', 'legal_admin', 'company_admin')
    )
  );

-- Step 4: Verify the policy was created
SELECT 
  '=== VERIFICATION: Employees policy updated ===' as info;

SELECT 
  policyname,
  cmd,
  CASE 
    WHEN qual::text LIKE '%company_admin%' THEN '✅ Policy includes company_admin'
    ELSE '❌ Policy does not include company_admin'
  END as status,
  substring(qual::text, 1, 200) as policy_preview
FROM pg_policies
WHERE tablename = 'employees'
AND cmd = 'SELECT'
AND policyname = 'Employees can view own data';

-- Step 5: Test if we can now see employees
SELECT 
  '=== TEST: Can we see employees after fix? ===' as info,
  COUNT(*) as employee_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see employees - Fix worked!'
    ELSE '❌ Still cannot see employees'
  END as status
FROM employees
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
LIMIT 5;

-- Step 6: Check and update grants SELECT policy if needed
SELECT 
  '=== CURRENT GRANTS SELECT POLICIES ===' as info,
  policyname,
  cmd,
  qual::text as policy_condition
FROM pg_policies
WHERE tablename = 'grants'
AND cmd = 'SELECT'
ORDER BY policyname;

-- Step 7: Check and update companies SELECT policy if needed
-- (Companies should already allow all authenticated users based on earlier migrations)
SELECT 
  '=== CURRENT COMPANIES SELECT POLICIES ===' as info,
  policyname,
  cmd,
  qual::text as policy_condition
FROM pg_policies
WHERE tablename = 'companies'
AND cmd = 'SELECT'
ORDER BY policyname;

-- Step 8: Now try the transfer again - it should work!
-- The foreign key validation should now be able to see employees, companies, grants, and portfolios

