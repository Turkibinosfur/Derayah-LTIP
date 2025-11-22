/*
  # Finalize LTIP Pools Migration

  Consolidates the legacy ESOP pool implementation under the `ltip_pools`
  table so all application code relies on a single structure.

  Changes:
  - Renames `esop_pools` to `ltip_pools` (if the rename has not already been applied)
  - Renames supporting indexes, constraints, and foreign keys
  - Renames `incentive_plans.esop_pool_id` to `ltip_pool_id`
  - Updates helper functions, triggers, and policies to reference `ltip_pools`
  - Refreshes company portfolio sync logic to read from LTIP pools
*/

-- 1. Rename table when the legacy name still exists
DO $$
BEGIN
  IF to_regclass('public.ltip_pools') IS NULL AND to_regclass('public.esop_pools') IS NOT NULL THEN
    ALTER TABLE public.esop_pools RENAME TO ltip_pools;
  END IF;
END $$;

-- 2. Rename primary indexes created for the legacy table
DO $$
BEGIN
  IF to_regclass('public.idx_esop_pools_company_id') IS NOT NULL
     AND to_regclass('public.idx_ltip_pools_company_id') IS NULL THEN
    ALTER INDEX public.idx_esop_pools_company_id RENAME TO idx_ltip_pools_company_id;
  END IF;

  IF to_regclass('public.idx_esop_pools_status') IS NOT NULL
     AND to_regclass('public.idx_ltip_pools_status') IS NULL THEN
    ALTER INDEX public.idx_esop_pools_status RENAME TO idx_ltip_pools_status;
  END IF;

  IF to_regclass('public.idx_esop_pools_pool_type') IS NOT NULL
     AND to_regclass('public.idx_ltip_pools_pool_type') IS NULL THEN
    ALTER INDEX public.idx_esop_pools_pool_type RENAME TO idx_ltip_pools_pool_type;
  END IF;
END $$;

-- 3. Rename the foreign key column on incentive plans
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'incentive_plans'
      AND column_name = 'esop_pool_id'
  ) AND NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'incentive_plans'
      AND column_name = 'ltip_pool_id'
  ) THEN
    ALTER TABLE public.incentive_plans
      RENAME COLUMN esop_pool_id TO ltip_pool_id;
  END IF;
END $$;

-- Ensure legacy trigger is removed before recreating the function
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trigger_update_esop_pool_usage'
      AND tgrelid = 'public.incentive_plans'::regclass
  ) THEN
    DROP TRIGGER trigger_update_esop_pool_usage ON public.incentive_plans;
  END IF;
END $$;

-- 4. Rename the allocation constraint to match the new table name
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'esop_pools_allocation_not_less_than_used'
  ) THEN
    ALTER TABLE public.ltip_pools
      RENAME CONSTRAINT esop_pools_allocation_not_less_than_used
      TO ltip_pools_allocation_not_less_than_used;
  END IF;
END $$;

-- 5. Recreate the pool usage function so it references LTIP pools
DROP FUNCTION IF EXISTS update_esop_pool_usage();
CREATE OR REPLACE FUNCTION update_esop_pool_usage()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Handle DELETE operations
  IF TG_OP = 'DELETE' THEN
    IF OLD.ltip_pool_id IS NOT NULL THEN
      UPDATE ltip_pools
      SET
        shares_used = COALESCE((
          SELECT SUM(total_shares_allocated)
          FROM incentive_plans
          WHERE ltip_pool_id = OLD.ltip_pool_id
            AND id != OLD.id
        ), 0),
        updated_at = now()
      WHERE id = OLD.ltip_pool_id;
    END IF;
    RETURN OLD;
  END IF;

  -- Handle INSERT and UPDATE operations
  IF NEW.ltip_pool_id IS NOT NULL THEN
    UPDATE ltip_pools
    SET
      shares_used = COALESCE((
        SELECT SUM(total_shares_allocated)
        FROM incentive_plans
        WHERE ltip_pool_id = NEW.ltip_pool_id
      ), 0),
      updated_at = now()
    WHERE id = NEW.ltip_pool_id;
  END IF;

  IF TG_OP = 'UPDATE'
     AND OLD.ltip_pool_id IS NOT NULL
     AND OLD.ltip_pool_id <> COALESCE(NEW.ltip_pool_id, '00000000-0000-0000-0000-000000000000'::uuid) THEN
    UPDATE ltip_pools
    SET
      shares_used = COALESCE((
        SELECT SUM(total_shares_allocated)
        FROM incentive_plans
        WHERE ltip_pool_id = OLD.ltip_pool_id
      ), 0),
      updated_at = now()
    WHERE id = OLD.ltip_pool_id;
  END IF;

  RETURN NEW;
