-- Manual fix for vesting event status issue
-- Run this in your Supabase SQL editor or psql

-- First, let's see what events are incorrectly marked as due
SELECT 
    id,
    vesting_date,
    status,
    CASE 
        WHEN vesting_date > CURRENT_DATE THEN 'SHOULD BE PENDING'
        WHEN vesting_date <= CURRENT_DATE THEN 'CORRECTLY DUE'
    END as correct_status,
    vesting_date - CURRENT_DATE as days_until_vesting
FROM vesting_events 
WHERE status = 'due'
ORDER BY vesting_date;

-- Fix events that are marked as due but have future vesting dates
UPDATE vesting_events 
SET 
    status = 'pending',
    updated_at = now()
WHERE 
    status = 'due' 
    AND vesting_date > CURRENT_DATE;

-- Show the results
SELECT 
    status,
    COUNT(*) as count,
    MIN(vesting_date) as earliest_date,
    MAX(vesting_date) as latest_date
FROM vesting_events 
GROUP BY status
ORDER BY status;

-- Verify no events are incorrectly marked as due
SELECT COUNT(*) as incorrectly_due_events
FROM vesting_events 
WHERE status = 'due' AND vesting_date > CURRENT_DATE;
