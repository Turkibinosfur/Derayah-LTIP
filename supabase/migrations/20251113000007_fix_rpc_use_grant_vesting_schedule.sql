-- Fix the generate_vesting_events_for_grant function to use the grant's selected vesting_schedule_id
-- if available, before falling back to the plan's template
-- Also check for milestones first and use them if they exist (like the client-side function)

CREATE OR REPLACE FUNCTION generate_vesting_events_for_grant(p_grant_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_grant grants%ROWTYPE;
  v_plan incentive_plans%ROWTYPE;
  v_template vesting_schedules%ROWTYPE;
  v_grant_schedule vesting_schedules%ROWTYPE;
  v_vesting_config jsonb;
  v_start_date date;
  v_cliff_months integer;
  v_total_months integer;
  v_frequency text;
  v_frequency_months integer;
  v_total_periods integer;
  v_shares_per_period numeric;
  v_cliff_shares numeric;
  v_current_date date;
  v_cumulative_shares numeric := 0;
  v_sequence integer := 1;
  v_exercise_price numeric;
  v_allocated_shares numeric := 0;
  v_shares_this_period numeric;
  v_use_even_distribution boolean;
  v_has_even_distribution_col boolean;
  v_has_vesting_schedule_id_col boolean;
  v_has_exercise_price_col boolean;
  v_grant_vesting_schedule_id uuid;
  -- Milestone tracking variables
  v_schedule_id_for_milestones uuid;
  v_milestones_count integer := 0;
  v_has_milestones boolean := false;
  v_milestone_record RECORD;
  v_event_type text;
  v_max_sequence_order integer;
BEGIN
  -- Check if use_even_distribution column exists in the table
  SELECT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'grants' 
    AND column_name = 'use_even_distribution'
  ) INTO v_has_even_distribution_col;

  -- Check if vesting_schedule_id column exists in the table
  SELECT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'grants' 
    AND column_name = 'vesting_schedule_id'
  ) INTO v_has_vesting_schedule_id_col;

  -- Check if exercise_price column exists in the table
  SELECT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'grants' 
    AND column_name = 'exercise_price'
  ) INTO v_has_exercise_price_col;

  -- Get grant details
  BEGIN
    SELECT * INTO v_grant FROM grants WHERE id = p_grant_id;
  EXCEPTION WHEN OTHERS THEN
    -- If SELECT * fails (e.g., due to column mismatch), try to get specific columns
    -- This can happen if the function was created before a column was added
    RAISE EXCEPTION 'Failed to load grant: %', SQLERRM;
  END;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Grant not found: %', p_grant_id;
  END IF;

  -- Get even distribution preference from grant (only if column exists)
  -- We need to check this separately because accessing v_grant.use_even_distribution
  -- will fail if the column doesn't exist in the ROWTYPE
  IF v_has_even_distribution_col THEN
    BEGIN
      -- Query the column separately to safely access it
      EXECUTE format('SELECT use_even_distribution FROM grants WHERE id = $1')
      USING p_grant_id
      INTO v_use_even_distribution;
      v_use_even_distribution := COALESCE(v_use_even_distribution, false);
    EXCEPTION WHEN OTHERS THEN
      v_use_even_distribution := false;
    END;
  ELSE
    v_use_even_distribution := false;
  END IF;

  -- Get plan details
  SELECT * INTO v_plan FROM incentive_plans WHERE id = v_grant.plan_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Plan not found: %', v_grant.plan_id;
  END IF;

  -- Get vesting schedule details
  v_start_date := v_grant.vesting_start_date;
  
  -- PRIORITY 1: Check if grant has a selected vesting_schedule_id (only if column exists)
  IF v_has_vesting_schedule_id_col THEN
    BEGIN
      -- Query the column separately to safely access it
      EXECUTE format('SELECT vesting_schedule_id FROM grants WHERE id = $1')
      USING p_grant_id
      INTO v_grant_vesting_schedule_id;
      
      IF v_grant_vesting_schedule_id IS NOT NULL THEN
        SELECT * INTO v_grant_schedule 
        FROM vesting_schedules 
        WHERE id = v_grant_vesting_schedule_id;
        
        IF FOUND THEN
          v_cliff_months := v_grant_schedule.cliff_months;
          v_total_months := v_grant_schedule.total_duration_months;
          v_frequency := v_grant_schedule.vesting_frequency;
          RAISE NOTICE 'Using grant-selected vesting schedule: % (%, % months, % month cliff)', 
            v_grant_schedule.name, v_frequency, v_total_months, v_cliff_months;
        END IF;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      -- If accessing the column fails, continue without it
      NULL;
    END;
  END IF;
  
  -- PRIORITY 2: Try to get template details from plan
  IF v_grant_schedule IS NULL AND v_plan.vesting_schedule_template_id IS NOT NULL THEN
    SELECT * INTO v_template 
    FROM vesting_schedules 
    WHERE id = v_plan.vesting_schedule_template_id AND is_template = true;
    
    IF FOUND THEN
      v_cliff_months := v_template.cliff_months;
      v_total_months := v_template.total_duration_months;
      v_frequency := v_template.vesting_frequency;
      RAISE NOTICE 'Using plan template vesting schedule: % (%, % months, % month cliff)', 
        v_template.name, v_frequency, v_total_months, v_cliff_months;
    END IF;
  END IF;

  -- PRIORITY 3: Fallback to vesting_config
  IF v_grant_schedule IS NULL AND v_template IS NULL THEN
    v_vesting_config := COALESCE(v_plan.vesting_config, '{}'::jsonb);
    v_cliff_months := COALESCE((v_vesting_config->>'cliff_months')::integer, 12);
    v_total_months := COALESCE((v_vesting_config->>'years')::integer * 12, 48);
    v_frequency := COALESCE(v_vesting_config->>'frequency', 'monthly');
    RAISE NOTICE 'Using plan vesting_config: %, % months, % month cliff', 
      v_frequency, v_total_months, v_cliff_months;
  END IF;

  -- Determine which schedule ID to check for milestones
  IF v_grant_vesting_schedule_id IS NOT NULL THEN
    v_schedule_id_for_milestones := v_grant_vesting_schedule_id;
  ELSIF v_plan.vesting_schedule_template_id IS NOT NULL THEN
    v_schedule_id_for_milestones := v_plan.vesting_schedule_template_id;
  ELSE
    v_schedule_id_for_milestones := NULL;
  END IF;

  -- Check if milestones exist for this schedule
  IF v_schedule_id_for_milestones IS NOT NULL THEN
    SELECT COUNT(*) INTO v_milestones_count
    FROM vesting_milestones
    WHERE vesting_schedule_id = v_schedule_id_for_milestones
    AND months_from_start IS NOT NULL
    AND months_from_start > 0;

    IF v_milestones_count > 0 THEN
      v_has_milestones := true;
      RAISE NOTICE 'Found % milestones for schedule %, using milestones instead of frequency', 
        v_milestones_count, v_schedule_id_for_milestones;
    ELSE
      -- No milestones found - generate them from schedule settings (like client-side function)
      RAISE NOTICE 'No milestones found for schedule %, generating them from schedule settings', 
        v_schedule_id_for_milestones;
      
      -- Get the schedule to generate milestones from
      DECLARE
        v_schedule_for_milestones vesting_schedules%ROWTYPE;
        v_milestone_frequency integer;
        v_milestone_periods integer;
        v_milestone_percentage numeric;
        v_milestone_order integer := 0;
        v_milestone_type milestone_type;
      BEGIN
        SELECT * INTO v_schedule_for_milestones
        FROM vesting_schedules
        WHERE id = v_schedule_id_for_milestones;
        
        IF FOUND THEN
          -- Determine milestone type from schedule type
          v_milestone_type := CASE v_schedule_for_milestones.schedule_type
            WHEN 'time_based' THEN 'time'::milestone_type
            WHEN 'performance_based' THEN 'performance'::milestone_type
            WHEN 'hybrid' THEN 'hybrid'::milestone_type
            ELSE 'time'::milestone_type
          END;
          
          -- Calculate frequency in months
          v_milestone_frequency := CASE v_schedule_for_milestones.vesting_frequency
            WHEN 'monthly' THEN 1
            WHEN 'quarterly' THEN 3
            WHEN 'annually' THEN 12
            ELSE 1
          END;
          
          -- Generate cliff milestone if applicable
          IF v_schedule_for_milestones.cliff_months > 0 THEN
            INSERT INTO vesting_milestones (
              vesting_schedule_id,
              milestone_type,
              sequence_order,
              vesting_percentage,
              months_from_start
            ) VALUES (
              v_schedule_id_for_milestones,
              v_milestone_type,
              v_milestone_order,
              25.0,
              v_schedule_for_milestones.cliff_months
            );
            v_milestone_order := v_milestone_order + 1;
            v_milestones_count := v_milestones_count + 1;
          END IF;
          
          -- Generate regular milestones
          v_milestone_periods := FLOOR((v_schedule_for_milestones.total_duration_months - v_schedule_for_milestones.cliff_months)::numeric / v_milestone_frequency);
          IF v_milestone_periods > 0 THEN
            v_milestone_percentage := 75.0 / v_milestone_periods;
            
            FOR i IN 1..v_milestone_periods LOOP
              INSERT INTO vesting_milestones (
                vesting_schedule_id,
                milestone_type,
                sequence_order,
                vesting_percentage,
                months_from_start
              ) VALUES (
                v_schedule_id_for_milestones,
                v_milestone_type,
                v_milestone_order,
                v_milestone_percentage,
                v_schedule_for_milestones.cliff_months + (i * v_milestone_frequency)
              );
              v_milestone_order := v_milestone_order + 1;
              v_milestones_count := v_milestones_count + 1;
            END LOOP;
          END IF;
          
          v_has_milestones := true;
          RAISE NOTICE 'Generated % milestones for schedule % (frequency: % months, periods: %)', 
            v_milestones_count, v_schedule_id_for_milestones, v_milestone_frequency, v_milestone_periods;
        END IF;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Error generating milestones: %, continuing with frequency-based calculation', SQLERRM;
        v_has_milestones := false;
      END;
    END IF;
  END IF;

  -- Set exercise price for ESOP plans (only if column exists)
  IF v_plan.plan_type = 'ESOP' THEN
    IF v_has_exercise_price_col THEN
      BEGIN
        EXECUTE format('SELECT exercise_price FROM grants WHERE id = $1')
        USING p_grant_id
        INTO v_exercise_price;
        v_exercise_price := COALESCE(v_exercise_price, 1.0);
      EXCEPTION WHEN OTHERS THEN
        v_exercise_price := 1.0;
      END;
    ELSE
      v_exercise_price := 1.0;
    END IF;
  ELSE
    v_exercise_price := NULL;
  END IF;

  -- If milestones exist, use them to create vesting events
  IF v_has_milestones THEN
    -- Get max sequence order for last milestone check
    SELECT MAX(sequence_order) INTO v_max_sequence_order
    FROM vesting_milestones
    WHERE vesting_schedule_id = v_schedule_id_for_milestones;

    -- Create vesting events from milestones
    FOR v_milestone_record IN
      SELECT 
        sequence_order,
        vesting_percentage,
        months_from_start,
        milestone_type
      FROM vesting_milestones
      WHERE vesting_schedule_id = v_schedule_id_for_milestones
      AND months_from_start IS NOT NULL
      AND months_from_start > 0
      ORDER BY sequence_order
    LOOP
      -- Calculate shares for this milestone
      IF v_use_even_distribution THEN
        -- Even distribution: divide shares equally among all milestones
        v_shares_this_period := FLOOR(v_grant.total_shares::numeric / v_milestones_count);
      ELSE
        -- Percentage-based: use milestone's vesting_percentage
        v_shares_this_period := FLOOR(v_grant.total_shares::numeric * (v_milestone_record.vesting_percentage / 100.0));
      END IF;

      -- Last milestone gets all remaining shares to ensure total equals grant total
      IF v_milestone_record.sequence_order = v_max_sequence_order THEN
        v_shares_this_period := v_grant.total_shares - v_allocated_shares;
      END IF;

      -- Only insert if shares > 0
      IF v_shares_this_period > 0 THEN
        v_allocated_shares := v_allocated_shares + v_shares_this_period;
        v_cumulative_shares := v_allocated_shares;
        v_current_date := v_start_date + (v_milestone_record.months_from_start || ' months')::interval;

        -- Determine event type based on milestone type
        v_event_type := CASE v_milestone_record.milestone_type
          WHEN 'time' THEN 'time_based'
          WHEN 'performance' THEN 'performance_based'
          WHEN 'hybrid' THEN 'performance_based'
          ELSE 'time_based'
        END;

        -- Check if this is the cliff (first milestone at cliff months)
        -- The cliff is the first milestone that occurs at the cliff_months date
        IF v_cliff_months > 0 
           AND v_milestone_record.months_from_start = v_cliff_months
           AND v_milestone_record.sequence_order = (
             SELECT MIN(sequence_order) 
             FROM vesting_milestones 
             WHERE vesting_schedule_id = v_schedule_id_for_milestones
           ) THEN
          v_event_type := 'cliff';
        END IF;

        INSERT INTO vesting_events (
          grant_id, employee_id, company_id, event_type, sequence_number,
          vesting_date, shares_to_vest, cumulative_shares_vested,
          exercise_price, total_exercise_cost
        ) VALUES (
          p_grant_id, v_grant.employee_id, v_grant.company_id, v_event_type::vesting_event_type, v_sequence,
          v_current_date, v_shares_this_period, v_cumulative_shares,
          v_exercise_price,
          CASE WHEN v_exercise_price IS NOT NULL THEN v_shares_this_period * v_exercise_price ELSE NULL END
        );

        v_sequence := v_sequence + 1;
      END IF;
    END LOOP;

    RAISE NOTICE 'Generated % vesting events from milestones for grant % (total shares: %, allocated: %, even_distribution: %)', 
      v_sequence - 1, p_grant_id, v_grant.total_shares, v_allocated_shares, v_use_even_distribution;
  ELSE
    -- No milestones: use frequency-based calculation (existing logic)
    -- Calculate frequency in months
    v_frequency_months := CASE v_frequency
      WHEN 'monthly' THEN 1
      WHEN 'quarterly' THEN 3
      WHEN 'annually' THEN 12
      ELSE 1
    END;

    -- Calculate periods and shares
    -- Use FLOOR instead of CEIL to match client-side calculation
    v_total_periods := FLOOR((v_total_months - v_cliff_months)::numeric / v_frequency_months);
    
    RAISE NOTICE 'No milestones found, using frequency-based calculation: total_months=%, cliff_months=%, frequency_months=%, total_periods=%', 
      v_total_months, v_cliff_months, v_frequency_months, v_total_periods;
    
    -- Calculate shares based on distribution method
    IF v_use_even_distribution THEN
      -- Even distribution: divide shares equally among all periods (including cliff)
      IF v_cliff_months > 0 THEN
        -- With cliff: cliff gets equal share, rest divided equally
        v_cliff_shares := FLOOR(v_grant.total_shares::numeric / (v_total_periods + 1));
        v_shares_per_period := FLOOR((v_grant.total_shares::numeric - v_cliff_shares) / v_total_periods);
      ELSE
        -- No cliff: divide equally among all periods
        v_shares_per_period := FLOOR(v_grant.total_shares::numeric / v_total_periods);
        v_cliff_shares := 0;
      END IF;
    ELSE
      -- Percentage-based with floor (existing logic)
      IF v_cliff_months > 0 THEN
        v_cliff_shares := FLOOR(v_grant.total_shares::numeric * 0.25);
        v_shares_per_period := FLOOR((v_grant.total_shares::numeric - v_cliff_shares) / v_total_periods);
      ELSE
        v_cliff_shares := 0;
        v_shares_per_period := FLOOR(v_grant.total_shares::numeric / v_total_periods);
      END IF;
    END IF;

    -- Create cliff event if applicable
    IF v_cliff_months > 0 AND v_cliff_shares > 0 THEN
      v_current_date := v_start_date + (v_cliff_months || ' months')::interval;
      v_cumulative_shares := v_cliff_shares;
      v_allocated_shares := v_cliff_shares;
      
      INSERT INTO vesting_events (
        grant_id, employee_id, company_id, event_type, sequence_number,
        vesting_date, shares_to_vest, cumulative_shares_vested,
        exercise_price, total_exercise_cost
      ) VALUES (
        p_grant_id, v_grant.employee_id, v_grant.company_id, 'cliff'::vesting_event_type, v_sequence,
        v_current_date, v_cliff_shares, v_cumulative_shares,
        v_exercise_price, 
        CASE WHEN v_exercise_price IS NOT NULL THEN v_cliff_shares * v_exercise_price ELSE NULL END
      );
      
      v_sequence := v_sequence + 1;
    END IF;

    -- Create regular vesting events
    FOR i IN 1..v_total_periods LOOP
      v_current_date := v_start_date + ((v_cliff_months + i * v_frequency_months) || ' months')::interval;
      
      -- Calculate shares for this period
      IF i = v_total_periods THEN
        -- Last period: assign all remaining shares to ensure total equals grant total
        v_shares_this_period := v_grant.total_shares - v_allocated_shares;
      ELSE
        v_shares_this_period := v_shares_per_period;
      END IF;
      
      -- Only insert if shares > 0
      IF v_shares_this_period > 0 THEN
        v_allocated_shares := v_allocated_shares + v_shares_this_period;
        v_cumulative_shares := v_allocated_shares;
        
        INSERT INTO vesting_events (
          grant_id, employee_id, company_id, event_type, sequence_number,
          vesting_date, shares_to_vest, cumulative_shares_vested,
          exercise_price, total_exercise_cost
        ) VALUES (
          p_grant_id, v_grant.employee_id, v_grant.company_id, 'time_based'::vesting_event_type, v_sequence,
          v_current_date, v_shares_this_period, v_cumulative_shares,
          v_exercise_price,
          CASE WHEN v_exercise_price IS NOT NULL THEN v_shares_this_period * v_exercise_price ELSE NULL END
        );
        
        v_sequence := v_sequence + 1;
      END IF;
      
      -- Stop if we've allocated all shares (but don't exit too early)
      EXIT WHEN v_allocated_shares >= v_grant.total_shares;
    END LOOP;

    RAISE NOTICE 'Generated % vesting events from frequency for grant % (total shares: %, allocated: %, even_distribution: %)', 
      v_sequence - 1, p_grant_id, v_grant.total_shares, v_allocated_shares, v_use_even_distribution;
  END IF;
END;
$$;

