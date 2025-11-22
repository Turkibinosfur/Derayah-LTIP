/*
  Fix Document Status Update Trigger
  
  Problem: When a grant is accepted (employee_acceptance_at is set), the generated_documents 
  status is not automatically updated to 'signed'. The frontend calculates this dynamically,
  but the actual database record remains unchanged.
  
  Solution: Create a trigger that automatically updates the document status when a grant
  is accepted or when the grant status changes.
*/

-- First, let's check the current document status for the specific grant
SELECT 
  'CURRENT DOCUMENT STATUS FOR GR-20251025-000005' as info,
  d.id,
  d.document_name,
  d.status as document_status,
  g.grant_number,
  g.status as grant_status,
  g.employee_acceptance_at,
  e.email,
  e.first_name_en,
  e.last_name_en
FROM generated_documents d
LEFT JOIN grants g ON d.grant_id = g.id
LEFT JOIN employees e ON d.employee_id = e.id
WHERE g.grant_number = 'GR-20251025-000005'
ORDER BY d.generated_at DESC;

-- Create a function to update document status based on grant status
CREATE OR REPLACE FUNCTION update_document_status_on_grant_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Update all documents linked to this grant
  UPDATE generated_documents 
  SET 
    status = CASE 
      WHEN NEW.employee_acceptance_at IS NOT NULL THEN 'signed'::document_status
      WHEN NEW.status = 'pending_signature' THEN 'pending_signature'::document_status
      WHEN NEW.status = 'active' AND OLD.employee_acceptance_at IS NULL THEN 'signed'::document_status
      ELSE 'draft'::document_status
    END
  WHERE grant_id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on grants table
DROP TRIGGER IF EXISTS trigger_update_document_status ON grants;

CREATE TRIGGER trigger_update_document_status
  AFTER UPDATE ON grants
  FOR EACH ROW
  EXECUTE FUNCTION update_document_status_on_grant_change();

-- Manually update existing documents that should be marked as signed
UPDATE generated_documents 
SET 
  status = CASE 
    WHEN g.employee_acceptance_at IS NOT NULL THEN 'signed'::document_status
    WHEN g.status = 'pending_signature' THEN 'pending_signature'::document_status
    ELSE 'draft'::document_status
  END
FROM grants g
WHERE generated_documents.grant_id = g.id;

-- Check the document status after the update
SELECT 
  'AFTER DOCUMENT STATUS UPDATE' as info,
  d.id,
  d.document_name,
  d.status as document_status,
  g.grant_number,
  g.status as grant_status,
  g.employee_acceptance_at,
  e.email,
  e.first_name_en,
  e.last_name_en
FROM generated_documents d
LEFT JOIN grants g ON d.grant_id = g.id
LEFT JOIN employees e ON d.employee_id = e.id
WHERE g.grant_number = 'GR-20251025-000005'
ORDER BY d.generated_at DESC;

-- Test the trigger by checking all documents with their grant status
SELECT 
  'ALL DOCUMENTS STATUS CHECK' as info,
  d.id,
  d.document_name,
  d.status as document_status,
  g.grant_number,
  g.status as grant_status,
  g.employee_acceptance_at,
  e.email,
  e.first_name_en,
  e.last_name_en,
  CASE 
    WHEN g.employee_acceptance_at IS NOT NULL THEN '✓ SHOULD BE SIGNED'
    WHEN g.status = 'pending_signature' THEN '⏳ PENDING SIGNATURE'
    ELSE '📝 DRAFT'
  END as expected_status
FROM generated_documents d
LEFT JOIN grants g ON d.grant_id = g.id
LEFT JOIN employees e ON d.employee_id = e.id
ORDER BY d.generated_at DESC;

-- Verify the trigger was created
SELECT 
  'TRIGGER VERIFICATION' as info,
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'grants' 
AND trigger_name = 'trigger_update_document_status';