END;
$$;

-- 6. Recreate the updated_at trigger helper for LTIP pools
DROP FUNCTION IF EXISTS update_esop_pools_updated_at();
CREATE OR REPLACE FUNCTION update_esop_pools_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- 7. Reset triggers on the LTIP pools table
DROP TRIGGER IF EXISTS trigger_update_esop_pools_updated_at ON ltip_pools;
CREATE TRIGGER trigger_update_esop_pools_updated_at
BEFORE UPDATE ON ltip_pools
FOR EACH ROW
EXECUTE FUNCTION update_esop_pools_updated_at();

-- 8. Refresh RLS policies with LTIP-specific names
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'ltip_pools'
      AND policyname = 'Users can view ESOP pools for their company'
  ) THEN
    DROP POLICY "Users can view ESOP pools for their company" ON ltip_pools;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'ltip_pools'
      AND policyname = 'Users can insert ESOP pools for their company'
  ) THEN
    DROP POLICY "Users can insert ESOP pools for their company" ON ltip_pools;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'ltip_pools'
      AND policyname = 'Users can update ESOP pools for their company'
  ) THEN
    DROP POLICY "Users can update ESOP pools for their company" ON ltip_pools;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'ltip_pools'
      AND policyname = 'Users can delete ESOP pools for their company'
  ) THEN
    DROP POLICY "Users can delete ESOP pools for their company" ON ltip_pools;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'ltip_pools'
      AND policyname = 'Users can view LTIP pools for their company'
  ) THEN
    DROP POLICY "Users can view LTIP pools for their company" ON ltip_pools;
  END IF;

  EXECUTE $policy$
    CREATE POLICY "Users can view LTIP pools for their company" ON ltip_pools
      FOR SELECT
      USING (
        company_id IN (
          SELECT company_id
          FROM company_users
          WHERE user_id = auth.uid()
        )
      );
  $policy$;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'ltip_pools'
      AND policyname = 'Users can insert LTIP pools for their company'
  ) THEN
    DROP POLICY "Users can insert LTIP pools for their company" ON ltip_pools;
  END IF;

  EXECUTE $policy$
    CREATE POLICY "Users can insert LTIP pools for their company" ON ltip_pools
      FOR INSERT
      WITH CHECK (
        company_id IN (
          SELECT company_id
          FROM company_users
          WHERE user_id = auth.uid()
        )
      );
  $policy$;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'ltip_pools'
      AND policyname = 'Users can update LTIP pools for their company'
  ) THEN
    DROP POLICY "Users can update LTIP pools for their company" ON ltip_pools;
  END IF;

  EXECUTE $policy$
    CREATE POLICY "Users can update LTIP pools for their company" ON ltip_pools
      FOR UPDATE
      USING (
        company_id IN (
          SELECT company_id
          FROM company_users
          WHERE user_id = auth.uid()
        )
      );
  $policy$;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'ltip_pools'
      AND policyname = 'Users can delete LTIP pools for their company'
  ) THEN
    DROP POLICY "Users can delete LTIP pools for their company" ON ltip_pools;
  END IF;

  EXECUTE $policy$
    CREATE POLICY "Users can delete LTIP pools for their company" ON ltip_pools
      FOR DELETE
      USING (
        company_id IN (
          SELECT company_id
          FROM company_users
          WHERE user_id = auth.uid()
        )
      );
  $policy$;
END $$;

-- 9. Update the company reserved portfolio helpers to read LTIP pools
CREATE OR REPLACE FUNCTION create_company_reserved_portfolio()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_portfolio_id uuid;
  v_total_shares numeric;
