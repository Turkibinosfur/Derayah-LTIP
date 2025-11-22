-- Comprehensive utility to regenerate vesting events for grant GR-20251101-000010
-- This script deletes existing events and provides instructions for regeneration

DO $$
DECLARE
  v_grant_id uuid;
  v_grant_number text;
  v_total_shares numeric;
  v_plan_id uuid;
  v_plan_template_id uuid;
  v_template_id uuid;
  v_existing_events_count integer;
  v_total_shares_check numeric;
BEGIN
  RAISE NOTICE '=== VESTING EVENTS REGENERATION UTILITY ===';
  RAISE NOTICE '';
  
  -- Get grant details
  SELECT g.id, g.grant_number, g.total_shares, g.plan_id
  INTO v_grant_id, v_grant_number, v_total_shares, v_plan_id
  FROM grants g
  WHERE g.grant_number = 'GR-20251101-000010';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Grant GR-20251101-000010 not found';
  END IF;
  
  RAISE NOTICE 'Grant Found: %', v_grant_number;
  RAISE NOTICE 'Grant ID: %', v_grant_id;
  RAISE NOTICE 'Total Shares: %', v_total_shares;
  RAISE NOTICE '';
  
  -- Get plan template ID
  SELECT vesting_schedule_template_id INTO v_plan_template_id
  FROM incentive_plans
  WHERE id = v_plan_id;
  
  IF v_plan_template_id IS NULL THEN
    RAISE EXCEPTION 'Plan does not have a vesting schedule template';
  END IF;
  
  v_template_id := v_plan_template_id;
  
  -- Count existing events and sum their shares
  SELECT COUNT(*), COALESCE(SUM(shares_to_vest), 0)
  INTO v_existing_events_count, v_total_shares_check
  FROM vesting_events
  WHERE grant_id = v_grant_id;
  
  RAISE NOTICE '=== CURRENT STATE ===';
  RAISE NOTICE 'Existing Events: %', v_existing_events_count;
  RAISE NOTICE 'Shares in Events: %', v_total_shares_check;
  RAISE NOTICE 'Expected Shares: %', v_total_shares;
  RAISE NOTICE 'SHARES MISSING: %', (v_total_shares - v_total_shares_check);
  RAISE NOTICE '';
  
  -- Show template details
  RAISE NOTICE '=== TEMPLATE DETAILS ===';
  DECLARE
    template_rec RECORD;
    milestone_rec RECORD;
    total_percentage numeric := 0;
  BEGIN
    SELECT id, name, cliff_months, total_duration_months, vesting_frequency
    INTO template_rec
    FROM vesting_schedules
    WHERE id = v_template_id AND is_template = true;
    
    RAISE NOTICE 'Template Name: %', template_rec.name;
    RAISE NOTICE 'Template ID: %', template_rec.id;
    RAISE NOTICE 'Cliff Months: %', template_rec.cliff_months;
    RAISE NOTICE 'Total Duration: % months', template_rec.total_duration_months;
    RAISE NOTICE 'Frequency: %', template_rec.vesting_frequency;
    RAISE NOTICE '';
    
    RAISE NOTICE '=== MILESTONES ===';
    FOR milestone_rec IN
      SELECT sequence_order, vesting_percentage, months_from_start, milestone_type
      FROM vesting_milestones
      WHERE vesting_schedule_id = v_template_id
      ORDER BY sequence_order
    LOOP
      total_percentage := total_percentage + milestone_rec.vesting_percentage;
      RAISE NOTICE 'Sequence %: %%%% at month % (type: %)', 
        milestone_rec.sequence_order,
        milestone_rec.vesting_percentage,
        milestone_rec.months_from_start,
        milestone_rec.milestone_type;
    END LOOP;
    RAISE NOTICE '';
    RAISE NOTICE 'Total Percentage: %%%%', total_percentage;
    RAISE NOTICE '';
    
    -- Calculate expected shares per milestone
    RAISE NOTICE '=== EXPECTED CALCULATION FOR % SHARES ===', v_total_shares;
    FOR milestone_rec IN
      SELECT sequence_order, vesting_percentage, months_from_start, milestone_type
      FROM vesting_milestones
      WHERE vesting_schedule_id = v_template_id
      ORDER BY sequence_order
    LOOP
      DECLARE
        v_shares_calc numeric;
        v_is_last boolean;
      BEGIN
        -- Check if this is the last milestone
        SELECT COUNT(*) = (SELECT COUNT(*) FROM vesting_milestones WHERE vesting_schedule_id = v_template_id)
        INTO v_is_last
        WHERE sequence_order >= milestone_rec.sequence_order
        AND vesting_schedule_id = v_template_id;
        
        IF v_is_last THEN
          -- Last milestone gets remainder (calculated below)
          RAISE NOTICE 'Sequence %: %%%% = REMAINDER (last milestone)';
        ELSE
          v_shares_calc := FLOOR(v_total_shares * milestone_rec.vesting_percentage / 100);
          RAISE NOTICE 'Sequence %: %%%% = % shares', 
            milestone_rec.sequence_order,
            milestone_rec.vesting_percentage,
            v_shares_calc;
        END IF;
      END;
    END LOOP;
  END;
  
  RAISE NOTICE '';
  RAISE NOTICE '=== DELETING EXISTING EVENTS ===';
  DELETE FROM vesting_events WHERE grant_id = v_grant_id;
  RAISE NOTICE 'Deleted % vesting events', v_existing_events_count;
  RAISE NOTICE '';
  
  RAISE NOTICE '=== NEXT STEPS ===';
  RAISE NOTICE 'Vesting events have been deleted.';
  RAISE NOTICE '';
  RAISE NOTICE 'To regenerate with correct calculations:';
  RAISE NOTICE '1. Go to the Company Portal > Vesting Events page';
  RAISE NOTICE '2. Click "Generate Events" button';
  RAISE NOTICE '3. Confirm regeneration for this grant';
  RAISE NOTICE '';
  RAISE NOTICE 'OR use the JavaScript API:';
  RAISE NOTICE '  generateIndividualVestingRecords(''%'', ''%'')', v_grant_id, v_template_id;
  RAISE NOTICE '';
  RAISE NOTICE '=== REGENERATION COMPLETE ===';
  
END $$;

-- Show current state after deletion
SELECT 
  'After deletion' as status,
  COUNT(*) as event_count,
  COALESCE(SUM(shares_to_vest), 0) as total_shares
FROM vesting_events
WHERE grant_id = (SELECT id FROM grants WHERE grant_number = 'GR-20251101-000010');

