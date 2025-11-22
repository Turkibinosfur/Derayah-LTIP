-- Diagnostic query to check if the RPC function has been updated
-- Run this in Supabase SQL Editor to verify the migration has been applied

-- Check if the function accepts p_schedule_id parameter
SELECT 
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'generate_vesting_events_for_grant'
AND n.nspname = 'public';

-- Also check the function signature specifically
SELECT 
    p.proname as function_name,
    unnest(p.proargnames) as parameter_name,
    pg_catalog.format_type(p.proargtypes[array_position(p.proargnames, unnest(p.proargnames))], NULL) as parameter_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'generate_vesting_events_for_grant'
AND n.nspname = 'public';

