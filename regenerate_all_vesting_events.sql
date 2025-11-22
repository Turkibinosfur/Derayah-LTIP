/*
  Regenerate Vesting Events for All Grants
  
  This script will:
  1. Find all grants that have a vesting_schedule_template_id linked to their plan
  2. Delete existing vesting_events for those grants
  3. Re-insert vesting_events based on the template milestones
  
  ⚠️ WARNING: This will delete ALL existing vesting_events for grants with templates!
  ⚠️ Only run this if you understand the implications!
  
  Usage:
  Run this in your Supabase SQL Editor after applying the frontend fixes.
*/

DO $$
DECLARE
  v_grant_record RECORD;
  v_template_record RECORD;
  v_milestone_record RECORD;
  v_allocated_shares numeric := 0;
  v_share_amount numeric;
  v_total_shares numeric;
  v_cumulative_shares numeric := 0;
  v_vesting_date date;
  v_event_type text;
  v_deleted_count integer;
  v_created_count integer;
BEGIN
  RAISE NOTICE 'Starting vesting events regeneration for all grants with templates...';
  
  -- Loop through all grants that have a template linked to their plan
  FOR v_grant_record IN 
    SELECT 
      g.id as grant_id,
      g.grant_number,
      g.employee_id,
      g.company_id,
      g.total_shares,
      g.vesting_start_date,
      ip.vesting_schedule_template_id
    FROM grants g
    JOIN incentive_plans ip ON ip.id = g.plan_id
    WHERE ip.vesting_schedule_template_id IS NOT NULL
  LOOP
    RAISE NOTICE 'Processing grant: %', v_grant_record.grant_number;
    
    -- Get the template with its milestones
    SELECT * INTO v_template_record
    FROM vesting_schedules
    WHERE id = v_grant_record.vesting_schedule_template_id
      AND is_template = true;
    
    IF NOT FOUND THEN
      RAISE NOTICE '  ⚠️  Template not found for grant %, skipping', v_grant_record.grant_number;
      CONTINUE;
    END IF;
    
    -- Delete existing vesting events for this grant
    DELETE FROM vesting_events WHERE grant_id = v_grant_record.grant_id;
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RAISE NOTICE '  → Deleted % existing vesting events', v_deleted_count;
    
    v_allocated_shares := 0;
    v_cumulative_shares := 0;
    
    -- Loop through milestones ordered by sequence_order
    FOR v_milestone_record IN 
      SELECT * FROM vesting_milestones
      WHERE vesting_schedule_id = v_template_record.id
      ORDER BY sequence_order
    LOOP
      -- Calculate share amount for this milestone
      -- Last milestone gets the remainder to ensure total matches
      IF v_milestone_record.sequence_order = (
        SELECT MAX(sequence_order) 
        FROM vesting_milestones 
        WHERE vesting_schedule_id = v_template_record.id
      ) THEN
        -- Last milestone: assign remaining shares
        v_share_amount := v_grant_record.total_shares - v_allocated_shares;
      ELSE
        -- Not last: calculate based on percentage
        v_share_amount := FLOOR((v_grant_record.total_shares * v_milestone_record.vesting_percentage) / 100);
      END IF;
      
      v_allocated_shares := v_allocated_shares + v_share_amount;
      v_cumulative_shares := v_cumulative_shares + v_share_amount;
      
      -- Calculate vesting date
      IF v_milestone_record.months_from_start IS NOT NULL THEN
        v_vesting_date := v_grant_record.vesting_start_date + (v_milestone_record.months_from_start || ' months')::interval;
      ELSE
        v_vesting_date := v_grant_record.vesting_start_date;
      END IF;
      
      -- Determine event type
      IF v_milestone_record.milestone_type = 'time' THEN
        v_event_type := 'time_based';
      ELSIF v_milestone_record.milestone_type = 'performance' THEN
        v_event_type := 'performance';
      ELSIF v_milestone_record.milestone_type = 'hybrid' THEN
        v_event_type := 'hybrid';
      ELSIF v_milestone_record.sequence_order = 0 AND v_milestone_record.vesting_percentage = 25 THEN
        v_event_type := 'cliff';
      ELSE
        v_event_type := 'time_based';
      END IF;
      
      -- Insert the vesting event
      INSERT INTO vesting_events (
        grant_id,
        employee_id,
        company_id,
        event_type,
        sequence_number,
        vesting_date,
        shares_to_vest,
        cumulative_shares_vested,
        performance_condition_met,
        status,
        created_at
      ) VALUES (
        v_grant_record.grant_id,
        v_grant_record.employee_id,
        v_grant_record.company_id,
        v_event_type::vesting_event_type,
        v_milestone_record.sequence_order,
        v_vesting_date,
        v_share_amount,
        v_cumulative_shares,
        COALESCE(v_milestone_record.performance_condition_met, true),
        'pending',
        now()
      );
      
      RAISE NOTICE '  → Created event: sequence %%, date %, shares %, type %%', 
        v_milestone_record.sequence_order,
        v_vesting_date,
        v_share_amount,
        v_event_type;
    END LOOP;
    
    -- Get created count
    SELECT COUNT(*) INTO v_created_count 
    FROM vesting_events 
    WHERE grant_id = v_grant_record.grant_id;
    
    RAISE NOTICE '  ✓ Created % total events for grant %%', v_created_count, v_grant_record.grant_number;
  END LOOP;
  
  RAISE NOTICE '=======================================';
  RAISE NOTICE 'Regeneration complete!';
  
EXCEPTION 
  WHEN OTHERS THEN
    RAISE NOTICE 'Error occurred: %%', SQLERRM;
    RAISE;
END $$;