BEGIN
  SELECT COALESCE(SUM(total_shares_allocated), 0)
  INTO v_total_shares
  FROM ltip_pools
  WHERE company_id = NEW.id AND status = 'active';

  IF v_total_shares = 0 THEN
    SELECT COALESCE(SUM(total_shares_allocated), 0)
    INTO v_total_shares
    FROM incentive_plans
    WHERE company_id = NEW.id AND status = 'active';
  END IF;

  IF v_total_shares = 0 THEN
    v_total_shares := COALESCE(NEW.total_reserved_shares, 0);
  END IF;

  INSERT INTO portfolios (
    id,
    portfolio_type,
    company_id,
    employee_id,
    total_shares,
    available_shares,
    locked_shares,
    portfolio_number,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    'company_reserved',
    NEW.id,
    NULL,
    v_total_shares,
    v_total_shares,
    0,
    'PORT-COMPANY-RESERVED-' || NEW.id::text,
    now(),
    now()
  ) RETURNING id INTO v_portfolio_id;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION sync_company_portfolio_with_pools()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_allocated numeric;
  v_total_granted numeric;
  v_portfolio_id uuid;
  v_company_id uuid;
BEGIN
  IF TG_TABLE_NAME = 'ltip_pools' THEN
    v_company_id := COALESCE(NEW.company_id, OLD.company_id);
  ELSIF TG_TABLE_NAME = 'incentive_plans' THEN
    v_company_id := COALESCE(NEW.company_id, OLD.company_id);
  ELSIF TG_TABLE_NAME = 'grants' THEN
    v_company_id := COALESCE(NEW.company_id, OLD.company_id);
  END IF;

  IF v_company_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  SELECT COALESCE(SUM(total_shares_allocated), 0)
  INTO v_total_allocated
  FROM ltip_pools
  WHERE company_id = v_company_id AND status = 'active';

  IF v_total_allocated = 0 THEN
    SELECT COALESCE(SUM(total_shares_allocated), 0)
    INTO v_total_allocated
    FROM incentive_plans
    WHERE company_id = v_company_id AND status = 'active';
  END IF;

  SELECT COALESCE(SUM(total_shares), 0)
  INTO v_total_granted
  FROM grants
  WHERE company_id = v_company_id
    AND status IN ('active', 'pending_signature');

  SELECT id INTO v_portfolio_id
  FROM portfolios
  WHERE company_id = v_company_id
    AND portfolio_type = 'company_reserved'
    AND employee_id IS NULL;

  IF v_portfolio_id IS NOT NULL THEN
    UPDATE portfolios
    SET
      total_shares = v_total_allocated,
      locked_shares = v_total_granted,
      available_shares = GREATEST(0, v_total_allocated - v_total_granted),
      updated_at = now()
    WHERE id = v_portfolio_id;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

-- 10. Recreate the portfolio sync triggers with LTIP naming
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trigger_sync_portfolio_on_ltip_pool_change'
      AND tgrelid = 'public.ltip_pools'::regclass
  ) THEN
    DROP TRIGGER trigger_sync_portfolio_on_ltip_pool_change ON public.ltip_pools;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trigger_sync_portfolio_on_esop_pool_change'
      AND tgrelid = 'public.ltip_pools'::regclass
  ) THEN
    DROP TRIGGER trigger_sync_portfolio_on_esop_pool_change ON public.ltip_pools;
  END IF;
END $$;

CREATE TRIGGER trigger_sync_portfolio_on_ltip_pool_change
  AFTER INSERT OR UPDATE OR DELETE ON ltip_pools
  FOR EACH ROW
  EXECUTE FUNCTION sync_company_portfolio_with_pools();

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trigger_sync_portfolio_on_plan_change'
      AND tgrelid = 'public.incentive_plans'::regclass
  ) THEN
    DROP TRIGGER trigger_sync_portfolio_on_plan_change ON public.incentive_plans;
  END IF;
