-- Test script to check if the vesting_schedule_template_id column exists
-- and what the current schema looks like

-- Check if the column exists
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'incentive_plans' 
AND column_name = 'vesting_schedule_template_id';

-- Check current incentive_plans table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'incentive_plans' 
ORDER BY ordinal_position;

-- Check if there are any plans in the table
SELECT id, plan_name_en, status, created_at 
FROM incentive_plans 
ORDER BY created_at DESC 
LIMIT 5;

-- Check if vesting_schedules table exists and has templates
SELECT id, name, is_template, company_id 
FROM vesting_schedules 
WHERE is_template = true 
LIMIT 5;
