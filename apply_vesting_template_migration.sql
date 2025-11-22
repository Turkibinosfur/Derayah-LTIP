-- Manual migration to add vesting_schedule_template_id column to incentive_plans table
-- Run this in your Supabase SQL editor if the migration wasn't applied automatically

-- Add vesting_schedule_template_id column to incentive_plans table
ALTER TABLE incentive_plans 
ADD COLUMN IF NOT EXISTS vesting_schedule_template_id uuid REFERENCES vesting_schedules(id);

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_incentive_plans_vesting_template 
ON incentive_plans(vesting_schedule_template_id);

-- Add comment for documentation
COMMENT ON COLUMN incentive_plans.vesting_schedule_template_id IS 
'Links to vesting_schedules table where is_template = true. When set, the plan uses this template for all grants instead of manual vesting_config.';

-- Check if the column was added successfully
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'incentive_plans' 
AND column_name = 'vesting_schedule_template_id';