END $$;
CREATE TRIGGER trigger_sync_portfolio_on_plan_change
  AFTER INSERT OR UPDATE OR DELETE ON incentive_plans
  FOR EACH ROW
  EXECUTE FUNCTION sync_company_portfolio_with_pools();

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trigger_sync_portfolio_on_grant_change'
      AND tgrelid = 'public.grants'::regclass
  ) THEN
    DROP TRIGGER trigger_sync_portfolio_on_grant_change ON public.grants;
  END IF;
END $$;
CREATE TRIGGER trigger_sync_portfolio_on_grant_change
  AFTER INSERT OR UPDATE OR DELETE ON grants
  FOR EACH ROW
  EXECUTE FUNCTION sync_company_portfolio_with_pools();

-- 11. Replace constraint helper functions and triggers for LTIP pools
DROP FUNCTION IF EXISTS prevent_esop_pool_allocation_underflow();
DROP FUNCTION IF EXISTS prevent_esop_pool_deletion_with_usage();

CREATE OR REPLACE FUNCTION prevent_ltip_pool_allocation_underflow()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.total_shares_allocated < NEW.shares_used THEN
    RAISE EXCEPTION 'Cannot set total_shares_allocated (%) below shares_used (%) for LTIP pool %',
      NEW.total_shares_allocated, NEW.shares_used, NEW.id
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION prevent_ltip_pool_deletion_with_usage()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_plan_exists boolean;
  v_grant_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM incentive_plans p WHERE p.ltip_pool_id = OLD.id
  ) INTO v_plan_exists;

  IF v_plan_exists THEN
    RAISE EXCEPTION 'Cannot delete LTIP pool % because it is referenced by one or more incentive plans', OLD.id
      USING ERRCODE = 'foreign_key_violation';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM grants g
    JOIN incentive_plans p ON p.id = g.plan_id
    WHERE p.ltip_pool_id = OLD.id
  ) INTO v_grant_exists;

  IF v_grant_exists THEN
    RAISE EXCEPTION 'Cannot delete LTIP pool % because there are grants associated to plans using this pool', OLD.id
      USING ERRCODE = 'foreign_key_violation';
  END IF;

  RETURN OLD;
END;
$$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trg_ltip_pool_prevent_underflow'
      AND tgrelid = 'public.ltip_pools'::regclass
  ) THEN
    DROP TRIGGER trg_ltip_pool_prevent_underflow ON public.ltip_pools;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trg_esop_pool_prevent_underflow'
      AND tgrelid = 'public.ltip_pools'::regclass
  ) THEN
    DROP TRIGGER trg_esop_pool_prevent_underflow ON public.ltip_pools;
  END IF;
END $$;

CREATE TRIGGER trg_ltip_pool_prevent_underflow
BEFORE UPDATE ON ltip_pools
FOR EACH ROW
EXECUTE FUNCTION prevent_ltip_pool_allocation_underflow();

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trg_ltip_pool_prevent_delete_when_used'
      AND tgrelid = 'public.ltip_pools'::regclass
  ) THEN
    DROP TRIGGER trg_ltip_pool_prevent_delete_when_used ON public.ltip_pools;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trg_esop_pool_prevent_delete_when_used'
      AND tgrelid = 'public.ltip_pools'::regclass
  ) THEN
    DROP TRIGGER trg_esop_pool_prevent_delete_when_used ON public.ltip_pools;
  END IF;
END $$;

CREATE TRIGGER trg_ltip_pool_prevent_delete_when_used
BEFORE DELETE ON ltip_pools
FOR EACH ROW
EXECUTE FUNCTION prevent_ltip_pool_deletion_with_usage();

-- 12. Recalculate shares_used to ensure correctness after the rename
UPDATE ltip_pools lp
SET shares_used = GREATEST(0, COALESCE((
  SELECT SUM(ip.total_shares_allocated)
  FROM incentive_plans ip
  WHERE ip.ltip_pool_id = lp.id
), 0));

-- Drop any leftover legacy column
ALTER TABLE public.incentive_plans
  DROP COLUMN IF EXISTS esop_pool_id;

COMMENT ON TABLE ltip_pools IS 'LTIP (Long-Term Incentive Plan) pools for managing employee stock allocations';


