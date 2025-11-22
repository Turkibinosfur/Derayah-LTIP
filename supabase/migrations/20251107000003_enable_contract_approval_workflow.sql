-- Enable contract approval workflow enhancements

-- 1. Track approver metadata on generated documents
ALTER TABLE generated_documents
  ADD COLUMN IF NOT EXISTS approved_by uuid REFERENCES auth.users(id);

ALTER TABLE generated_documents
  ADD COLUMN IF NOT EXISTS approved_at timestamptz;

-- 2. Refresh document status trigger to preserve approval metadata
CREATE OR REPLACE FUNCTION update_document_status_on_grant_change()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE generated_documents
  SET
    status = CASE
      WHEN NEW.employee_acceptance_at IS NOT NULL THEN 'signed'::document_status
      WHEN NEW.status = 'pending_signature' THEN 'pending_signature'::document_status
      WHEN NEW.status = 'active' AND OLD.employee_acceptance_at IS NULL THEN 'signed'::document_status
      ELSE 'draft'::document_status
    END,
    approved_by = CASE
      WHEN NEW.employee_acceptance_at IS NOT NULL OR NEW.status = 'pending_signature' THEN approved_by
      ELSE NULL
    END,
    approved_at = CASE
      WHEN NEW.employee_acceptance_at IS NOT NULL OR NEW.status = 'pending_signature' THEN approved_at
      ELSE NULL
    END
  WHERE grant_id = NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Refresh trigger to ensure it uses latest function definition
DROP TRIGGER IF EXISTS trigger_update_document_status ON grants;

CREATE TRIGGER trigger_update_document_status
  AFTER UPDATE ON grants
  FOR EACH ROW
  EXECUTE FUNCTION update_document_status_on_grant_change();

-- 4. Update RLS policies to allow authorized approvers
DROP POLICY IF EXISTS "Admins can manage documents" ON generated_documents;

CREATE POLICY "Authorized users can manage documents"
  ON generated_documents
  FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id
      FROM company_users
      WHERE user_id = auth.uid()
        AND (
          role IN ('super_admin', 'finance_admin')
          OR (
            role IN ('hr_admin', 'legal_admin')
            AND COALESCE((permissions ->> 'contract_approval')::boolean, FALSE)
          )
        )
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id
      FROM company_users
      WHERE user_id = auth.uid()
        AND (
          role IN ('super_admin', 'finance_admin')
          OR (
            role IN ('hr_admin', 'legal_admin')
            AND COALESCE((permissions ->> 'contract_approval')::boolean, FALSE)
          )
        )
    )
  );

-- 5. Grant approvers the ability to transition grant status
DROP POLICY IF EXISTS "Contract approvers can update grants" ON grants;

CREATE POLICY "Contract approvers can update grants"
  ON grants
  FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id
      FROM company_users
      WHERE user_id = auth.uid()
        AND (
          role IN ('super_admin', 'finance_admin')
          OR (
            role IN ('hr_admin', 'legal_admin')
            AND COALESCE((permissions ->> 'contract_approval')::boolean, FALSE)
          )
        )
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id
      FROM company_users
      WHERE user_id = auth.uid()
        AND (
          role IN ('super_admin', 'finance_admin')
          OR (
            role IN ('hr_admin', 'legal_admin')
            AND COALESCE((permissions ->> 'contract_approval')::boolean, FALSE)
          )
        )
    )
  );

