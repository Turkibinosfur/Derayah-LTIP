-- Test Contract Acceptance Functionality
-- This script tests if the contract acceptance process is working correctly

-- 1. Check current grants and their status
SELECT 
  '=== CURRENT GRANTS STATUS ===' as step,
  g.id,
  g.grant_number,
  g.status,
  g.grant_date,
  g.total_shares,
  g.vested_shares,
  g.remaining_unvested_shares,
  g.employee_acceptance_at,
  g.created_at,
  g.updated_at,
  e.first_name_en,
  e.last_name_en,
  e.email
FROM grants g
JOIN employees e ON g.employee_id = e.id
ORDER BY g.created_at DESC;

-- 2. Check if there are any grants with pending_signature status
SELECT 
  '=== PENDING SIGNATURE GRANTS ===' as step,
  g.id,
  g.grant_number,
  g.status,
  g.employee_acceptance_at,
  g.updated_at,
  e.first_name_en,
  e.last_name_en,
  e.email
FROM grants g
JOIN employees e ON g.employee_id = e.id
WHERE g.status = 'pending_signature'
ORDER BY g.created_at DESC;

-- 3. Check if there are any grants with acceptance date but wrong status
SELECT 
  '=== GRANTS WITH ACCEPTANCE DATE ===' as step,
  g.id,
  g.grant_number,
  g.status,
  g.employee_acceptance_at,
  g.updated_at,
  e.first_name_en,
  e.last_name_en,
  e.email,
  CASE 
    WHEN g.employee_acceptance_at IS NOT NULL AND g.status = 'pending_signature'
    THEN 'PROBLEM: Has acceptance date but wrong status'
    WHEN g.employee_acceptance_at IS NOT NULL AND g.status = 'active'
    THEN 'CORRECT: Has acceptance date and correct status'
    ELSE 'PENDING: No acceptance date'
  END as issue_status
FROM grants g
JOIN employees e ON g.employee_id = e.id
WHERE g.employee_acceptance_at IS NOT NULL
ORDER BY g.updated_at DESC;

-- 4. Test manual update to see if database allows updates
UPDATE grants 
SET 
  status = 'active',
  employee_acceptance_at = NOW(),
  vested_shares = 0,
  remaining_unvested_shares = total_shares,
  updated_at = NOW()
WHERE status = 'pending_signature'
AND id IN (
  SELECT id FROM grants 
  WHERE status = 'pending_signature' 
  ORDER BY created_at DESC 
  LIMIT 1
);

-- 5. Check if the manual update worked
SELECT 
  '=== AFTER MANUAL UPDATE ===' as step,
  g.id,
  g.grant_number,
  g.status,
  g.employee_acceptance_at,
  g.vested_shares,
  g.remaining_unvested_shares,
  g.updated_at,
  e.first_name_en,
  e.last_name_en,
  e.email
FROM grants g
JOIN employees e ON g.employee_id = e.id
WHERE g.status = 'active'
ORDER BY g.updated_at DESC;

-- 6. Check RLS policies on grants table
SELECT 
  '=== RLS POLICIES ON GRANTS ===' as step,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'grants';
