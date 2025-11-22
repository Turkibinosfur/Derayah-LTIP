-- Verification script to check if the RPC function migration has been applied
-- Run this in Supabase SQL Editor

DO $$
DECLARE
    v_function_exists boolean;
    v_has_p_schedule_id boolean;
    v_function_def text;
    v_param_count integer;
    v_func_name text;
    v_func_args text;
BEGIN
    RAISE NOTICE '=== VERIFYING RPC FUNCTION MIGRATION ===';
    RAISE NOTICE '';
    
    -- Check if function exists
    SELECT EXISTS (
        SELECT 1 
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE p.proname = 'generate_vesting_events_for_grant'
        AND n.nspname = 'public'
    ) INTO v_function_exists;
    
    IF v_function_exists THEN
        RAISE NOTICE '✓ Function exists: generate_vesting_events_for_grant';
        
        -- Get function definition
        SELECT pg_get_functiondef(p.oid) INTO v_function_def
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE p.proname = 'generate_vesting_events_for_grant'
        AND n.nspname = 'public'
        LIMIT 1;
        
        -- Check if function has p_schedule_id parameter
        SELECT EXISTS (
            SELECT 1 
            FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE p.proname = 'generate_vesting_events_for_grant'
            AND n.nspname = 'public'
            AND 'p_schedule_id' = ANY(p.proargnames)
        ) INTO v_has_p_schedule_id;
        
        IF v_has_p_schedule_id THEN
            RAISE NOTICE '✓ Function has p_schedule_id parameter';
        ELSE
            RAISE NOTICE '✗ Function does NOT have p_schedule_id parameter';
            RAISE NOTICE '  → Migration has NOT been applied';
        END IF;
        
        -- Check if function definition includes critical logic
        IF v_function_def LIKE '%CRITICAL: Check p_schedule_id parameter FIRST%' THEN
            RAISE NOTICE '✓ Function includes p_schedule_id priority check';
        ELSE
            RAISE NOTICE '✗ Function does NOT include p_schedule_id priority check';
            RAISE NOTICE '  → Migration has NOT been applied';
        END IF;
        
        IF v_function_def LIKE '%RPC: Using provided p_schedule_id parameter%' THEN
            RAISE NOTICE '✓ Function includes p_schedule_id logging';
        ELSE
            RAISE NOTICE '✗ Function does NOT include p_schedule_id logging';
        END IF;
        
        -- Get parameter count
        SELECT array_length(p.proargnames, 1) INTO v_param_count
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE p.proname = 'generate_vesting_events_for_grant'
        AND n.nspname = 'public'
        LIMIT 1;
        
        RAISE NOTICE '';
        RAISE NOTICE 'Function parameters: %', v_param_count;
        
        IF v_param_count >= 2 THEN
            RAISE NOTICE '✓ Function has 2 or more parameters (expected: p_grant_id, p_schedule_id)';
        ELSE
            RAISE NOTICE '✗ Function has only % parameter(s) (expected: 2)', v_param_count;
        END IF;
        
        RAISE NOTICE '';
        RAISE NOTICE '=== SUMMARY ===';
        IF v_has_p_schedule_id AND v_function_def LIKE '%CRITICAL: Check p_schedule_id parameter FIRST%' THEN
            RAISE NOTICE '✅ MIGRATION HAS BEEN APPLIED';
            RAISE NOTICE 'The RPC function should now generate the correct number of vesting events.';
        ELSE
            RAISE NOTICE '❌ MIGRATION HAS NOT BEEN APPLIED';
            RAISE NOTICE 'Please apply the migration: 20251115140000_fix_rpc_milestone_count_validation.sql';
        END IF;
        
    ELSE
        RAISE NOTICE '✗ Function does NOT exist: generate_vesting_events_for_grant';
        RAISE NOTICE '  → This is unexpected. The function should exist.';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== FUNCTION SIGNATURE ===';
    IF v_function_exists THEN
        SELECT 
            p.proname,
            pg_get_function_arguments(p.oid)
        INTO v_func_name, v_func_args
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE p.proname = 'generate_vesting_events_for_grant'
        AND n.nspname = 'public';
        
        IF v_func_name IS NOT NULL THEN
            RAISE NOTICE 'Function: %', v_func_name;
            RAISE NOTICE 'Arguments: %', v_func_args;
        END IF;
    END IF;
    
END $$;

