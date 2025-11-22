/*
  # Fix Vesting Trigger for Template-Based Plans
  
  This migration fixes the issue where vesting events were being generated twice:
  1. By the database trigger (generic calculation)
  2. By the JavaScript function (using milestones from template)
  
  The duplicate generation caused rounding issues where fractional shares were lost.
  
  Solution:
  - Update the trigger to skip generation for grants under plans with templates
  - Let JavaScript generate vesting events from milestone percentages
  - This ensures the last milestone gets any remainder shares
*/

-- Update trigger function to check for template-based plans
CREATE OR REPLACE FUNCTION trigger_generate_vesting_events()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_plan_template_id uuid;
BEGIN
  -- Only generate events for active grants
  IF NEW.status = 'active' THEN
    -- Check if this grant's plan has a vesting schedule template
    -- If it does, skip database generation (JavaScript function will handle it)
    SELECT vesting_schedule_template_id INTO v_plan_template_id
    FROM incentive_plans
    WHERE id = NEW.plan_id;
    
    -- Only generate events if plan does NOT have a template (legacy behavior)
    IF v_plan_template_id IS NULL THEN
      PERFORM generate_vesting_events_for_grant(NEW.id);
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION trigger_generate_vesting_events() IS 
'Auto-generates vesting events for grants. Skips generation for template-based plans to avoid duplicates.';

