-- Check vesting_events table structure and debug issues
-- Run this in Supabase SQL Editor

-- 1. Check if vesting_events table exists and its structure
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns 
WHERE table_name = 'vesting_events' 
ORDER BY ordinal_position;

-- 2. Check current row count
SELECT COUNT(*) as total_vesting_events FROM vesting_events;

-- 3. Check if the function exists
SELECT 
  routine_name, 
  routine_type,
  specific_name
FROM information_schema.routines 
WHERE routine_name = 'generate_vesting_events_for_grant';

-- 4. Test with a simple manual insert to check table permissions
DO $$
DECLARE
  v_grant_id UUID;
  v_employee_id UUID;
  v_company_id UUID;
BEGIN
  -- Get first active grant details
  SELECT g.id, g.employee_id, g.company_id 
  INTO v_grant_id, v_employee_id, v_company_id
  FROM grants g 
  WHERE g.status = 'active' 
  LIMIT 1;
  
  IF v_grant_id IS NOT NULL THEN
    RAISE NOTICE 'Testing with grant: %, employee: %, company: %', v_grant_id, v_employee_id, v_company_id;
    
    -- Try a simple insert
    BEGIN
      INSERT INTO vesting_events (
        grant_id, 
        employee_id, 
        company_id, 
        event_type, 
        sequence_number,
        vesting_date, 
        shares_to_vest, 
        cumulative_shares_vested,
        status
      ) VALUES (
        v_grant_id,
        v_employee_id,
        v_company_id,
        'time_based',
        999, -- Test sequence number
        CURRENT_DATE + INTERVAL '1 month',
        100,
        100,
        'pending'
      );
      
      RAISE NOTICE 'Test insert successful ✓';
      
      -- Clean up test record
      DELETE FROM vesting_events WHERE sequence_number = 999;
      RAISE NOTICE 'Test record cleaned up ✓';
      
    EXCEPTION
      WHEN OTHERS THEN
        RAISE NOTICE 'Test insert failed: %', SQLERRM;
    END;
  ELSE
    RAISE NOTICE 'No active grants found for testing';
  END IF;
END $$;
