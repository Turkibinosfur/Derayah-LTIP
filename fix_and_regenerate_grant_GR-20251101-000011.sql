/*
  Fix Template Milestones and Regenerate Vesting Events for Grant GR-20251101-000011
  
  This script will:
  1. Check if the grant's template has milestones
  2. If not, create milestones based on template settings
  3. Regenerate vesting events
*/

DO $$
DECLARE
  v_grant_id uuid;
  v_template_id uuid;
  v_template_record RECORD;
  v_milestone_record RECORD;
  v_milestone_count integer;
  v_allocated_shares numeric := 0;
  v_share_amount numeric;
  v_cumulative_shares numeric := 0;
  v_vesting_date date;
  v_event_type text;
  v_deleted_count integer;
  v_created_count integer;
  v_order integer;
  v_months integer;
  v_percentage numeric;
  v_total_months integer;
  v_cliff_months integer;
  v_frequency integer;
  v_periods integer;
  v_percent_per_period numeric;
  v_i integer;
BEGIN
  -- Get the grant ID
  SELECT id INTO v_grant_id
  FROM grants
  WHERE grant_number = 'GR-20251101-000011';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Grant GR-20251101-000011 not found';
  END IF;
  
  RAISE NOTICE 'Found grant, checking template...';
  
  -- Get the template ID from the grant's plan
  SELECT ip.vesting_schedule_template_id
  INTO v_template_id
  FROM grants g
  JOIN incentive_plans ip ON ip.id = g.plan_id
  WHERE g.id = v_grant_id;
  
  IF v_template_id IS NULL THEN
    RAISE EXCEPTION 'No template found for grant GR-20251101-000011';
  END IF;
  
  RAISE NOTICE 'Found template: %', v_template_id;
  
  -- Get the full template details
  SELECT * INTO v_template_record
  FROM vesting_schedules
  WHERE id = v_template_id
    AND is_template = true;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Template % not found or is not a template', v_template_id;
  END IF;
  
  -- Check if milestones exist
  SELECT COUNT(*) INTO v_milestone_count
  FROM vesting_milestones
  WHERE vesting_schedule_id = v_template_id;
  
  RAISE NOTICE 'Template has % milestones', v_milestone_count;
  
  -- If no milestones exist, create them based on template settings
  IF v_milestone_count = 0 THEN
    RAISE NOTICE 'Creating milestones for template...';
    
    v_order := 0;
    
    -- Create cliff milestone if applicable
    IF v_template_record.cliff_months > 0 THEN
      INSERT INTO vesting_milestones (
        vesting_schedule_id,
        milestone_type,
        sequence_order,
        vesting_percentage,
        months_from_start,
        performance_metric_id,
        target_value
      ) VALUES (
        v_template_id,
        'time',
        v_order,
        25,
        v_template_record.cliff_months,
        NULL,
        NULL
      );
      
      v_order := v_order + 1;
      RAISE NOTICE 'Created cliff milestone: sequence %, months %, percentage 25', 
        v_order - 1, v_template_record.cliff_months;
    END IF;
    
    -- Create regular milestones
    -- Set up variables for milestone creation
    v_total_months := v_template_record.total_duration_months;
    v_cliff_months := v_template_record.cliff_months;
    
    -- Determine frequency
    IF v_template_record.vesting_frequency = 'monthly' THEN
      v_frequency := 1;
    ELSIF v_template_record.vesting_frequency = 'quarterly' THEN
      v_frequency := 3;
    ELSE -- annually
      v_frequency := 12;
    END IF;
    
    -- Calculate periods after cliff
    v_periods := FLOOR((v_total_months - v_cliff_months) / v_frequency);
    v_percent_per_period := 75.0 / v_periods;
    
    RAISE NOTICE 'Creating % regular milestones with % each', v_periods, v_percent_per_period;
    
    -- Create each milestone
    FOR v_i IN 1..v_periods LOOP
      v_months := v_cliff_months + (v_i * v_frequency);
      
      INSERT INTO vesting_milestones (
        vesting_schedule_id,
        milestone_type,
        sequence_order,
        vesting_percentage,
        months_from_start,
        performance_metric_id,
        target_value
      ) VALUES (
        v_template_id,
        'time',
        v_order,
        v_percent_per_period,
        v_months,
        NULL,
        NULL
      );
      
      RAISE NOTICE 'Created milestone: sequence %, months %, percentage %', 
        v_order, v_months, v_percent_per_period;
      
      v_order := v_order + 1;
    END LOOP;
    
    RAISE NOTICE 'Created % total milestones', v_order;
  END IF;
  
  -- Now regenerate vesting events
  RAISE NOTICE 'Deleting existing vesting events...';
  
  DELETE FROM vesting_events WHERE grant_id = v_grant_id;
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RAISE NOTICE 'Deleted % existing vesting events', v_deleted_count;
  
  v_allocated_shares := 0;
  v_cumulative_shares := 0;
  
  -- Create vesting events from milestones
  FOR v_milestone_record IN 
    SELECT * FROM vesting_milestones
    WHERE vesting_schedule_id = v_template_id
    ORDER BY sequence_order
  LOOP
    -- Calculate share amount
    IF v_milestone_record.sequence_order = (
      SELECT MAX(sequence_order) FROM vesting_milestones WHERE vesting_schedule_id = v_template_id
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

