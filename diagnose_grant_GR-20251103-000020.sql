-- Diagnose grant GR-20251103-000020
-- Check template, milestones, and vesting events

SELECT '=== GRANT INFO ===' as section;

SELECT 
  'Grant: ' || grant_number || ' | Start: ' || vesting_start_date::text || ' | Shares: ' || total_shares::text as info
FROM grants
WHERE grant_number = 'GR-20251103-000020';

SELECT '=== PLAN INFO ===' as section;

SELECT 
  'Plan: ' || ip.plan_name_en || ' | Template ID: ' || COALESCE(ip.vesting_schedule_template_id::text, 'NULL') as info
FROM grants g
JOIN incentive_plans ip ON ip.id = g.plan_id
WHERE g.grant_number = 'GR-20251103-000020';

SELECT '=== TEMPLATE INFO ===' as section;

SELECT 
  'Template: ' || vs.name || ' | Type: ' || vs.schedule_type || ' | Duration: ' || vs.total_duration_months::text as info
FROM grants g
JOIN incentive_plans ip ON ip.id = g.plan_id
JOIN vesting_schedules vs ON vs.id = ip.vesting_schedule_template_id
WHERE g.grant_number = 'GR-20251103-000020';

SELECT '===== MILESTONES =====' as section;

SELECT 
  COALESCE(COUNT(*)::text, '0') as info
FROM grants g
JOIN incentive_plans ip ON ip.id = g.plan_id
JOIN vesting_schedules vs ON vs.id = ip.vesting_schedule_template_id
LEFT JOIN vesting_milestones vm ON vm.vesting_schedule_id = vs.id
WHERE g.grant_number = 'GR-20251103-000020';

SELECT 
  'Milestone ' || vm.sequence_order::text || ': ' || 
  vm.vesting_percentage::text || '% at ' || 
  vm.months_from_start::text || ' months | Type: ' || vm.milestone_type as info
FROM grants g
JOIN incentive_plans ip ON ip.id = g.plan_id
JOIN vesting_schedules vs ON vs.id = ip.vesting_schedule_template_id
JOIN vesting_milestones vm ON vm.vesting_schedule_id = vs.id
WHERE g.grant_number = 'GR-20251103-000020'
ORDER BY vm.sequence_order;

SELECT '===== VESTING EVENTS =====' as section;

SELECT 
  COUNT(*)::text as info
FROM vesting_events ve
JOIN grants g ON g.id = ve.grant_id
WHERE g.grant_number = 'GR-20251103-000020';

SELECT 
  'Event ' || ve.sequence_number::text || ': ' ||
  ve.vesting_date::text || ' | ' || ve.shares_to_vest::text || ' shares | ' || ve.event_type as info
FROM vesting_events ve
JOIN grants g ON g.id = ve.grant_id
WHERE g.grant_number = 'GR-20251103-000020'
ORDER BY ve.sequence_number;

