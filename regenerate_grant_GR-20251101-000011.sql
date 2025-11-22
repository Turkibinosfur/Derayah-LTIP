/*
  Regenerate Vesting Events for Grant GR-20251101-000011
  
  This will delete and recreate all vesting events for this specific grant
*/

DO $$
DECLARE
  v_grant_id uuid;
  v_template_record RECORD;
  v_milestone_record RECORD;
  v_allocated_shares numeric := 0;
  v_share_amount numeric;
  v_cumulative_shares numeric := 0;
  v_vesting_date date;
  v_event_type text;
  v_deleted_count integer;
  v_created_count integer;
BEGIN
  -- Get the grant ID
  SELECT id INTO v_grant_id
  FROM grants
  WHERE grant_number = 'GR-20251101-000011';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Grant GR-20251101-000011 not found';
  END IF;
  
  RAISE NOTICE 'Found grant, deleting existing vesting events...';
  
  -- Delete existing vesting events
  DELETE FROM vesting_events WHERE grant_id = v_grant_id;
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RAISE NOTICE 'Deleted % existing vesting events', v_deleted_count;
  
  -- Get the template from the grant's plan
  SELECT vs.* INTO v_template_record
  FROM vesting_schedules vs
  JOIN incentive_plans ip ON ip.vesting_schedule_template_id = vs.id
  JOIN grants g ON g.plan_id = ip.id
  WHERE g.id = v_grant_id
    AND vs.is_template = true;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No template found for grant GR-20251101-000011';
  END IF;
  
  RAISE NOTICE 'Found template: %', v_template_record.name;
  
  -- Get total shares
  SELECT total_shares INTO v_allocated_shares FROM grants WHERE id = v_grant_id;
  
  v_allocated_shares := 0;
  v_cumulative_shares := 0;
  
  -- Create vesting events from milestones
  FOR v_milestone_record IN 
    SELECT * FROM vesting_milestones
    WHERE vesting_schedule_id = v_template_record.id
    ORDER BY sequence_order
  LOOP
    -- Calculate share amount
    IF v_milestone_record.sequence_order = (
      SELECT MAX(sequence_order) FROM vesting_milestones WHERE vesting_schedule_id = v_template_record.id
    ) THEN
      SELECT total_shares - v_allocated_shares
      INTO v_share_amount
      FROM grants
      WHERE id = v_grant_id;
    ELSE
      SELECT FLOOR((total_shares * v_milestone_record.vesting_percentage) / 100)
      INTO v_share_amount
      FROM grants
      WHERE id = v_grant_id;
    END IF;
    
    v_allocated_shares := v_allocated_shares + v_share_amount;
    v_cumulative_shares := v_cumulative_shares + v_share_amount;
    
    -- Calculate vesting date
    IF v_milestone_record.months_from_start IS NOT NULL THEN
      SELECT vesting_start_date + (v_milestone_record.months_from_start || ' months')::interval
      INTO v_vesting_date
      FROM grants
      WHERE id = v_grant_id;
    ELSE
      SELECT vesting_start_date INTO v_vesting_date FROM grants WHERE id = v_grant_id;
    END IF;
    
    -- Determine event type
    v_event_type := 'time_based';
    IF v_milestone_record.milestone_type = 'performance' THEN
      v_event_type := 'performance';
    ELSIF v_milestone_record.milestone_type = 'hybrid' THEN
      v_event_type := 'hybrid';
    ELSIF v_milestone_record.sequence_order = 0 AND v_milestone_record.vesting_percentage = 25 THEN
      v_event_type := 'cliff';
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
    )
    SELECT 
      g.id,
      g.employee_id,
      g.company_id,
      v_event_type::vesting_event_type,
      v_milestone_record.sequence_order,
      v_vesting_date,
      v_share_amount,
      v_cumulative_shares,
      true,
      'pending',
      now()
    FROM grants g
    WHERE g.id = v_grant_id;
    
    RAISE NOTICE 'Created event: sequence %, date %, shares %, type %', 
      v_milestone_record.sequence_order, v_vesting_date, v_share_amount, v_event_type;
  END LOOP;
  
  SELECT COUNT(*) INTO v_created_count FROM vesting_events WHERE grant_id = v_grant_id;
  RAISE NOTICE 'Successfully created % vesting events for grant GR-20251101-000011', v_created_count;
  
END $$;

