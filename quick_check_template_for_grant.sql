-- Quick check: Find the template and its milestones for grant GR-20251102-000014

SELECT 
  'GRANT INFO' as section,
  g.grant_number,
  g.vesting_start_date::text,
  g.total_shares::text
FROM grants g
WHERE g.grant_number = 'GR-20251102-000014'

UNION ALL

SELECT 
  'PLAN INFO' as section,
  ip.plan_name_en,
  ip.vesting_schedule_template_id::text,
  ip.vesting_config::text
FROM grants g
JOIN incentive_plans ip ON ip.id = g.plan_id
WHERE g.grant_number = 'GR-20251102-000014'

UNION ALL

SELECT 
  'TEMPLATE INFO' as section,
  vs.name,
  vs.total_duration_months::text || ' months',
  vs.schedule_type
FROM grants g
JOIN incentive_plans ip ON ip.id = g.plan_id
JOIN vesting_schedules vs ON vs.id = ip.vesting_schedule_template_id
WHERE g.grant_number = 'GR-20251102-000014'

UNION ALL

SELECT 
  'MILESTONE: ' || vm.sequence_order::text as section,
  vm.milestone_type || ' - ' || vm.vesting_percentage::text || '%' as details,
  vm.months_from_start::text || ' months' as months_from_start,
  (CASE WHEN vm.months_from_start IS NULL THEN 'NULL!' ELSE 'OK' END) as status
FROM grants g
JOIN incentive_plans ip ON ip.id = g.plan_id
JOIN vesting_schedules vs ON vs.id = ip.vesting_schedule_template_id
JOIN vesting_milestones vm ON vm.vesting_schedule_id = vs.id
WHERE g.grant_number = 'GR-20251102-000014'
ORDER BY vm.sequence_order

UNION ALL

SELECT 
  'VESTING EVENT: ' || ve.sequence_number::text as section,
  ve.event_type || ' - ' || ve.shares_to_vest::text || ' shares' as details,
  ve.vesting_date::text as vesting_date,
  ve.status
FROM grants g
JOIN vesting_events ve ON ve.grant_id = g.id
WHERE g.grant_number = 'GR-20251102-000014'
ORDER BY ve.sequence_number;

