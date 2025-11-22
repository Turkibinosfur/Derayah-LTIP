/*
  Migration to check for email constraints that might be causing update failures.
  This migration will identify any unique constraints or triggers on the email field.
*/

DO $$
DECLARE
  rec RECORD;
  v_company_id uuid;
  v_duplicate_emails integer;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';

  IF v_company_id IS NULL THEN
    RAISE NOTICE 'Company "Derayah Financial" not found. Exiting migration.';
    RETURN;
  END IF;

  RAISE NOTICE 'Processing company ID: %', v_company_id;

  -- Check for unique constraints on email
  RAISE NOTICE '=== UNIQUE CONSTRAINTS ON EMAIL ===';
  FOR rec IN
    SELECT constraint_name, constraint_type, table_name
    FROM information_schema.table_constraints 
    WHERE table_name = 'employees' 
    AND constraint_type = 'UNIQUE'
  LOOP
    RAISE NOTICE 'Unique Constraint: % | Type: % | Table: %', 
      rec.constraint_name, rec.constraint_type, rec.table_name;
  END LOOP;

  -- Check for indexes on email column
  RAISE NOTICE '=== INDEXES ON EMAIL COLUMN ===';
  FOR rec IN
    SELECT indexname, indexdef
    FROM pg_indexes 
    WHERE tablename = 'employees' 
    AND indexdef LIKE '%email%'
  LOOP
    RAISE NOTICE 'Index: % | Definition: %', rec.indexname, rec.indexdef;
  END LOOP;

  -- Check for duplicate emails in the company
  SELECT COUNT(*) INTO v_duplicate_emails
  FROM (
    SELECT email, COUNT(*) as count
    FROM employees
    WHERE company_id = v_company_id
    AND email IS NOT NULL
    GROUP BY email
    HAVING COUNT(*) > 1
  ) duplicates;

  RAISE NOTICE 'Number of duplicate emails in company: %', v_duplicate_emails;

  -- Show all emails in the company
  RAISE NOTICE '=== ALL EMAILS IN COMPANY ===';
  FOR rec IN
    SELECT email, COUNT(*) as count
    FROM employees
    WHERE company_id = v_company_id
    AND email IS NOT NULL
    GROUP BY email
    ORDER BY email
  LOOP
    RAISE NOTICE 'Email: % | Count: %', rec.email, rec.count;
  END LOOP;

  -- Check if there are any triggers on employees table
  RAISE NOTICE '=== TRIGGERS ON EMPLOYEES TABLE ===';
  FOR rec IN
    SELECT trigger_name, event_manipulation, action_timing, action_statement
    FROM information_schema.triggers 
    WHERE event_object_table = 'employees'
  LOOP
    RAISE NOTICE 'Trigger: % | Event: % | Timing: % | Statement: %', 
      rec.trigger_name, rec.event_manipulation, rec.action_timing, rec.action_statement;
  END LOOP;

END $$;
