-- Simple test for grant creation
-- Run this to test if the basic grant creation works

DO $$
DECLARE
  v_company_id UUID;
  v_employee_id UUID;
  v_plan_id UUID;
  v_user_id UUID;
  v_grant_id UUID;
BEGIN
  RAISE NOTICE '=== TESTING GRANT CREATION ===';
  
  -- Get test data
  SELECT c.id INTO v_company_id 
  FROM companies c 
  LIMIT 1;
  
  SELECT e.id INTO v_employee_id 
  FROM employees e 
  WHERE e.company_id = v_company_id 
  LIMIT 1;
  
  SELECT p.id INTO v_plan_id 
  FROM incentive_plans p 
  WHERE p.company_id = v_company_id 
    AND p.shares_available > 100 
  LIMIT 1;
  
  SELECT cu.id INTO v_user_id 
  FROM company_users cu 
  WHERE cu.company_id = v_company_id 
  LIMIT 1;
  
  -- Check if we have all required data
  IF v_company_id IS NULL THEN
    RAISE NOTICE '❌ No company found';
    RETURN;
  END IF;
  
  IF v_employee_id IS NULL THEN
    RAISE NOTICE '❌ No employee found for company %', v_company_id;
    RETURN;
  END IF;
  
  IF v_plan_id IS NULL THEN
    RAISE NOTICE '❌ No plan with available shares found for company %', v_company_id;
    RETURN;
  END IF;
  
  IF v_user_id IS NULL THEN
    RAISE NOTICE '❌ No company user found for company %', v_company_id;
    RETURN;
  END IF;
  
  RAISE NOTICE '✅ Test data ready:';
  RAISE NOTICE '  Company: %', v_company_id;
  RAISE NOTICE '  Employee: %', v_employee_id;
  RAISE NOTICE '  Plan: %', v_plan_id;
  RAISE NOTICE '  User: %', v_user_id;
  
  -- Test grant creation
  BEGIN
    INSERT INTO grants (
      company_id,
      plan_id,
      employee_id,
      total_shares,
      vesting_start_date,
      vesting_end_date,
      grant_date,
      created_by,
      status
    ) VALUES (
      v_company_id,
      v_plan_id,
      v_employee_id,
      50, -- Small number for testing
      CURRENT_DATE,
      CURRENT_DATE + INTERVAL '4 years',
      CURRENT_DATE,
      v_user_id,
      'active'
    ) RETURNING id INTO v_grant_id;
    
    RAISE NOTICE '✅ Grant created successfully with ID: %', v_grant_id;
    
    -- Check if vesting events were created
    DECLARE
      v_events_count INTEGER;
    BEGIN
      SELECT COUNT(*) INTO v_events_count
      FROM vesting_events
      WHERE grant_id = v_grant_id;
      
      RAISE NOTICE '📊 Vesting events created: %', v_events_count;
    END;
    
    -- Clean up test grant
    DELETE FROM vesting_events WHERE grant_id = v_grant_id;
    DELETE FROM grants WHERE id = v_grant_id;
    RAISE NOTICE '🧹 Test grant and events cleaned up';
    
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE '❌ Grant creation failed: %', SQLERRM;
      RAISE NOTICE '❌ Error detail: %', SQLSTATE;
  END;
  
END $$;
