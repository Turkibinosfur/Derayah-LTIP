/*
  # Generate Vesting Events for Existing Grants
  
  This migration generates vesting events for all existing grants that don't already have vesting events.
  It processes each grant and creates the appropriate vesting schedule based on:
  1. Vesting schedule templates (if linked)
  2. Plan vesting_config (fallback)
  3. Default vesting rules (final fallback)
*/

DO $$
DECLARE
  v_grant_record RECORD;
  v_existing_events_count INTEGER;
  v_total_grants INTEGER := 0;
  v_processed_grants INTEGER := 0;
  v_skipped_grants INTEGER := 0;
  v_error_grants INTEGER := 0;
BEGIN
  RAISE NOTICE 'Starting vesting events generation for existing grants...';
  
  -- Count total grants to process
  SELECT COUNT(*) INTO v_total_grants 
  FROM grants 
  WHERE status = 'active';
  
  RAISE NOTICE 'Found % active grants to process', v_total_grants;
  
  -- Loop through all active grants
  FOR v_grant_record IN 
    SELECT 
      g.id,
      g.employee_id,
      g.company_id,
      g.total_shares,
      g.vesting_start_date,
      g.plan_id,
      g.status,
      COALESCE(e.first_name_en, e.first_name_ar, 'Unknown') as first_name,
      COALESCE(e.last_name_en, e.last_name_ar, 'Employee') as last_name,
      p.plan_name_en,
      p.plan_code
    FROM grants g
    JOIN employees e ON g.employee_id = e.id
    JOIN incentive_plans p ON g.plan_id = p.id
    WHERE g.status = 'active'
    ORDER BY g.created_at ASC
  LOOP
    BEGIN
      -- Check if vesting events already exist for this grant
      SELECT COUNT(*) INTO v_existing_events_count
      FROM vesting_events
      WHERE grant_id = v_grant_record.id;
      
      IF v_existing_events_count > 0 THEN
        RAISE NOTICE 'Grant % (% %) already has % vesting events - skipping', 
          v_grant_record.id, 
          v_grant_record.first_name, 
          v_grant_record.last_name,
          v_existing_events_count;
        v_skipped_grants := v_skipped_grants + 1;
      ELSE
        -- Generate vesting events for this grant
        RAISE NOTICE 'Generating vesting events for grant % (% % - % shares - %)', 
          v_grant_record.id,
          v_grant_record.first_name, 
          v_grant_record.last_name,
          v_grant_record.total_shares,
          v_grant_record.plan_name_en;
        
        -- Call the vesting events generation function
        PERFORM generate_vesting_events_for_grant(v_grant_record.id);
        
        v_processed_grants := v_processed_grants + 1;
        
        -- Verify events were created
        SELECT COUNT(*) INTO v_existing_events_count
        FROM vesting_events
        WHERE grant_id = v_grant_record.id;
        
        RAISE NOTICE '  → Created % vesting events for grant %', 
          v_existing_events_count, 
          v_grant_record.id;
      END IF;
      
    EXCEPTION
      WHEN OTHERS THEN
        v_error_grants := v_error_grants + 1;
        RAISE WARNING 'Error processing grant % (% %): %', 
          v_grant_record.id,
          v_grant_record.first_name, 
          v_grant_record.last_name,
          SQLERRM;
    END;
  END LOOP;
  
  RAISE NOTICE '=== VESTING EVENTS GENERATION SUMMARY ===';
  RAISE NOTICE 'Total grants found: %', v_total_grants;
  RAISE NOTICE 'Grants processed: %', v_processed_grants;
  RAISE NOTICE 'Grants skipped (already had events): %', v_skipped_grants;
  RAISE NOTICE 'Grants with errors: %', v_error_grants;
  
  -- Show final statistics
  DECLARE
    v_total_events INTEGER;
    v_pending_events INTEGER;
    v_due_events INTEGER;
    v_companies_affected INTEGER;
  BEGIN
    SELECT COUNT(*) INTO v_total_events FROM vesting_events;
    SELECT COUNT(*) INTO v_pending_events FROM vesting_events WHERE status = 'pending';
    SELECT COUNT(*) INTO v_due_events FROM vesting_events WHERE status = 'due';
    SELECT COUNT(DISTINCT company_id) INTO v_companies_affected FROM vesting_events;
    
    RAISE NOTICE '=== FINAL STATISTICS ===';
    RAISE NOTICE 'Total vesting events in system: %', v_total_events;
    RAISE NOTICE 'Pending events: %', v_pending_events;
    RAISE NOTICE 'Due events: %', v_due_events;
    RAISE NOTICE 'Companies affected: %', v_companies_affected;
  END;
  
END $$;

-- Update vesting event statuses to mark events that are already due
SELECT update_vesting_event_status();

-- Show sample of created vesting events
DO $$
DECLARE
  rec RECORD;
BEGIN
  RAISE NOTICE '=== SAMPLE VESTING EVENTS ===';
  
  -- Show first 10 upcoming vesting events
  FOR rec IN 
    SELECT 
      ve.id,
      ve.vesting_date,
      ve.shares_to_vest,
      ve.event_type,
      ve.status,
      COALESCE(e.first_name_en, e.first_name_ar, 'Unknown') || ' ' || COALESCE(e.last_name_en, e.last_name_ar, 'Employee') as employee_name,
      p.plan_name_en,
      p.plan_code
    FROM vesting_events ve
    JOIN employees e ON ve.employee_id = e.id
    JOIN grants g ON ve.grant_id = g.id
    JOIN incentive_plans p ON g.plan_id = p.id
    WHERE ve.vesting_date >= CURRENT_DATE
    ORDER BY ve.vesting_date ASC
    LIMIT 10
  LOOP
    RAISE NOTICE 'Event: % | % | % shares | % | % (%)', 
      rec.vesting_date,
      rec.employee_name,
      rec.shares_to_vest,
      rec.event_type,
      rec.plan_name_en,
      rec.plan_code;
  END LOOP;
END $$;

COMMENT ON SCHEMA public IS 'Vesting events have been generated for all existing active grants';
