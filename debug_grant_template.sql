/*
  Diagnostic Query for Grant GR-20251101-000011
  
  Check what's linked to this grant and if there's a template
*/

SELECT 
  g.grant_number,
  g.total_shares,
  g.vesting_start_date,
  ip.plan_name_en,
  ip.vesting_schedule_template_id,
  vs.name as template_name,
  vs.schedule_type as template_type,
  vs.total_duration_months,
  vs.cliff_months,
  vs.vesting_frequency,
  vs.is_template,
  (SELECT COUNT(*) FROM vesting_milestones WHERE vesting_schedule_id = vs.id) as milestone_count
FROM grants g
JOIN incentive_plans ip ON ip.id = g.plan_id
LEFT JOIN vesting_schedules vs ON vs.id = ip.vesting_schedule_template_id
WHERE g.grant_number = 'GR-20251101-000011';

-- Show milestones if template exists
DO $$
DECLARE
  v_template_id uuid;
BEGIN
  SELECT ip.vesting_schedule_template_id INTO v_template_id
  FROM grants g
  JOIN incentive_plans ip ON ip.id = g.plan_id
  WHERE g.grant_number = 'GR-20251101-000011';
  
  IF v_template_id IS NOT NULL THEN
    RAISE NOTICE 'Found template ID: %', v_template_id;
    RAISE NOTICE 'Milestones for this template:';
    
    FOR rec IN 
      SELECT * FROM vesting_milestones 
      WHERE vesting_schedule_id = v_template_id 
      ORDER BY sequence_order
    LOOP
      RAISE NOTICE '  Sequence: %, Type: %, Percentage: %%, Months: %', 
        rec.sequence_order, rec.milestone_type, rec.vesting_percentage, rec.months_from_start;
    END LOOP;
  ELSE
    RAISE NOTICE 'No template linked to grant GR-20251101-000011';
  END IF;
END $$;

-- Show current vesting events
SELECT 
  sequence_number,
  event_type,
  vesting_date,
  shares_to_vest,
  status
FROM vesting_events
WHERE grant_id = (SELECT id FROM grants WHERE grant_number = 'GR-20251101-000011')
ORDER BY sequence_number;

