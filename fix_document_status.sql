-- Fix document status in the company portal Documents page
-- This script updates document status based on grant status

-- First, check current document status
SELECT 
    'CURRENT DOCUMENT STATUS' as info,
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
ORDER BY d.generated_at DESC;

-- Update document status based on employee acceptance timestamp
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

-- Check document status after updates
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
ORDER BY d.generated_at DESC;

-- Specifically check test9's document
SELECT 
    'TEST9 DOCUMENT STATUS' as info,
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
WHERE e.email = 'test9@test.com'
ORDER BY d.generated_at DESC;
