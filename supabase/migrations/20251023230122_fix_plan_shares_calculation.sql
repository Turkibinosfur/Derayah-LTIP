/*
  # Fix Plan Shares Calculation

  1. Changes
    - Create function to update plan shares when grants change
    - Create trigger to automatically recalculate shares_granted and shares_available
    - Update existing data to reflect actual granted shares

  2. Purpose
    - Ensures shares_granted always matches the sum of grants.total_shares
    - Ensures shares_available is always calculated correctly
    - Maintains data integrity automatically
*/

-- Function to update plan shares
CREATE OR REPLACE FUNCTION update_plan_shares()
RETURNS TRIGGER AS $$
BEGIN
  -- Update the incentive plan with actual granted shares
  UPDATE incentive_plans
  SET 
    shares_granted = COALESCE((
      SELECT SUM(total_shares)
      FROM grants
      WHERE plan_id = COALESCE(NEW.plan_id, OLD.plan_id)
    ), 0),
    shares_available = total_shares_allocated - COALESCE((
      SELECT SUM(total_shares)
      FROM grants
      WHERE plan_id = COALESCE(NEW.plan_id, OLD.plan_id)
    ), 0)
  WHERE id = COALESCE(NEW.plan_id, OLD.plan_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_update_plan_shares ON grants;

-- Create trigger for INSERT, UPDATE, and DELETE on grants
CREATE TRIGGER trigger_update_plan_shares
AFTER INSERT OR UPDATE OR DELETE ON grants
FOR EACH ROW
EXECUTE FUNCTION update_plan_shares();

-- Update all existing plans to have correct values
UPDATE incentive_plans
SET 
  shares_granted = COALESCE((
    SELECT SUM(total_shares)
    FROM grants
    WHERE plan_id = incentive_plans.id
  ), 0),
  shares_available = total_shares_allocated - COALESCE((
    SELECT SUM(total_shares)
    FROM grants
    WHERE plan_id = incentive_plans.id
  ), 0);
