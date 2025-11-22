-- Comprehensive Grant Debug
-- This script will help us understand exactly what's happening

-- 1. Check ALL grants for the current user
SELECT 
  '=== ALL GRANTS FOR CURRENT USER ===' as step,
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

-- 2. Check if there are any grants with acceptance date
SELECT 
  '=== GRANTS WITH ACCEPTANCE DATE ===' as step,
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
WHERE g.employee_acceptance_at IS NOT NULL
ORDER BY g.updated_at DESC;

-- 3. Check grants that should be active but aren't
SELECT 
  '=== GRANTS THAT SHOULD BE ACTIVE ===' as step,
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

-- 4. Force update any problematic grants
UPDATE grants 
SET 
  status = 'active',
  updated_at = NOW()
WHERE employee_acceptance_at IS NOT NULL 
  AND status = 'pending_signature';

-- 5. Show final result
SELECT 
  '=== FINAL RESULT ===' as step,
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
WHERE g.employee_acceptance_at IS NOT NULL
ORDER BY g.updated_at DESC;
