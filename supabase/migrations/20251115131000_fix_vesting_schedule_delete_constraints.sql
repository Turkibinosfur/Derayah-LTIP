/*
  # Fix Foreign Key Constraints for Vesting Schedule Deletion

  Updates foreign key constraints to allow deletion of vesting schedules.
  When a vesting schedule is deleted:
  - Grants will have their vesting_schedule_id set to NULL (ON DELETE SET NULL)
  - Plans will have their vesting_schedule_template_id set to NULL (ON DELETE SET NULL)
  - Milestones will be automatically deleted (already has ON DELETE CASCADE)
*/

-- Fix the foreign key constraint on grants.vesting_schedule_id
DO $$
DECLARE
  v_constraint_name text;
  v_column_attnum smallint;
BEGIN
  -- Get the attribute number for vesting_schedule_id column
  SELECT attnum INTO v_column_attnum
  FROM pg_attribute
  WHERE attrelid = 'grants'::regclass
    AND attname = 'vesting_schedule_id';

  -- Only proceed if column exists
  IF v_column_attnum IS NOT NULL THEN
    -- Find the foreign key constraint name
    SELECT con.conname INTO v_constraint_name
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    WHERE rel.relname = 'grants'
      AND con.contype = 'f'
      AND v_column_attnum = ANY(con.conkey)
      AND con.confrelid = 'vesting_schedules'::regclass;

    -- Drop the existing foreign key constraint if found
    IF v_constraint_name IS NOT NULL THEN
      EXECUTE format('ALTER TABLE grants DROP CONSTRAINT %I', v_constraint_name);
      RAISE NOTICE 'Dropped existing constraint: %', v_constraint_name;
    END IF;

    -- Recreate it with ON DELETE SET NULL so deletion is allowed
    ALTER TABLE grants 
      ADD CONSTRAINT grants_vesting_schedule_id_fkey
      FOREIGN KEY (vesting_schedule_id) 
      REFERENCES vesting_schedules(id) 
      ON DELETE SET NULL;

    RAISE NOTICE 'Updated grants.vesting_schedule_id foreign key to allow deletion (SET NULL)';
  ELSE
    RAISE NOTICE 'Column grants.vesting_schedule_id does not exist, skipping';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error updating grants constraint: %', SQLERRM;
END;
$$;

-- Fix the foreign key constraint on incentive_plans.vesting_schedule_template_id
DO $$
DECLARE
  v_constraint_name text;
  v_column_attnum smallint;
BEGIN
  -- Get the attribute number for vesting_schedule_template_id column
  SELECT attnum INTO v_column_attnum
  FROM pg_attribute
  WHERE attrelid = 'incentive_plans'::regclass
    AND attname = 'vesting_schedule_template_id';

  -- Only proceed if column exists
  IF v_column_attnum IS NOT NULL THEN
    -- Find the foreign key constraint name
    SELECT con.conname INTO v_constraint_name
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    WHERE rel.relname = 'incentive_plans'
      AND con.contype = 'f'
      AND v_column_attnum = ANY(con.conkey)
      AND con.confrelid = 'vesting_schedules'::regclass;

    -- Drop the existing foreign key constraint if found
    IF v_constraint_name IS NOT NULL THEN
      EXECUTE format('ALTER TABLE incentive_plans DROP CONSTRAINT %I', v_constraint_name);
      RAISE NOTICE 'Dropped existing constraint: %', v_constraint_name;
    END IF;

    -- Recreate it with ON DELETE SET NULL so deletion is allowed
    ALTER TABLE incentive_plans 
      ADD CONSTRAINT incentive_plans_vesting_schedule_template_id_fkey
      FOREIGN KEY (vesting_schedule_template_id) 
      REFERENCES vesting_schedules(id) 
      ON DELETE SET NULL;

    RAISE NOTICE 'Updated incentive_plans.vesting_schedule_template_id foreign key to allow deletion (SET NULL)';
  ELSE
    RAISE NOTICE 'Column incentive_plans.vesting_schedule_template_id does not exist, skipping';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error updating incentive_plans constraint: %', SQLERRM;
END;
$$;

