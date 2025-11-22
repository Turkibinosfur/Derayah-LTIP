-- Fix RLS policy for generated_documents to allow company users to insert
-- (similar to how grants can be inserted by any company user)

-- Drop old policies first
DROP POLICY IF EXISTS "Admins can manage documents" ON generated_documents;
DROP POLICY IF EXISTS "Company users can insert documents" ON generated_documents;
DROP POLICY IF EXISTS "Company users can view company documents" ON generated_documents;
DROP POLICY IF EXISTS "Company users can update documents" ON generated_documents;

-- Allow any company user to insert documents for their company
CREATE POLICY "Company users can insert documents"
  ON generated_documents FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
    )
  );

-- Allow any company user to view documents for their company
CREATE POLICY "Company users can view company documents"
  ON generated_documents FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
    )
  );

-- Allow any company user to update documents for their company
CREATE POLICY "Company users can update documents"
  ON generated_documents FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
    )
  );
