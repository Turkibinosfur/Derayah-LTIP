-- Test and verify employee acceptance logic for document status
-- This script checks the logic: signed = employee_acceptance_at IS NOT NULL

-- Check all grants with their acceptance status
SELECT 
    'GRANT ACCEPTANCE STATUS' as info,
    g.id,
    g.grant_number,
    g.status as grant_status,
    g.employee_acceptance_at,
    CASE 
        WHEN g.employee_acceptance_at IS NOT NULL THEN '✓ Employee has accepted'
        ELSE '❌ Employee has not accepted'
    END as acceptance_status,
    e.email,
    e.first_name_en,
    e.last_name_en
FROM grants g
JOIN employees e ON g.employee_id = e.id
ORDER BY g.created_at DESC;

-- Check document status based on acceptance logic
SELECT 
    'DOCUMENT STATUS LOGIC' as info,
    d.id,
    d.document_name,
    d.status as current_document_status,
    g.grant_number,
    g.employee_acceptance_at,
    CASE 
        WHEN g.employee_acceptance_at IS NOT NULL THEN 'signed'
        WHEN g.status = 'pending_signature' THEN 'pending_signature'
        ELSE 'draft'
    END as expected_document_status,
    CASE 
        WHEN g.employee_acceptance_at IS NOT NULL THEN '✓ Should be SIGNED'
        WHEN g.status = 'pending_signature' THEN '⏳ Should be PENDING SIGNATURE'
        ELSE '📝 Should be DRAFT'
    END as status_explanation,
    e.email,
    e.first_name_en,
    e.last_name_en
FROM generated_documents d
LEFT JOIN grants g ON d.grant_id = g.id
LEFT JOIN employees e ON d.employee_id = e.id
ORDER BY d.generated_at DESC;

-- Specifically check test9's status
SELECT 
    'TEST9 SPECIFIC STATUS' as info,
    d.id,
    d.document_name,
    d.status as document_status,
    g.grant_number,
    g.status as grant_status,
    g.employee_acceptance_at,
    CASE 
        WHEN g.employee_acceptance_at IS NOT NULL THEN '✓ Employee accepted - should be SIGNED'
        ELSE '❌ Employee not accepted - should be DRAFT/PENDING'
    END as test9_status,
    e.email
FROM generated_documents d
LEFT JOIN grants g ON d.grant_id = g.id
LEFT JOIN employees e ON d.employee_id = e.id
WHERE e.email = 'test9@test.com'
ORDER BY d.generated_at DESC;

-- Update documents based on the correct logic
UPDATE generated_documents 
SET 
    status = CASE 
        WHEN g.employee_acceptance_at IS NOT NULL THEN 'signed'
        WHEN g.status = 'pending_signature' THEN 'pending_signature'
        ELSE 'draft'
    END,
    updated_at = NOW()
FROM grants g
WHERE generated_documents.grant_id = g.id;

-- Verify the update worked
SELECT 
    'AFTER UPDATE - FINAL STATUS' as info,
    d.id,
    d.document_name,
    d.status as document_status,
    g.grant_number,
    g.employee_acceptance_at,
    CASE 
        WHEN g.employee_acceptance_at IS NOT NULL THEN '✓ SIGNED (Employee accepted)'
        WHEN g.status = 'pending_signature' THEN '⏳ PENDING SIGNATURE'
        ELSE '📝 DRAFT (No acceptance)'
    END as final_status_explanation,
    e.email,
    e.first_name_en,
    e.last_name_en
FROM generated_documents d
LEFT JOIN grants g ON d.grant_id = g.id
LEFT JOIN employees e ON d.employee_id = e.id
ORDER BY d.generated_at DESC;
