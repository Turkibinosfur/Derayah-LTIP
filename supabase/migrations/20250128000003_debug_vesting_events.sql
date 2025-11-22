/*
  # Debug Vesting Events Creation
  
  This diagnostic script checks why vesting events might not have been created
  and provides detailed information about the current state.
*/

DO $$
DECLARE
  v_grants_count INTEGER;
  v_active_grants_count INTEGER;
  v_vesting_events_count INTEGER;
  v_companies_count INTEGER;
  v_plans_count INTEGER;
  v_employees_count INTEGER;
  grant_rec RECORD;
  plan_rec RECORD;
BEGIN
  RAISE NOTICE '=== VESTING EVENTS DIAGNOSTIC ===';
  
  -- Check basic table counts
  SELECT COUNT(*) INTO v_companies_count FROM companies;
  SELECT COUNT(*) INTO v_employees_count FROM employees;
  SELECT COUNT(*) INTO v_plans_count FROM incentive_plans;
  SELECT COUNT(*) INTO v_grants_count FROM grants;
  SELECT COUNT(*) INTO v_active_grants_count FROM grants WHERE status = 'active';
  SELECT COUNT(*) INTO v_vesting_events_count FROM vesting_events;
  
  RAISE NOTICE 'Table Counts:';
  RAISE NOTICE '  Companies: %', v_companies_count;
  RAISE NOTICE '  Employees: %', v_employees_count;
  RAISE NOTICE '  Plans: %', v_plans_count;
  RAISE NOTICE '  Total Grants: %', v_grants_count;
  RAISE NOTICE '  Active Grants: %', v_active_grants_count;
  RAISE NOTICE '  Vesting Events: %', v_vesting_events_count;
  
  -- Check if vesting_events table exists and has correct structure
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'vesting_events') THEN
    RAISE NOTICE 'vesting_events table exists ✓';
  ELSE
    RAISE NOTICE 'vesting_events table does NOT exist ✗';
    RETURN;
  END IF;
  
  -- Check if we have any active grants
  IF v_active_grants_count = 0 THEN
    RAISE NOTICE 'No active grants found - this explains why no vesting events were created';
    
    -- Show all grants and their statuses
    RAISE NOTICE 'All grants in system:';
    FOR grant_rec IN 
      SELECT 
        g.id,
        g.status,
        g.total_shares,
        g.vesting_start_date,
        COALESCE(e.first_name_en, e.first_name_ar, 'Unknown') || ' ' || COALESCE(e.last_name_en, e.last_name_ar, 'Employee') as employee_name,
        p.plan_name_en,
        p.plan_code
      FROM grants g
      LEFT JOIN employees e ON g.employee_id = e.id
      LEFT JOIN incentive_plans p ON g.plan_id = p.id
      ORDER BY g.created_at DESC
      LIMIT 10
    LOOP
      RAISE NOTICE '  Grant %: % | % shares | % | % (%)', 
        grant_rec.id,
        grant_rec.status,
        grant_rec.total_shares,
        grant_rec.employee_name,
        grant_rec.plan_name_en,
        grant_rec.plan_code;
    END LOOP;
    
    RETURN;
  END IF;
  
  -- Check active grants in detail
  RAISE NOTICE 'Active Grants Analysis:';
  FOR grant_rec IN 
    SELECT 
      g.id,
      g.employee_id,
      g.plan_id,
      g.total_shares,
      g.vesting_start_date,
      g.status,
      COALESCE(e.first_name_en, e.first_name_ar, 'Unknown') || ' ' || COALESCE(e.last_name_en, e.last_name_ar, 'Employee') as employee_name,
      p.plan_name_en,
      p.plan_code,
      p.vesting_schedule_template_id,
      p.vesting_config
    FROM grants g
    LEFT JOIN employees e ON g.employee_id = e.id
    LEFT JOIN incentive_plans p ON g.plan_id = p.id
    WHERE g.status = 'active'
    ORDER BY g.created_at DESC
    LIMIT 5
  LOOP
    RAISE NOTICE 'Grant %:', grant_rec.id;
    RAISE NOTICE '  Employee: % (ID: %)', grant_rec.employee_name, grant_rec.employee_id;
    RAISE NOTICE '  Plan: % (ID: %)', grant_rec.plan_name_en, grant_rec.plan_id;
    RAISE NOTICE '  Shares: %', grant_rec.total_shares;
    RAISE NOTICE '  Vesting Start: %', grant_rec.vesting_start_date;
    RAISE NOTICE '  Template ID: %', grant_rec.vesting_schedule_template_id;
    RAISE NOTICE '  Vesting Config: %', grant_rec.vesting_config;
    
    -- Check if this grant has any vesting events
    DECLARE
      v_events_for_grant INTEGER;
    BEGIN
      SELECT COUNT(*) INTO v_events_for_grant 
      FROM vesting_events 
      WHERE grant_id = grant_rec.id;
      
      RAISE NOTICE '  Vesting Events: %', v_events_for_grant;
    END;
    
    RAISE NOTICE '  ---';
  END LOOP;
  
  -- Check vesting schedule templates
  RAISE NOTICE 'Vesting Schedule Templates:';
  FOR plan_rec IN 
    SELECT 
      vs.id,
      vs.name,
      vs.total_duration_months,
      vs.cliff_months,
      vs.vesting_frequency,
      vs.is_template
    FROM vesting_schedules vs
    WHERE vs.is_template = true
    ORDER BY vs.created_at DESC
    LIMIT 5
  LOOP
    RAISE NOTICE '  Template %: % | %mo total | %mo cliff | %', 
      plan_rec.id,
      plan_rec.name,
      plan_rec.total_duration_months,
      plan_rec.cliff_months,
      plan_rec.vesting_frequency;
  END LOOP;
  
  -- Test the vesting event generation function manually
  RAISE NOTICE 'Testing vesting event generation function...';
  
  -- Get the first active grant
  SELECT g.id INTO grant_rec.id
  FROM grants g
  WHERE g.status = 'active'
  LIMIT 1;
  
  IF grant_rec.id IS NOT NULL THEN
    RAISE NOTICE 'Testing with grant ID: %', grant_rec.id;
    
    BEGIN
      -- Try to generate vesting events for this grant
      PERFORM generate_vesting_events_for_grant(grant_rec.id);
      RAISE NOTICE 'Function executed successfully ✓';
      
      -- Check if events were created
      SELECT COUNT(*) INTO v_vesting_events_count 
      FROM vesting_events 
      WHERE grant_id = grant_rec.id;
      
      RAISE NOTICE 'Events created for this grant: %', v_vesting_events_count;
      
    EXCEPTION
      WHEN OTHERS THEN
        RAISE NOTICE 'Error in generate_vesting_events_for_grant: %', SQLERRM;
    END;
  ELSE
    RAISE NOTICE 'No active grants found to test with';
  END IF;
  
  -- Final summary
  SELECT COUNT(*) INTO v_vesting_events_count FROM vesting_events;
  RAISE NOTICE '=== FINAL VESTING EVENTS COUNT: % ===', v_vesting_events_count;
  
END $$;
