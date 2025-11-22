/*
  # Fix ALL Foreign Key Constraints for Vesting Schedule Deletion

  This migration finds and fixes ALL foreign key constraints that reference
  vesting_schedules, ensuring they allow deletion by using ON DELETE SET NULL.
  
  This is a comprehensive fix that will handle any constraint names.
*/

DO $$
DECLARE
  v_constraint_record RECORD;
  v_sql text;
  v_delete_rule text;
BEGIN
  -- Find all foreign key constraints that reference vesting_schedules
  FOR v_constraint_record IN
    SELECT 
      tc.table_name,
      tc.constraint_name,
      kcu.column_name,
      rc.delete_rule
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
    JOIN information_schema.referential_constraints AS rc
      ON rc.constraint_name = tc.constraint_name
      AND rc.constraint_schema = tc.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND ccu.table_name = 'vesting_schedules'
      AND ccu.table_schema = 'public'
      -- Only fix constraints that don't already have the correct delete rule
      -- vesting_milestones should have CASCADE, others should have SET NULL
      AND NOT (
        (tc.table_name = 'vesting_milestones' AND rc.delete_rule = 'CASCADE')
        OR (tc.table_name != 'vesting_milestones' AND rc.delete_rule = 'SET NULL')
      )
  LOOP
    RAISE NOTICE 'Found constraint: %.% (%) - current delete_rule: %', 
      v_constraint_record.table_name, 
      v_constraint_record.constraint_name,
      v_constraint_record.column_name,
      v_constraint_record.delete_rule;

    -- Determine the correct delete rule
    -- milestones should cascade, everything else should set null
    IF v_constraint_record.table_name = 'vesting_milestones' THEN
      v_delete_rule := 'CASCADE';
    ELSE
      v_delete_rule := 'SET NULL';
    END IF;

    -- Drop the existing constraint
    v_sql := format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', 
      v_constraint_record.table_name, 
      v_constraint_record.constraint_name);
    
    EXECUTE v_sql;
    RAISE NOTICE 'Dropped constraint: %', v_constraint_record.constraint_name;

    -- Recreate with the correct delete rule
    v_sql := format(
      'ALTER TABLE %I ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES vesting_schedules(id) ON DELETE %s',
      v_constraint_record.table_name,
      v_constraint_record.constraint_name,
      v_constraint_record.column_name,
      v_delete_rule
    );
    
    EXECUTE v_sql;
    RAISE NOTICE 'Recreated constraint: % with ON DELETE %', v_constraint_record.constraint_name, v_delete_rule;
  END LOOP;

  RAISE NOTICE 'Completed fixing all foreign key constraints for vesting_schedules';
END;
$$;

