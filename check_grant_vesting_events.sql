-- Check vesting events for grant GR-20251028-000007
-- Run this query to see what's in the database

-- First, find the grant
SELECT 
    g.id as grant_id,
    g.grant_number,
    g.total_shares,
    g.vested_shares,
    g.vesting_start_date,
    g.vesting_end_date,
    g.status as grant_status,
    e.first_name_en || ' ' || e.last_name_en as employee_name
FROM grants g
JOIN employees e ON g.employee_id = e.id
WHERE g.grant_number = 'GR-20251028-000007';

-- Then check the vesting schedule records
WITH grant_info AS (
    SELECT id as grant_id 
    FROM grants 
    WHERE grant_number = 'GR-20251028-000007'
)
SELECT 
    vs.id,
    vs.sequence_number,
    vs.vesting_date,
    vs.shares_to_vest,
    vs.status,
    vs.actual_vest_date,
    vs.performance_condition_met,
    vs.created_at,
    -- Calculate if this event is due
    CASE 
        WHEN vs.status = 'vested' THEN 'VESTED'
        WHEN vs.vesting_date <= CURRENT_DATE AND vs.status = 'pending' THEN 'DUE'
        WHEN vs.vesting_date > CURRENT_DATE THEN 'UPCOMING'
        ELSE vs.status
    END as calculated_status,
    -- Days past due (negative = future)
    CURRENT_DATE - vs.vesting_date as days_difference
FROM vesting_schedules vs
JOIN grant_info gi ON vs.grant_id = gi.grant_id
ORDER BY vs.sequence_number;

-- Check for duplicates
WITH grant_info AS (
    SELECT id as grant_id 
    FROM grants 
    WHERE grant_number = 'GR-20251028-000007'
)
SELECT 
    sequence_number,
    COUNT(*) as duplicate_count,
    STRING_AGG(id::text, ', ') as record_ids
FROM vesting_schedules vs
JOIN grant_info gi ON vs.grant_id = gi.grant_id
GROUP BY sequence_number
HAVING COUNT(*) > 1;

-- Summary count by status
WITH grant_info AS (
    SELECT id as grant_id 
    FROM grants 
    WHERE grant_number = 'GR-20251028-000007'
)
SELECT 
    CASE 
        WHEN vs.status = 'vested' THEN 'VESTED'
        WHEN vs.vesting_date <= CURRENT_DATE AND vs.status = 'pending' THEN 'DUE'
        WHEN vs.vesting_date > CURRENT_DATE THEN 'UPCOMING'
        ELSE vs.status
    END as calculated_status,
    COUNT(*) as event_count,
    SUM(vs.shares_to_vest) as total_shares
FROM vesting_schedules vs
JOIN grant_info gi ON vs.grant_id = gi.grant_id
GROUP BY 
    CASE 
        WHEN vs.status = 'vested' THEN 'VESTED'
        WHEN vs.vesting_date <= CURRENT_DATE AND vs.status = 'pending' THEN 'DUE'
        WHEN vs.vesting_date > CURRENT_DATE THEN 'UPCOMING'
        ELSE vs.status
    END
ORDER BY calculated_status;
