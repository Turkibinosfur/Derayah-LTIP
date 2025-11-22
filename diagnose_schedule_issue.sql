-- Diagnostic query to check the "5 years test" schedule and its milestones
-- This will help identify why only 2 events are being created

-- Check the schedule details
SELECT 
    id,
    name,
    total_duration_months,
    cliff_months,
    vesting_frequency,
    is_template,
    schedule_type
FROM vesting_schedules
WHERE name = '5 years test' OR id = '71e97c47-f6d1-4061-a631-e74f6366f93f';

-- Check if this schedule has milestones (which might interfere)
SELECT 
    vm.id,
    vm.vesting_schedule_id,
    vm.sequence_order,
    vm.vesting_percentage,
    vm.months_from_start,
    vm.milestone_type,
    vs.name as schedule_name
FROM vesting_milestones vm
JOIN vesting_schedules vs ON vm.vesting_schedule_id = vs.id
WHERE vs.id = '71e97c47-f6d1-4061-a631-e74f6366f93f'
ORDER BY vm.sequence_order;

-- Count milestones for this schedule
SELECT 
    vs.name as schedule_name,
    COUNT(vm.id) as milestone_count,
    CASE 
        WHEN vs.cliff_months > 0 THEN 1 + FLOOR((vs.total_duration_months - vs.cliff_months) / 
            CASE vs.vesting_frequency 
                WHEN 'monthly' THEN 1 
                WHEN 'quarterly' THEN 3 
                WHEN 'annually' THEN 12 
                ELSE 1 
            END)
        ELSE FLOOR(vs.total_duration_months / 
            CASE vs.vesting_frequency 
                WHEN 'monthly' THEN 1 
                WHEN 'quarterly' THEN 3 
                WHEN 'annually' THEN 12 
                ELSE 1 
            END)
    END as expected_events
FROM vesting_schedules vs
LEFT JOIN vesting_milestones vm ON vm.vesting_schedule_id = vs.id
WHERE vs.id = '71e97c47-f6d1-4061-a631-e74f6366f93f'
GROUP BY vs.id, vs.name, vs.total_duration_months, vs.cliff_months, vs.vesting_frequency;

-- Summary: Count events per grant
SELECT 
    g.grant_number,
    g.id as grant_id,
    COUNT(ve.id) as total_events,
    g.total_shares,
    MIN(ve.vesting_date) as first_vesting_date,
    MAX(ve.vesting_date) as last_vesting_date
FROM grants g
LEFT JOIN vesting_events ve ON ve.grant_id = g.id
WHERE g.grant_number IN ('GR-20251115-000073', 'GR-20251115-000074', 'GR-20251115-000075')
GROUP BY g.id, g.grant_number, g.total_shares
ORDER BY g.grant_number DESC;

