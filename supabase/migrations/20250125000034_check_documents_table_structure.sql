/*
  Migration to check the actual structure of the documents table.
  This will help identify the correct column names to use.
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
    
    -- Show sample documents
    RAISE NOTICE '=== SAMPLE DOCUMENTS ===';
    FOR rec IN
      SELECT id, document_type, document_name, status, created_at
      FROM documents
      WHERE company_id = v_company_id
      LIMIT 5
    LOOP
      RAISE NOTICE 'Document: % | Type: % | Name: % | Status: % | Created: %', 
        rec.id, rec.document_type, rec.document_name, rec.status, rec.created_at;
    END LOOP;
    
  ELSE
    RAISE NOTICE '✗ documents table does not exist';
  END IF;

  -- Check if grant_documents table exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'grant_documents') THEN
    RAISE NOTICE '✓ grant_documents table exists';
    
    -- Show grant_documents table structure
    RAISE NOTICE '=== GRANT_DOCUMENTS TABLE STRUCTURE ===';
    FOR rec IN
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'grant_documents' 
      ORDER BY ordinal_position
    LOOP
      RAISE NOTICE 'Column: % | Type: % | Nullable: % | Default: %', 
        rec.column_name, rec.data_type, rec.is_nullable, rec.column_default;
    END LOOP;
    
    -- Check if there are any grant documents
    SELECT COUNT(*) INTO rec FROM grant_documents WHERE company_id = v_company_id;
    RAISE NOTICE 'Number of grant documents in company: %', rec.count;
    
  ELSE
    RAISE NOTICE '✗ grant_documents table does not exist';
  END IF;

  -- Check other document-related tables
  RAISE NOTICE '=== OTHER DOCUMENT TABLES ===';
  FOR rec IN
    SELECT table_name
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND (table_name LIKE '%document%' OR table_name LIKE '%contract%')
    ORDER BY table_name
  LOOP
    RAISE NOTICE 'Document-related table: %', rec.table_name;
  END LOOP;

  RAISE NOTICE '=== RECOMMENDATIONS ===';
  RAISE NOTICE 'Based on the table structure, use the correct column names:';
  RAISE NOTICE '• For documents table: document_name (not title)';
  RAISE NOTICE '• For grant_documents table: document_name (not title)';
  RAISE NOTICE '• Check if both tables exist and use the appropriate one';

END $$;
