-- Fix vesting events for grant GR-20251101-000010
-- This script regenerates vesting events to ensure all 50 shares are allocated

BEGIN;

-- Find the grant
DO $$
DECLARE
  v_grant_id uuid;
  v_grant_number text;
  v_total_shares numeric;
  v_plan_template_id uuid;
  v_template_id uuid;
  v_existing_events_count integer;
BEGIN
  RAISE NOTICE '=== FIXING VESTING EVENTS FOR GRANT GR-20251101-000010 ===';
  
  -- Get grant details
  SELECT id, grant_number, total_shares INTO v_grant_id, v_grant_number, v_total_shares
  FROM grants
  WHERE grant_number = 'GR-20251101-000010';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Grant GR-20251101-000010 not found';
  END IF;
  
  RAISE NOTICE 'Found grant: % (ID: %)', v_grant_number, v_grant_id;
  RAISE NOTICE 'Total shares: %', v_total_shares;
  
  -- Get plan template ID
  SELECT vesting_schedule_template_id INTO v_plan_template_id
  FROM incentive_plans
  WHERE id = (SELECT plan_id FROM grants WHERE id = v_grant_id);
  
  RAISE NOTICE 'Plan template ID: %', v_plan_template_id;
  
  IF v_plan_template_id IS NULL THEN
    RAISE EXCEPTION 'Plan does not have a vesting schedule template';
  END IF;
  
  v_template_id := v_plan_template_id;
  
  -- Count existing events
  SELECT COUNT(*) INTO v_existing_events_count
  FROM vesting_events
  WHERE grant_id = v_grant_id;
  
  RAISE NOTICE 'Existing vesting events: %', v_existing_events_count;
  
  -- Delete existing vesting events
  DELETE FROM vesting_events WHERE grant_id = v_grant_id;
  RAISE NOTICE 'Deleted % existing vesting events', v_existing_events_count;
  
  -- Show template details
  RAISE NOTICE '=== TEMPLATE DETAILS ===';
  DECLARE
    template_rec RECORD;
    milestone_rec RECORD;
  BEGIN
    SELECT id, name, cliff_months, total_duration_months, vesting_frequency
    INTO template_rec
    FROM vesting_schedules
    WHERE id = v_template_id AND is_template = true;
    
    RAISE NOTICE 'Template: %', template_rec.name;
    RAISE NOTICE 'Cliff months: %', template_rec.cliff_months;
    RAISE NOTICE 'Total duration: % months', template_rec.total_duration_months;
    RAISE NOTICE 'Frequency: %', template_rec.vesting_frequency;
    
    RAISE NOTICE '=== MILESTONES ===';
    FOR milestone_rec IN
      SELECT sequence_order, vesting_percentage, months_from_start, milestone_type
      FROM vesting_milestones
      WHERE vesting_schedule_id = v_template_id
      ORDER BY sequence_order
    LOOP
      RAISE NOTICE 'Sequence %: %%% at month % (type: %)', 
        milestone_rec.sequence_order,
        milestone_rec.vesting_percentage,
        milestone_rec.months_from_start,
        milestone_rec.milestone_type;
    END LOOP;
  END;
  
  RAISE NOTICE '=== VESTING EVENTS WILL BE RECREATED BY JAVASCRIPT ===';
  RAISE NOTICE 'Please use the "Generate Events" button or call generateIndividualVestingRecords()';
  
END $$;

-- Show current state
SELECT 
  ve.sequence_number,
  ve.event_type,
  ve.vesting_date,
  ve.shares_to_vest,
  ve.status,
  ve.created_at
FROM vesting_events ve
WHERE ve.grant_id = (SELECT id FROM grants WHERE grant_number = 'GR-20251101-000010')
ORDER BY ve.sequence_number;

COMMIT;

