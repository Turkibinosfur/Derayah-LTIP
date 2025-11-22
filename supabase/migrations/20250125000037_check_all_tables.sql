/*
  Migration to check the actual structure of all relevant tables.
  This will help us understand what columns exist in each table.
*/

DO $$
DECLARE
  rec RECORD;
  v_company_id uuid;
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

  -- Check documents table structure
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'documents') THEN
    RAISE NOTICE '=== DOCUMENTS TABLE STRUCTURE ===';
    FOR rec IN
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'documents' 
      ORDER BY ordinal_position
    LOOP
      RAISE NOTICE 'Column: % | Type: % | Nullable: % | Default: %', 
        rec.column_name, rec.data_type, rec.is_nullable, rec.column_default;
    END LOOP;
  ELSE
    RAISE NOTICE '✗ documents table does not exist';
  END IF;

  -- Check portfolios table structure
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'portfolios') THEN
    RAISE NOTICE '=== PORTFOLIOS TABLE STRUCTURE ===';
    FOR rec IN
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'portfolios' 
      ORDER BY ordinal_position
    LOOP
      RAISE NOTICE 'Column: % | Type: % | Nullable: % | Default: %', 
        rec.column_name, rec.data_type, rec.is_nullable, rec.column_default;
    END LOOP;
  ELSE
    RAISE NOTICE '✗ portfolios table does not exist';
  END IF;

  -- Check grants table structure
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'grants') THEN
    RAISE NOTICE '=== GRANTS TABLE STRUCTURE ===';
    FOR rec IN
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'grants' 
      ORDER BY ordinal_position
    LOOP
      RAISE NOTICE 'Column: % | Type: % | Nullable: % | Default: %', 
        rec.column_name, rec.data_type, rec.is_nullable, rec.column_default;
    END LOOP;
  ELSE
    RAISE NOTICE '✗ grants table does not exist';
  END IF;

  -- Check employees table structure
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'employees') THEN
    RAISE NOTICE '=== EMPLOYEES TABLE STRUCTURE ===';
    FOR rec IN
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'employees' 
      ORDER BY ordinal_position
    LOOP
      RAISE NOTICE 'Column: % | Type: % | Nullable: % | Default: %', 
        rec.column_name, rec.data_type, rec.is_nullable, rec.column_default;
    END LOOP;
  ELSE
    RAISE NOTICE '✗ employees table does not exist';
  END IF;

  -- Check if there are any documents in the system
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'documents') THEN
    SELECT COUNT(*) INTO rec FROM documents WHERE company_id = v_company_id;
    RAISE NOTICE 'Number of documents in company: %', rec.count;
    
    IF rec.count > 0 THEN
      RAISE NOTICE '=== SAMPLE DOCUMENTS ===';
      FOR rec IN
        SELECT *
        FROM documents
        WHERE company_id = v_company_id
        LIMIT 3
      LOOP
        RAISE NOTICE 'Sample document: %', rec;
      END LOOP;
    END IF;
  END IF;

  RAISE NOTICE '=== RECOMMENDATIONS ===';
  RAISE NOTICE 'Based on the table structures above:';
  RAISE NOTICE '1. Use only the columns that actually exist';
  RAISE NOTICE '2. Check if tables exist before using them';
  RAISE NOTICE '3. Use minimal column sets for safety';

END $$;
