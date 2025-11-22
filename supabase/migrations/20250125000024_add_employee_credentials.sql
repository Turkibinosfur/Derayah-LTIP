/*
  Migration to add employee portal credential columns to the employees table.
  This migration adds the necessary columns for employee portal access.
*/

DO $$
DECLARE
  rec RECORD;
BEGIN
  -- Add portal_username column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'employees' 
    AND column_name = 'portal_username'
  ) THEN
    ALTER TABLE employees ADD COLUMN portal_username TEXT;
    RAISE NOTICE 'Added portal_username column to employees table';
  ELSE
    RAISE NOTICE 'portal_username column already exists in employees table';
  END IF;

  -- Add portal_password column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'employees' 
    AND column_name = 'portal_password'
  ) THEN
    ALTER TABLE employees ADD COLUMN portal_password TEXT;
    RAISE NOTICE 'Added portal_password column to employees table';
  ELSE
    RAISE NOTICE 'portal_password column already exists in employees table';
  END IF;

  -- Add portal_access_enabled column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'employees' 
    AND column_name = 'portal_access_enabled'
  ) THEN
    ALTER TABLE employees ADD COLUMN portal_access_enabled BOOLEAN DEFAULT FALSE;
    RAISE NOTICE 'Added portal_access_enabled column to employees table';
  ELSE
    RAISE NOTICE 'portal_access_enabled column already exists in employees table';
  END IF;

  -- Show current employees table structure
  RAISE NOTICE '=== CURRENT EMPLOYEES TABLE STRUCTURE ===';
  FOR rec IN
    SELECT column_name, data_type, is_nullable, column_default
    FROM information_schema.columns 
    WHERE table_name = 'employees' 
    ORDER BY ordinal_position
  LOOP
    RAISE NOTICE 'Column: % | Type: % | Nullable: % | Default: %', 
      rec.column_name, rec.data_type, rec.is_nullable, rec.column_default;
  END LOOP;

END $$;
