-- Debug grant creation issues
-- Run this in Supabase SQL Editor to check for potential problems

-- 1. Check if vesting events trigger exists and is enabled
SELECT 
  'Trigger status:' as step,
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement,
  action_condition
FROM information_schema.triggers 
WHERE trigger_name LIKE '%vesting%' 
   OR trigger_name LIKE '%grant%';

-- 2. Check if vesting event generation function exists
SELECT 
  'Function status:' as step,
  routine_name,
  routine_type,
  data_type
FROM information_schema.routines 
WHERE routine_name LIKE '%vesting%' 
   OR routine_name LIKE '%grant%';

-- 3. Test a simple grant insert without triggering vesting events
-- (We'll disable the trigger temporarily for testing)
DO $$
DECLARE
  v_company_id UUID;
  v_employee_id UUID;
  v_plan_id UUID;
  v_user_id UUID;
BEGIN
  -- Get sample data for testing
  SELECT id INTO v_company_id FROM companies LIMIT 1;
  SELECT id INTO v_employee_id FROM employees LIMIT 1;
  SELECT id INTO v_plan_id FROM incentive_plans WHERE shares_available > 100 LIMIT 1;
  SELECT cu.id INTO v_user_id FROM company_users cu LIMIT 1;
  
  RAISE NOTICE 'Test data:';
  RAISE NOTICE '  Company: %', v_company_id;
  RAISE NOTICE '  Employee: %', v_employee_id;
  RAISE NOTICE '  Plan: %', v_plan_id;
  RAISE NOTICE '  User: %', v_user_id;
  
  IF v_company_id IS NULL OR v_employee_id IS NULL OR v_plan_id IS NULL OR v_user_id IS NULL THEN
    RAISE NOTICE 'Missing required data for test';
    RETURN;
  END IF;
  
  -- Temporarily disable the vesting events trigger
  ALTER TABLE grants DISABLE TRIGGER trg_generate_vesting_events_on_grant_insert;
  
  -- Try to insert a test grant
  BEGIN
    INSERT INTO grants (
      company_id,
      plan_id,
      employee_id,
      total_shares,
      vesting_start_date,
      vesting_end_date,
      grant_date,
      created_by
    ) VALUES (
      v_company_id,
      v_plan_id,
      v_employee_id,
      100,
      CURRENT_DATE,
      CURRENT_DATE + INTERVAL '4 years',
      CURRENT_DATE,
      v_user_id
    );
    
    RAISE NOTICE '✅ Test grant insert successful (without trigger)';
    
    -- Clean up test grant
    DELETE FROM grants WHERE total_shares = 100 AND created_by = v_user_id AND grant_date = CURRENT_DATE;
    RAISE NOTICE '✅ Test grant cleaned up';
    
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE '❌ Test grant insert failed: %', SQLERRM;
  END;
  
  -- Re-enable the trigger
  ALTER TABLE grants ENABLE TRIGGER trg_generate_vesting_events_on_grant_insert;
  RAISE NOTICE '✅ Trigger re-enabled';
  
END $$;

-- 4. Check for any constraint violations or missing columns
SELECT 
  'Grants table structure:' as step,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'grants' 
ORDER BY ordinal_position;

-- 5. Check for any RLS policies that might be blocking inserts
SELECT 
  'RLS policies on grants:' as step,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'grants';
