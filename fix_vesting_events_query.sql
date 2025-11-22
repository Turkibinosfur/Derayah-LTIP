-- Check what vesting events were actually created
-- Run this in Supabase SQL Editor to see the events

-- 1. Check total vesting events
SELECT 
  'Total vesting events' as description,
  COUNT(*) as count
FROM vesting_events;

-- 2. Check vesting events by status
SELECT 
  status,
  COUNT(*) as count,
  SUM(shares_to_vest) as total_shares
FROM vesting_events
GROUP BY status
ORDER BY count DESC;

-- 3. Check vesting events by company
SELECT 
  ve.company_id,
  c.company_name_en,
  COUNT(*) as events_count,
  SUM(ve.shares_to_vest) as total_shares
FROM vesting_events ve
LEFT JOIN companies c ON ve.company_id = c.id
GROUP BY ve.company_id, c.company_name_en
ORDER BY events_count DESC;

-- 4. Show sample vesting events with all details
SELECT 
  ve.id,
  ve.grant_id,
  ve.employee_id,
  ve.company_id,
  ve.event_type,
  ve.sequence_number,
  ve.vesting_date,
  ve.shares_to_vest,
  ve.status,
  ve.exercise_price,
  COALESCE(e.first_name_en, e.first_name_ar, 'Unknown') || ' ' || COALESCE(e.last_name_en, e.last_name_ar, 'Employee') as employee_name,
  p.plan_name_en,
  p.plan_code,
  p.plan_type
FROM vesting_events ve
LEFT JOIN employees e ON ve.employee_id = e.id
LEFT JOIN grants g ON ve.grant_id = g.id
LEFT JOIN incentive_plans p ON g.plan_id = p.id
ORDER BY ve.created_at DESC
LIMIT 10;

-- 5. Check vesting events with dates (to see if they're in future or past)
SELECT 
  ve.vesting_date,
  ve.status,
  COUNT(*) as count,
  CASE 
    WHEN ve.vesting_date > CURRENT_DATE THEN 'Future'
    WHEN ve.vesting_date = CURRENT_DATE THEN 'Today'
    ELSE 'Past'
  END as date_category
FROM vesting_events ve
GROUP BY ve.vesting_date, ve.status, date_category
ORDER BY ve.vesting_date DESC
LIMIT 20;
