-- Debug Grant Acceptance Issue
-- This script checks the current state of grants and helps identify why acceptance isn't working

-- 1. Check all grants and their current status
SELECT 
  '=== ALL GRANTS STATUS ===' as step,
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

-- 2. Check specifically for grants with pending_signature status
SELECT 
  '=== PENDING SIGNATURE GRANTS ===' as step,
  g.id,
  g.grant_number,
  g.status,
  g.grant_date,
  g.total_shares,
  g.vested_shares,
  g.remaining_unvested_shares,
  g.employee_acceptance_at,
  e.first_name_en,
  e.last_name_en,
  e.email
FROM grants g
JOIN employees e ON g.employee_id = e.id
WHERE g.status = 'pending_signature'
ORDER BY g.created_at DESC;

-- 3. Check for grants that should be active but aren't
SELECT 
  '=== POTENTIAL ACTIVE GRANTS ===' as step,
  g.id,
  g.grant_number,
  g.status,
  g.grant_date,
  g.total_shares,
  g.vested_shares,
  g.remaining_unvested_shares,
  g.employee_acceptance_at,
  e.first_name_en,
  e.last_name_en,
  e.email,
  CASE 
    WHEN g.employee_acceptance_at IS NOT NULL AND g.status = 'pending_signature'
    THEN 'SHOULD BE ACTIVE - Acceptance date set but status not updated'
    WHEN g.employee_acceptance_at IS NOT NULL AND g.status = 'active'
    THEN 'CORRECTLY ACTIVE'
    ELSE 'PENDING - No acceptance date'
  END as issue_status
FROM grants g
JOIN employees e ON g.employee_id = e.id
WHERE g.employee_acceptance_at IS NOT NULL
ORDER BY g.created_at DESC;

-- 4. Check recent grant updates (last 24 hours)
SELECT 
  '=== RECENT GRANT UPDATES ===' as step,
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
WHERE g.updated_at > NOW() - INTERVAL '24 hours'
ORDER BY g.updated_at DESC;

-- 5. Manual fix for grants that have acceptance date but wrong status
UPDATE grants 
SET 
  status = 'active',
  updated_at = NOW()
WHERE employee_acceptance_at IS NOT NULL 
  AND status = 'pending_signature';

-- 6. Show the result after the fix
SELECT 
  '=== AFTER MANUAL FIX ===' as step,
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
