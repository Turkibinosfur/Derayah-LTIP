-- TEST: Check if RLS on referenced tables is blocking foreign key validation
-- Foreign key constraints check the referenced tables, which might be blocked by RLS

-- Step 1: Test if we can see the records that foreign keys reference
SELECT 
  '=== TEST: Foreign Key Referenced Records ===' as info;

-- Test companies table access
SELECT 
  'Companies Table' as table_name,
  COUNT(*) as visible_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see companies'
    ELSE '❌ Cannot see companies - RLS blocking'
  END as status
FROM companies
WHERE id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid;

-- Test portfolios table access (for foreign keys)
SELECT 
  'Portfolios Table' as table_name,
  COUNT(*) as visible_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see portfolios'
    ELSE '❌ Cannot see portfolios - RLS blocking'
  END as status
FROM portfolios
WHERE id IN (
  (SELECT id FROM portfolios WHERE portfolio_type = 'company_reserved' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' AND employee_id IS NULL LIMIT 1),
  (SELECT id FROM portfolios WHERE portfolio_type = 'employee_vested' AND company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' LIMIT 1)
);

-- Test employees table access
SELECT 
  'Employees Table' as table_name,
  COUNT(*) as visible_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see employees'
    ELSE '❌ Cannot see employees - RLS blocking'
  END as status
FROM employees
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
LIMIT 5;

-- Step 2: The issue is likely that FOREIGN KEY constraint validation
-- happens AFTER the WITH CHECK policy, but it needs to see the referenced records
-- If RLS blocks access to referenced tables, the foreign key check fails

-- Step 3: Solution - Check RLS policies on referenced tables for SELECT
SELECT 
  '=== RLS POLICIES ON REFERENCED TABLES ===' as info;

-- Check portfolios SELECT policies
SELECT 
  'portfolios' as table_name,
  policyname,
  cmd,
  qual::text as policy_condition
FROM pg_policies
WHERE tablename = 'portfolios'
AND cmd = 'SELECT'
ORDER BY policyname;

-- Check companies SELECT policies
SELECT 
  'companies' as table_name,
  policyname,
  cmd,
  qual::text as policy_condition
FROM pg_policies
WHERE tablename = 'companies'
AND cmd = 'SELECT'
ORDER BY policyname;

-- Check employees SELECT policies
SELECT 
  'employees' as table_name,
  policyname,
  cmd,
  qual::text as policy_condition
FROM pg_policies
WHERE tablename = 'employees'
AND cmd = 'SELECT'
ORDER BY policyname;

