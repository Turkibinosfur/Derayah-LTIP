-- Fix ALL grants for the "New program 2" plan (LTIP-36)
-- This will fix all grants that have incorrect vesting dates

DO $$
DECLARE
  v_grant RECORD;
  v_fixed_count int := 0;
BEGIN
  RAISE NOTICE 'Starting batch fix for all LTIP-36 grants...';
  
  -- Loop through all grants for this plan
  FOR v_grant IN 
    SELECT 
      g.id,
      g.grant_number,
      g.vesting_start_date,
      g.total_shares,
      ip.vesting_schedule_template_id as template_id
    FROM grants g
    JOIN incentive_plans ip ON ip.id = g.plan_id
    WHERE ip.plan_code = 'LTIP-36'
    ORDER BY g.created_at DESC
  LOOP
    BEGIN
      RAISE NOTICE '';
      RAISE NOTICE 'Processing grant: %', v_grant.grant_number;
      
      -- Delete existing vesting events
      DELETE FROM vesting_events WHERE grant_id = v_grant.id;
      RAISE NOTICE '  Deleted existing events';
      
      -- Regenerate using the vesting utils logic
      -- First check if template has milestones
      DECLARE
        v_milestone_count int;
        v_template_total_months int;
        v_template_cliff_months int;
        v_template_frequency text;
        v_template_type text;
        v_frequency_months int;
        v_milestone_type text;
        v_remaining_months int;
        v_period_count int;
        v_percentage_per_period numeric;
        v_order int;
        v_milestone_row RECORD;
        v_vesting_date date;
        v_shares_to_vest numeric;
        v_shares_allocated numeric := 0;
        v_cumulative_shares numeric := 0;
        v_event_type text;
      BEGIN
        -- Get template details
        SELECT 
          total_duration_months,
          cliff_months,
          vesting_frequency,
          schedule_type
        INTO 
          v_template_total_months,
          v_template_cliff_months,
          v_template_frequency,
          v_template_type
        FROM vesting_schedules
        WHERE id = v_grant.template_id AND is_template = true;
        
        -- Check milestone count
        SELECT COUNT(*) INTO v_milestone_count
        FROM vesting_milestones
        WHERE vesting_schedule_id = v_grant.template_id;
        
        -- If no milestones, generate them
        IF v_milestone_count = 0 THEN
          RAISE NOTICE '  No milestones found, generating...';
          
          v_frequency_months := CASE v_template_frequency
            WHEN 'monthly' THEN 1
            WHEN 'quarterly' THEN 3
            WHEN 'annually' THEN 12
            ELSE 12
          END;
          
          v_milestone_type := CASE v_template_type
            WHEN 'time_based' THEN 'time'
            WHEN 'performance_based' THEN 'performance'
            WHEN 'hybrid' THEN 'hybrid'
            ELSE 'time'
          END;
          
          v_order := 0;
          
          -- Generate cliff milestone
          IF v_template_cliff_months > 0 THEN
            INSERT INTO vesting_milestones (
              vesting_schedule_id,
              milestone_type,
              sequence_order,
              vesting_percentage,
              months_from_start
            ) VALUES (
              v_grant.template_id,
              v_milestone_type,
              v_order,
              25,
              v_template_cliff_months
            );
            v_order := v_order + 1;
            RAISE NOTICE '    Generated cliff milestone at % months', v_template_cliff_months;
          END IF;
          
          -- Generate periodic milestones
          v_remaining_months := v_template_total_months - v_template_cliff_months;
          v_period_count := FLOOR(v_remaining_months / v_frequency_months);
          v_percentage_per_period := 75.0 / v_period_count;
          
          FOR i IN 1..v_period_count LOOP
            INSERT INTO vesting_milestones (
              vesting_schedule_id,
              milestone_type,
              sequence_order,
              vesting_percentage,
              months_from_start
            ) VALUES (
              v_grant.template_id,
              v_milestone_type,
              v_order,
              v_percentage_per_period,
              v_template_cliff_months + (i * v_frequency_months)
            );
            v_order := v_order + 1;
          END LOOP;
          
          RAISE NOTICE '    Generated % periodic milestones', v_period_count;
        END IF;
        
        -- Now generate vesting events from milestones
        FOR v_milestone_row IN 
          SELECT 
            sequence_order,
            milestone_type,
            vesting_percentage,
            months_from_start
          FROM vesting_milestones
          WHERE vesting_schedule_id = v_grant.template_id
          ORDER BY sequence_order
        LOOP
          v_vesting_date := v_grant.vesting_start_date + (v_milestone_row.months_from_start || ' months')::interval;
          
          v_shares_to_vest := FLOOR((v_grant.total_shares * v_milestone_row.vesting_percentage) / 100);
          v_shares_allocated := v_shares_allocated + v_shares_to_vest;
          
          v_event_type := CASE v_milestone_row.milestone_type
            WHEN 'time' THEN 'time_based'
            WHEN 'performance' THEN 'performance'
            WHEN 'hybrid' THEN 'hybrid'
            ELSE 'time_based'
          END;
          
          v_cumulative_shares := v_cumulative_shares + v_shares_to_vest;
          
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
            v_grant.id,
            employee_id,
            company_id,
            v_event_type,
            v_milestone_row.sequence_order,
            v_vesting_date,
            v_shares_to_vest,
            v_cumulative_shares,
            true,
            'pending',
            NOW()
          FROM grants
          WHERE id = v_grant.id;
        END LOOP;
        
        -- Adjust last event for remainder
        UPDATE vesting_events
        SET shares_to_vest = (
          SELECT v_grant.total_shares - SUM(shares_to_vest) 
          FROM vesting_events 
          WHERE grant_id = v_grant.id AND id != vesting_events.id
        )
        WHERE grant_id = v_grant.id
        AND sequence_number = (
          SELECT MAX(sequence_number) 
          FROM vesting_events 
          WHERE grant_id = v_grant.id
        );
        
        v_fixed_count := v_fixed_count + 1;
        RAISE NOTICE '  ✓ Successfully regenerated events for %', v_grant.grant_number;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '  ✗ Error processing %: %', v_grant.grant_number, SQLERRM;
      END;
    END;
  END LOOP;
  
  RAISE NOTICE '';
  RAISE NOTICE '=== COMPLETE ===';
  RAISE NOTICE 'Fixed % grants', v_fixed_count;
END $$;

