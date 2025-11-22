-- Manual test to create a vesting event
-- This will help us determine if the issue is with generation or display

DO $$
DECLARE
  v_company_id UUID;
  v_employee_id UUID;
  v_grant_id UUID;
  v_test_event_id UUID;
BEGIN
  -- Get the first company
  SELECT id INTO v_company_id FROM companies LIMIT 1;
  
  -- Get the first employee
  SELECT id INTO v_employee_id FROM employees LIMIT 1;
  
  -- Get the first active grant
  SELECT id INTO v_grant_id FROM grants WHERE status = 'active' LIMIT 1;
  
  IF v_company_id IS NULL OR v_employee_id IS NULL OR v_grant_id IS NULL THEN
    RAISE NOTICE 'Missing required data:';
    RAISE NOTICE '  Company ID: %', v_company_id;
    RAISE NOTICE '  Employee ID: %', v_employee_id;
    RAISE NOTICE '  Grant ID: %', v_grant_id;
    RETURN;
  END IF;
  
  RAISE NOTICE 'Creating test vesting event with:';
  RAISE NOTICE '  Company ID: %', v_company_id;
  RAISE NOTICE '  Employee ID: %', v_employee_id;
  RAISE NOTICE '  Grant ID: %', v_grant_id;
  
  -- Create a test vesting event
  INSERT INTO vesting_events (
    grant_id,
    employee_id,
    company_id,
    event_type,
    sequence_number,
    vesting_date,
    shares_to_vest,
    cumulative_shares_vested,
    status,
    performance_condition_met
  ) VALUES (
    v_grant_id,
    v_employee_id,
    v_company_id,
    'time_based'::vesting_event_type,
    999, -- Test sequence number
    CURRENT_DATE + INTERVAL '30 days',
    1000,
    1000,
    'pending'::vesting_event_status,
    true
  ) RETURNING id INTO v_test_event_id;
  
  RAISE NOTICE 'Test vesting event created with ID: %', v_test_event_id;
  
  -- Verify it was created
  DECLARE
    v_count INTEGER;
  BEGIN
    SELECT COUNT(*) INTO v_count FROM vesting_events WHERE id = v_test_event_id;
    RAISE NOTICE 'Verification: Found % vesting event(s) with test ID', v_count;
  END;
  
  -- Show the created event with joined data (same as frontend query)
  DECLARE
    event_rec RECORD;
  BEGIN
    SELECT 
      ve.id,
      ve.vesting_date,
      ve.shares_to_vest,
      ve.status,
      ve.event_type,
      COALESCE(e.first_name_en, e.first_name_ar, 'Unknown') || ' ' || COALESCE(e.last_name_en, e.last_name_ar, 'Employee') as employee_name,
      p.plan_name_en,
      p.plan_code
    INTO event_rec
    FROM vesting_events ve
    LEFT JOIN employees e ON ve.employee_id = e.id
    LEFT JOIN grants g ON ve.grant_id = g.id
    LEFT JOIN incentive_plans p ON g.plan_id = p.id
    WHERE ve.id = v_test_event_id;
    
    IF FOUND THEN
      RAISE NOTICE 'Test event details:';
      RAISE NOTICE '  Employee: %', event_rec.employee_name;
      RAISE NOTICE '  Plan: %', event_rec.plan_name_en;
      RAISE NOTICE '  Shares: %', event_rec.shares_to_vest;
      RAISE NOTICE '  Date: %', event_rec.vesting_date;
      RAISE NOTICE '  Status: %', event_rec.status;
    ELSE
      RAISE NOTICE 'Could not retrieve test event details';
    END IF;
  END;
  
END $$;

-- Show total count after test
SELECT 'Total vesting events after test:' as description, COUNT(*) as count FROM vesting_events;
