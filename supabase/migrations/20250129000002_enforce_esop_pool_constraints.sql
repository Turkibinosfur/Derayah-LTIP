/*
  Enforce ESOP Pool Constraints

  - Disallow deleting an ESOP pool if it is referenced by any incentive plans
    or indirectly used by grants through those plans
  - Disallow reducing total_shares_allocated below shares_used
  - Keep shares_used <= total_shares_allocated invariant with a CHECK
*/

-- Ensure invariant at the table level
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'esop_pools_allocation_not_less_than_used'
  ) THEN
    ALTER TABLE esop_pools
      ADD CONSTRAINT esop_pools_allocation_not_less_than_used
      CHECK (total_shares_allocated >= shares_used);
  END IF;
END $$;

-- Prevent reducing allocation below used with clearer error message
CREATE OR REPLACE FUNCTION prevent_esop_pool_allocation_underflow()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.total_shares_allocated < NEW.shares_used THEN
    RAISE EXCEPTION 'Cannot set total_shares_allocated (%) below shares_used (%) for ESOP pool %',
      NEW.total_shares_allocated, NEW.shares_used, NEW.id
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_esop_pool_prevent_underflow ON esop_pools;
CREATE TRIGGER trg_esop_pool_prevent_underflow
BEFORE UPDATE ON esop_pools
FOR EACH ROW
EXECUTE FUNCTION prevent_esop_pool_allocation_underflow();

-- Prevent deleting pools that are in use by plans or grants
CREATE OR REPLACE FUNCTION prevent_esop_pool_deletion_with_usage()
RETURNS TRIGGER AS $$
DECLARE
  v_plan_exists boolean;
  v_grant_exists boolean;
BEGIN
  -- If any incentive plans reference this pool, block deletion
  SELECT EXISTS (
    SELECT 1 FROM incentive_plans p WHERE p.esop_pool_id = OLD.id
  ) INTO v_plan_exists;

  IF v_plan_exists THEN
    RAISE EXCEPTION 'Cannot delete ESOP pool % because it is referenced by one or more incentive plans', OLD.id
      USING ERRCODE = 'foreign_key_violation';
  END IF;

  -- Double-safety: if any grants exist under plans of this pool, block deletion
  SELECT EXISTS (
    SELECT 1
    FROM grants g
    JOIN incentive_plans p ON p.id = g.plan_id
    WHERE p.esop_pool_id = OLD.id
  ) INTO v_grant_exists;

  IF v_grant_exists THEN
    RAISE EXCEPTION 'Cannot delete ESOP pool % because there are grants associated to plans using this pool', OLD.id
      USING ERRCODE = 'foreign_key_violation';
  END IF;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_esop_pool_prevent_delete_when_used ON esop_pools;
CREATE TRIGGER trg_esop_pool_prevent_delete_when_used
BEFORE DELETE ON esop_pools
FOR EACH ROW
EXECUTE FUNCTION prevent_esop_pool_deletion_with_usage();

-- Optional: keep shares_used recalculated and clamped by allocation on any plan change
-- (Assumes update_esop_pool_usage() exists from prior migration)
-- Re-run calculation to ensure constraint holds for existing data
UPDATE esop_pools ep
SET shares_used = GREATEST(0, COALESCE((
  SELECT SUM(ip.total_shares_allocated)
  FROM incentive_plans ip
  WHERE ip.esop_pool_id = ep.id
), 0))
WHERE TRUE;


