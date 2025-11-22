-- FIX: Update RLS policies on referenced tables to include company_admin
-- This allows foreign key validation to work when inserting into share_transfers

-- Step 1: Update employees SELECT policy to include company_admin
-- Drop and recreate with company_admin included
DROP POLICY IF EXISTS "Employees can view own data" ON employees;

CREATE POLICY "Employees can view own data"
  ON employees FOR SELECT TO authenticated
  USING (
    (user_id = auth.uid())
    OR (EXISTS (
      SELECT 1 FROM _super_admin_access sa
      WHERE sa.company_id = employees.company_id
      AND sa.user_id = auth.uid()
    ))
    OR (EXISTS (
      SELECT 1 FROM _active_company_roles r
      WHERE r.company_id = employees.company_id
      AND r.user_id = auth.uid()
      AND r.role = ANY (ARRAY['super_admin'::user_role, 'hr_admin'::user_role, 'finance_admin'::user_role, 'company_admin'::user_role])
    ))
  );

-- Step 2: Update grants SELECT policy to include company_admin (if needed)
-- Check current grants policies first
SELECT 
  '=== CURRENT GRANTS POLICIES ===' as info,
  policyname,
  cmd,
  qual::text as policy_condition
FROM pg_policies
WHERE tablename = 'grants'
AND cmd = 'SELECT'
ORDER BY policyname;

-- Step 3: Update companies SELECT policy to include company_admin (if needed)
-- Check current companies policies first
SELECT 
  '=== CURRENT COMPANIES POLICIES ===' as info,
  policyname,
  cmd,
  qual::text as policy_condition
FROM pg_policies
WHERE tablename = 'companies'
AND cmd = 'SELECT'
ORDER BY policyname;

-- Step 4: Update portfolios SELECT policy to include company_admin (if needed)
-- This should already allow company_admin based on previous migrations, but verify
SELECT 
  '=== CURRENT PORTFOLIOS POLICIES ===' as info,
  policyname,
  cmd,
  qual::text as policy_condition
FROM pg_policies
WHERE tablename = 'portfolios'
AND cmd = 'SELECT'
ORDER BY policyname;

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

