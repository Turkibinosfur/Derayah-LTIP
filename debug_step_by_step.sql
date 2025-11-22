-- Step-by-step debugging for vesting events
-- Run each query separately in Supabase SQL Editor

-- STEP 1: Check if vesting_events table has any data at all
SELECT 'Step 1: Total vesting events in database' as step;
SELECT COUNT(*) as total_events FROM vesting_events;

-- STEP 2: If there are events, show a sample
SELECT 'Step 2: Sample vesting events' as step;
SELECT 
  id,
  grant_id,
  employee_id,
  company_id,
  event_type,
  vesting_date,
  shares_to_vest,
  status,
  created_at
FROM vesting_events
ORDER BY created_at DESC
LIMIT 5;

-- STEP 3: Check companies and their IDs
SELECT 'Step 3: Companies in system' as step;
SELECT 
  id as company_id,
  company_name_en,
  company_name_ar,
  created_at
FROM companies
ORDER BY created_at DESC;

-- STEP 4: Check if your user is linked to a company
SELECT 'Step 4: Check company_users table' as step;
SELECT 
  cu.user_id,
  cu.company_id,
  cu.role,
  c.company_name_en
FROM company_users cu
LEFT JOIN companies c ON cu.company_id = c.id
ORDER BY cu.created_at DESC
LIMIT 10;

-- STEP 5: Check vesting events by company
SELECT 'Step 5: Vesting events by company' as step;
SELECT 
  ve.company_id,
  c.company_name_en,
  COUNT(*) as events_count
FROM vesting_events ve
LEFT JOIN companies c ON ve.company_id = c.id
GROUP BY ve.company_id, c.company_name_en
ORDER BY events_count DESC;

-- STEP 6: Test the exact query the frontend uses
-- Replace 'YOUR_COMPANY_ID_HERE' with your actual company ID from step 3
SELECT 'Step 6: Frontend query test' as step;
SELECT 
  ve.id,
  ve.grant_id,
  ve.employee_id,
  ve.company_id,
  ve.event_type,
  ve.vesting_date,
  ve.shares_to_vest,
  ve.status,
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
-- WHERE ve.company_id = 'YOUR_COMPANY_ID_HERE'  -- Uncomment and replace with your company ID
ORDER BY ve.vesting_date ASC
LIMIT 10;
