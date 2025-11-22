-- Simple verification query that returns rows (easier to see results)
-- Run this in Supabase SQL Editor

-- Check 1: Does the function exist and have p_schedule_id parameter?
SELECT 
    'Function Exists' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE p.proname = 'generate_vesting_events_for_grant'
            AND n.nspname = 'public'
        ) THEN 'YES ✓'
        ELSE 'NO ✗'
    END as result;

-- Check 2: Does it have p_schedule_id parameter?
SELECT 
    'Has p_schedule_id Parameter' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE p.proname = 'generate_vesting_events_for_grant'
            AND n.nspname = 'public'
            AND 'p_schedule_id' = ANY(p.proargnames)
        ) THEN 'YES ✓'
        ELSE 'NO ✗ - Migration NOT Applied'
    END as result;

-- Check 3: Function signature
SELECT 
    'Function Signature' as check_type,
    pg_get_function_arguments(p.oid) as result
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'generate_vesting_events_for_grant'
AND n.nspname = 'public';

-- Check 4: Number of parameters
SELECT 
    'Parameter Count' as check_type,
    array_length(p.proargnames, 1)::text as result
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'generate_vesting_events_for_grant'
AND n.nspname = 'public';

-- Check 5: Does function definition include the critical logic?
SELECT 
    'Has Critical Logic' as check_type,
    CASE 
        WHEN pg_get_functiondef(p.oid) LIKE '%CRITICAL: Check p_schedule_id parameter FIRST%' 
        THEN 'YES ✓ - Migration Applied'
        ELSE 'NO ✗ - Migration NOT Applied'
    END as result
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'generate_vesting_events_for_grant'
AND n.nspname = 'public';

-- Summary
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE p.proname = 'generate_vesting_events_for_grant'
            AND n.nspname = 'public'
            AND 'p_schedule_id' = ANY(p.proargnames)
            AND pg_get_functiondef(p.oid) LIKE '%CRITICAL: Check p_schedule_id parameter FIRST%'
        ) THEN '✅ MIGRATION HAS BEEN APPLIED'
        ELSE '❌ MIGRATION HAS NOT BEEN APPLIED - Please run the migration file'
    END as "=== MIGRATION STATUS ===";

