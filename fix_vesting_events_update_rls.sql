-- Fix RLS policy on vesting_events to allow company_admin to UPDATE
-- This is needed so that vesting event status can be updated to 'transferred'

-- Step 1: Check current UPDATE policies
SELECT 
  '=== CURRENT vesting_events UPDATE POLICIES ===' as info,
  policyname,
  cmd,
  qual::text as using_clause,
  with_check::text as with_check_clause
FROM pg_policies
WHERE tablename = 'vesting_events'
AND cmd = 'UPDATE'
ORDER BY policyname;

-- Step 2: Drop existing UPDATE policies
DROP POLICY IF EXISTS "Admins can update vesting events" ON vesting_events;
DROP POLICY IF EXISTS "Company users can update vesting events" ON vesting_events;

-- Step 3: Create/update policy to include company_admin
CREATE POLICY "Company users can update vesting events"
  ON vesting_events FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND is_active = true
      AND role IN ('super_admin', 'hr_admin', 'finance_admin', 'legal_admin', 'company_admin')
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND is_active = true
      AND role IN ('super_admin', 'hr_admin', 'finance_admin', 'legal_admin', 'company_admin')
    )
  );

-- Step 4: Verification
SELECT 
  '=== VERIFICATION: Updated Policy ===' as info,
  policyname,
  cmd,
  with_check::text as policy_check,
  CASE 
    WHEN with_check::text LIKE '%company_admin%' THEN '✅ Includes company_admin'
    ELSE '❌ Missing company_admin'
  END as status
FROM pg_policies
WHERE tablename = 'vesting_events'
AND cmd = 'UPDATE'
ORDER BY policyname;

-- Step 5: Test if we can see vesting_events (for UPDATE)
SELECT 
  '=== TEST: Can see vesting_events for update? ===' as info,
  COUNT(*) as event_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Can see vesting_events - UPDATE should work!'
    ELSE '❌ Cannot see vesting_events - UPDATE will fail'
  END as status
FROM vesting_events
WHERE company_id = 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1'::uuid
AND status = 'vested'
LIMIT 1;

