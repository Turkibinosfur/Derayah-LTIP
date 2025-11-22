-- Test Grant Update
-- This script tests if we can manually update a grant status

-- 1. Find a grant with pending_signature status
SELECT 
  '=== FINDING PENDING GRANT ===' as step,
  g.id,
  g.grant_number,
  g.status,
  g.employee_acceptance_at,
  e.first_name_en,
  e.last_name_en,
  e.email
FROM grants g
JOIN employees e ON g.employee_id = e.id
WHERE g.status = 'pending_signature'
LIMIT 1;

-- 2. Try to update the grant status manually
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
  LIMIT 1
);

-- 3. Check if the update worked
SELECT 
  '=== AFTER MANUAL UPDATE ===' as step,
  g.id,
  g.grant_number,
  g.status,
  g.employee_acceptance_at,
  g.vested_shares,
  g.remaining_unvested_shares,
  e.first_name_en,
  e.last_name_en,
  e.email
FROM grants g
JOIN employees e ON g.employee_id = e.id
WHERE g.status = 'active'
ORDER BY g.updated_at DESC
LIMIT 5;
