-- Debug company ID mismatch between user and vesting events
-- This will help identify why events exist but don't show for your user

-- STEP 1: Find your user ID and company association
-- Replace 'your-email@example.com' with your actual email
SELECT 
  'Your user details:' as step,
  au.id as your_user_id,
  au.email,
  cu.company_id as your_company_id,
  cu.role,
  c.company_name_en as your_company_name
FROM auth.users au
LEFT JOIN company_users cu ON au.id = cu.user_id
LEFT JOIN companies c ON cu.company_id = c.id
-- WHERE au.email = 'your-email@example.com'  -- Uncomment and replace with your email
ORDER BY au.created_at DESC
LIMIT 5;

-- STEP 2: Show all vesting events and their company IDs
SELECT 
  'Vesting events by company:' as step,
  ve.company_id,
  c.company_name_en,
  COUNT(*) as events_count,
  MIN(ve.vesting_date) as earliest_date,
  MAX(ve.vesting_date) as latest_date
FROM vesting_events ve
LEFT JOIN companies c ON ve.company_id = c.id
GROUP BY ve.company_id, c.company_name_en
ORDER BY events_count DESC;

-- STEP 3: Show sample vesting events with company details
SELECT 
  'Sample vesting events:' as step,
  ve.id,
  ve.company_id,
  c.company_name_en,
  ve.vesting_date,
  ve.shares_to_vest,
  ve.status,
  COALESCE(e.first_name_en, e.first_name_ar, 'Unknown') || ' ' || COALESCE(e.last_name_en, e.last_name_ar, 'Employee') as employee_name
FROM vesting_events ve
LEFT JOIN companies c ON ve.company_id = c.id
LEFT JOIN employees e ON ve.employee_id = e.id
ORDER BY ve.created_at DESC
LIMIT 10;

-- STEP 4: Check if there's a mismatch
-- This query will show if your company has any vesting events
-- Replace 'YOUR_COMPANY_ID' with the company_id from step 1
SELECT 
  'Events for your company:' as step,
  COUNT(*) as events_for_your_company
FROM vesting_events ve
-- WHERE ve.company_id = 'YOUR_COMPANY_ID'  -- Uncomment and replace
;

-- STEP 5: Test the exact frontend query
-- Replace 'YOUR_COMPANY_ID' with your actual company ID
SELECT 
  'Frontend query simulation:' as step,
  ve.id,
  ve.grant_id,
  ve.employee_id,
  ve.company_id,
  ve.event_type,
  ve.sequence_number,
  ve.vesting_date,
  ve.shares_to_vest,
  ve.cumulative_shares_vested,
  ve.status,
  ve.exercise_price,
  ve.created_at,
  e.first_name_en,
  e.first_name_ar,
  e.last_name_en,
  e.last_name_ar,
  g.total_shares,
  g.vested_shares,
  p.plan_name_en,
  p.plan_code,
  p.plan_type
FROM vesting_events ve
LEFT JOIN employees e ON ve.employee_id = e.id
LEFT JOIN grants g ON ve.grant_id = g.id
LEFT JOIN incentive_plans p ON g.plan_id = p.id
-- WHERE ve.company_id = 'YOUR_COMPANY_ID'  -- Uncomment and replace
ORDER BY ve.vesting_date ASC
LIMIT 10;
