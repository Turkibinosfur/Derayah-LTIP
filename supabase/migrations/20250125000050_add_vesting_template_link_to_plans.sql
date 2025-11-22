/*
  # Add Vesting Schedule Template Link to Incentive Plans
  
  This migration adds the missing link between incentive plans and vesting schedule templates,
  enabling the template-based vesting flow.
  
  Changes:
  1. Add vesting_schedule_template_id column to incentive_plans table
  2. Add foreign key constraint to vesting_schedules table
  3. Add index for performance
  4. Update existing plans to link to default template (if available)
*/

-- Add vesting_schedule_template_id column to incentive_plans table
ALTER TABLE incentive_plans 
ADD COLUMN IF NOT EXISTS vesting_schedule_template_id uuid REFERENCES vesting_schedules(id);

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_incentive_plans_vesting_template 
ON incentive_plans(vesting_schedule_template_id);

-- Add comment for documentation
COMMENT ON COLUMN incentive_plans.vesting_schedule_template_id IS 
'Links to vesting_schedules table where is_template = true. When set, the plan uses this template for all grants instead of manual vesting_config.';

-- Update existing plans to link to default template if available
DO $$
DECLARE
  v_default_template_id uuid;
  v_updated_count integer;
BEGIN
  -- Find the first available template for each company
  FOR v_default_template_id IN 
    SELECT DISTINCT ON (vs.company_id) vs.id
    FROM vesting_schedules vs
    WHERE vs.is_template = true
    ORDER BY vs.company_id, vs.created_at ASC
  LOOP
    -- Update plans for this company that don't have a template linked
    UPDATE incentive_plans 
    SET vesting_schedule_template_id = v_default_template_id,
        updated_at = now()
    WHERE vesting_schedule_template_id IS NULL
      AND company_id = (
        SELECT company_id 
        FROM vesting_schedules 
        WHERE id = v_default_template_id
      );
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    IF v_updated_count > 0 THEN
      RAISE NOTICE 'Linked % plans to default template %', v_updated_count, v_default_template_id;
    END IF;
  END LOOP;
  
  RAISE NOTICE 'Completed linking existing plans to vesting schedule templates';
END $$;
