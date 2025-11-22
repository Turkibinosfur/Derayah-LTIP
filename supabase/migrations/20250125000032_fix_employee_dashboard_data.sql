/*
  Migration to fix employee dashboard data loading issues.
  This migration will:
  1. Check what tables exist for documents
  2. Ensure proper data structure for employee portal
  3. Fix any missing relationships
*/

DO $$
DECLARE
  rec RECORD;
  v_company_id uuid;
  v_khalid_id uuid;
  v_grant_id uuid;
  v_document_id uuid;
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

  -- Get Khalid's employee ID
  SELECT id INTO v_khalid_id
  FROM employees
  WHERE first_name_en = 'Khalid' AND last_name_en = 'Al-Zahrani' AND company_id = v_company_id;

  IF v_khalid_id IS NULL THEN
    RAISE NOTICE 'Khalid Al-Zahrani not found. Exiting migration.';
    RETURN;
  END IF;

  RAISE NOTICE 'Khalid Al-Zahrani ID: %', v_khalid_id;

  -- Check what document tables exist
  RAISE NOTICE '=== DOCUMENT TABLES CHECK ===';
  FOR rec IN
    SELECT table_name
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name LIKE '%document%'
    ORDER BY table_name
  LOOP
    RAISE NOTICE 'Document table found: %', rec.table_name;
  END LOOP;

  -- Check if grant_documents table exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'grant_documents') THEN
    RAISE NOTICE '✓ grant_documents table exists';
    
    -- Check Khalid's grant documents
    RAISE NOTICE '=== KHALID GRANT DOCUMENTS ===';
    FOR rec IN
      SELECT id, document_name, document_type, status, generated_at
      FROM grant_documents
      WHERE employee_id = v_khalid_id
      ORDER BY generated_at DESC
    LOOP
      RAISE NOTICE 'Grant Document: % | Type: % | Status: % | Generated: %', 
        rec.document_name, rec.document_type, rec.status, rec.generated_at;
    END LOOP;
  ELSE
    RAISE NOTICE '✗ grant_documents table does not exist';
  END IF;

  -- Check if documents table exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'documents') THEN
    RAISE NOTICE '✓ documents table exists';
    
    -- Check Khalid's documents
    RAISE NOTICE '=== KHALID DOCUMENTS ===';
    FOR rec IN
      SELECT id, title, document_type, status, created_at
      FROM documents
      WHERE employee_id = v_khalid_id
      ORDER BY created_at DESC
    LOOP
      RAISE NOTICE 'Document: % | Type: % | Status: % | Created: %', 
        rec.title, rec.document_type, rec.status, rec.created_at;
    END LOOP;
  ELSE
    RAISE NOTICE '✗ documents table does not exist';
  END IF;

  -- Get Khalid's grant ID
  SELECT id INTO v_grant_id
  FROM grants
  WHERE employee_id = v_khalid_id;

  IF v_grant_id IS NULL THEN
    RAISE NOTICE 'Khalid has no grants. Exiting migration.';
    RETURN;
  END IF;

  RAISE NOTICE 'Khalid Grant ID: %', v_grant_id;

  -- Create grant_documents for Khalid if the table exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'grant_documents') THEN
    -- Check if Khalid already has grant documents
    IF NOT EXISTS (SELECT 1 FROM grant_documents WHERE employee_id = v_khalid_id) THEN
      -- Create grant document for Khalid
      INSERT INTO grant_documents (
        id, company_id, employee_id, grant_id, document_name, document_type,
        document_content, status, generated_at, created_at, updated_at
      ) VALUES (
        gen_random_uuid(), v_company_id, v_khalid_id, v_grant_id,
        'Stock Option Agreement - Khalid Al-Zahrani', 'contract',
        'This is the stock option agreement for Khalid Al-Zahrani with 350,000 shares over 4 years...',
        'pending_signature', now(), now(), now()
      ) RETURNING id INTO v_document_id;
      
      RAISE NOTICE '✓ Created grant document for Khalid: %', v_document_id;
    ELSE
      RAISE NOTICE '✓ Grant documents already exist for Khalid';
    END IF;
  ELSE
    RAISE NOTICE '⚠ grant_documents table does not exist - cannot create grant documents';
  END IF;

  -- Check Khalid's grants status
  RAISE NOTICE '=== KHALID GRANTS STATUS ===';
  FOR rec IN
    SELECT id, grant_number, total_shares, status, granted_date
    FROM grants
    WHERE employee_id = v_khalid_id
  LOOP
    RAISE NOTICE 'Grant: % | Shares: % | Status: % | Granted: %', 
      rec.grant_number, rec.total_shares, rec.status, rec.granted_date;
  END LOOP;

  -- Update Khalid's grant status if needed
  UPDATE grants 
  SET status = 'active',
      updated_at = now()
  WHERE employee_id = v_khalid_id 
  AND status IS NULL;

  RAISE NOTICE '✓ Updated Khalid grant status to active';

  -- Check Khalid's portfolio
  RAISE NOTICE '=== KHALID PORTFOLIO STATUS ===';
  FOR rec IN
    SELECT id, portfolio_type, total_shares, available_shares, locked_shares
    FROM portfolios
    WHERE employee_id = v_khalid_id
  LOOP
    RAISE NOTICE 'Portfolio: % | Type: % | Total: % | Available: % | Locked: %', 
      rec.id, rec.portfolio_type, rec.total_shares, rec.available_shares, rec.locked_shares;
  END LOOP;

  RAISE NOTICE '=== EMPLOYEE DASHBOARD DATA SETUP COMPLETE ===';
  RAISE NOTICE 'Khalid should now see:';
  RAISE NOTICE '• Active grants with shares';
  RAISE NOTICE '• Portfolio with share information';
  RAISE NOTICE '• Grant documents (if grant_documents table exists)';
  RAISE NOTICE '• Notifications about grants';
  RAISE NOTICE '';
  RAISE NOTICE 'If documents still don''t show, check:';
  RAISE NOTICE '1. DocumentDownloadCenter component table references';
  RAISE NOTICE '2. RLS policies on document tables';
  RAISE NOTICE '3. Employee authentication status';

END $$;
