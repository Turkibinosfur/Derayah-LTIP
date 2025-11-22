-- Quick check for the most recent grant and its template
-- Find the latest grant and check if its template has proper milestones

WITH latest_grant AS (
  SELECT 
    g.id as grant_id,
    g.grant_number,
    g.vesting_start_date,
    g.total_shares,
    g.plan_id
  FROM grants g
  ORDER BY g.created_at DESC
  LIMIT 1
),
grant_plan AS (
  SELECT 
    lg.*,
    ip.vesting_schedule_template_id as template_id,
    ip.plan_name_en
  FROM latest_grant lg
  JOIN incentive_plans ip ON ip.id = lg.plan_id
)
SELECT 
  '=== LATEST GRANT ===' as info_line
FROM grant_plan
UNION ALL
SELECT 
  'Grant: ' || grant_number || ' | Start: ' || vesting_start_date::text || ' | Shares: ' || total_shares::text
FROM grant_plan
UNION ALL
SELECT 
  'Plan: ' || plan_name_en || ' | Template: ' || template_id::text
FROM grant_plan
UNION ALL
SELECT 
  '=== TEMPLATE INFO ===' as info_line
FROM grant_plan
UNION ALL
SELECT 
  'Name: ' || vs.name || ' | Type: ' || vs.schedule_type || ' | Duration: ' || vs.total_duration_months::text
FROM grant_plan gp
JOIN vesting_schedules vs ON vs.id = gp.template_id
UNION ALL
SELECT 
  'Frequency: ' || vs.vesting_frequency || ' | Cliff: ' || vs.cliff_months::text || ' | Template: ' || vs.is_template::text
FROM grant_plan gp
JOIN vesting_schedules vs ON vs.id = gp.template_id
UNION ALL
SELECT 
  '=== MILESTONES ===' as info_line
FROM grant_plan
UNION ALL
SELECT 
  COALESCE(
    '✓ Found ' || COUNT(*)::text || ' milestones',
    '✗ NO MILESTONES FOUND!'
  )
FROM grant_plan gp
JOIN vesting_milestones vm ON vm.vesting_schedule_id = gp.template_id
UNION ALL
SELECT 
  'Milestone ' || vm.sequence_order::text || ': ' || 
  vm.vesting_percentage::text || '% at ' || 
  vm.months_from_start::text || ' months | Type: ' || vm.milestone_type
FROM grant_plan gp
JOIN vesting_milestones vm ON vm.vesting_schedule_id = gp.template_id
UNION ALL
SELECT 
  '=== CURRENT VESTING EVENTS ===' as info_line
FROM grant_plan
UNION ALL
SELECT 
  COALESCE(
    'Found ' || COUNT(*)::text || ' events',
    'NO EVENTS FOUND'
  )
FROM grant_plan gp
JOIN vesting_events ve ON ve.grant_id = gp.grant_id
UNION ALL
SELECT 
  'Event ' || ve.sequence_number::text || ': ' ||
  ve.vesting_date::text || ' | ' || ve.shares_to_vest::text || ' shares | ' || ve.event_type
FROM grant_plan gp
JOIN vesting_events ve ON ve.grant_id = gp.grant_id
ORDER BY info_line;

