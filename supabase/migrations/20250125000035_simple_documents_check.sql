/*
  Simple migration to check what columns exist in the documents table.
  This will help us understand the actual table structure.
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

  -- Check if documents table exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'documents') THEN
    RAISE NOTICE '✓ documents table exists';
    
    -- Show documents table structure
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
    
    -- Check if there are any documents in the table
    SELECT COUNT(*) INTO rec FROM documents WHERE company_id = v_company_id;
    RAISE NOTICE 'Number of documents in company: %', rec.count;
    
    -- Show sample documents (only if table has data)
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
    ELSE
      RAISE NOTICE 'No documents found in the table';
    END IF;
    
  ELSE
    RAISE NOTICE '✗ documents table does not exist';
  END IF;

  RAISE NOTICE '=== RECOMMENDATIONS ===';
  RAISE NOTICE 'Based on the table structure above, use only the columns that exist.';
  RAISE NOTICE 'Common columns might be: id, company_id, employee_id, document_type, file_path, status, created_at, updated_at';

END $$;
