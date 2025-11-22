-- Generate vesting events for all active grants
-- Run this after running the fix_vesting_function.sql

DO $$
DECLARE
  grant_rec RECORD;
  v_events_created INTEGER := 0;
  v_grants_processed INTEGER := 0;
BEGIN
  RAISE NOTICE '=== GENERATING VESTING EVENTS FOR ALL ACTIVE GRANTS ===';
  
  -- Process each active grant
  FOR grant_rec IN 
    SELECT 
      g.id,
      g.total_shares,
      g.vesting_start_date,
      COALESCE(e.first_name_en, e.first_name_ar, 'Unknown') || ' ' || COALESCE(e.last_name_en, e.last_name_ar, 'Employee') as employee_name,
      p.plan_name_en,
      p.plan_code
    FROM grants g
    LEFT JOIN employees e ON g.employee_id = e.id
    LEFT JOIN incentive_plans p ON g.plan_id = p.id
    WHERE g.status = 'active'
    ORDER BY g.created_at DESC
  LOOP
    v_grants_processed := v_grants_processed + 1;
    
    RAISE NOTICE 'Processing Grant %: % - % shares for %', 
      v_grants_processed, grant_rec.id, grant_rec.total_shares, grant_rec.employee_name;
    
    -- Generate vesting events for this grant
    BEGIN
      PERFORM generate_vesting_events_for_grant(grant_rec.id);
      
      -- Count events created for this grant
      DECLARE
        v_grant_events INTEGER;
      BEGIN
        SELECT COUNT(*) INTO v_grant_events
        FROM vesting_events
        WHERE grant_id = grant_rec.id;
        
        v_events_created := v_events_created + v_grant_events;
        RAISE NOTICE '  → Created % vesting events', v_grant_events;
      END;
      
    EXCEPTION
      WHEN OTHERS THEN
        RAISE NOTICE '  → ERROR: %', SQLERRM;
    END;
    
    RAISE NOTICE '  ---';
  END LOOP;
  
  RAISE NOTICE '=== SUMMARY ===';
  RAISE NOTICE 'Grants processed: %', v_grants_processed;
  RAISE NOTICE 'Total vesting events created: %', v_events_created;
  
  -- Show sample of created events
  IF v_events_created > 0 THEN
    RAISE NOTICE '=== SAMPLE VESTING EVENTS ===';
    
    DECLARE
      event_rec RECORD;
    BEGIN
      FOR event_rec IN
        SELECT 
          ve.vesting_date,
          ve.shares_to_vest,
          ve.event_type,
          ve.status,
          COALESCE(e.first_name_en, e.first_name_ar, 'Unknown') || ' ' || COALESCE(e.last_name_en, e.last_name_ar, 'Employee') as employee_name,
          p.plan_name_en
        FROM vesting_events ve
        JOIN grants g ON ve.grant_id = g.id
        JOIN employees e ON ve.employee_id = e.id
        JOIN incentive_plans p ON g.plan_id = p.id
        WHERE ve.vesting_date >= CURRENT_DATE
        ORDER BY ve.vesting_date ASC
        LIMIT 10
      LOOP
        RAISE NOTICE 'Event: % | % | % shares | % | %', 
          event_rec.vesting_date,
          event_rec.employee_name,
          event_rec.shares_to_vest,
          event_rec.event_type,
          event_rec.plan_name_en;
      END LOOP;
    END;
  END IF;
END $$;
