-- Fix Grant Status - Simple Version
-- This script fixes grants that have acceptance date but wrong status

-- 1. Check current state
SELECT 
  '=== CURRENT GRANT STATUS ===' as step,
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

-- 2. Update grants that have acceptance date but wrong status
UPDATE grants 
SET 
  status = 'active',
  updated_at = NOW()
WHERE employee_acceptance_at IS NOT NULL 
  AND status = 'pending_signature';

-- 3. Show result after update
SELECT 
  '=== AFTER UPDATE ===' as step,
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
