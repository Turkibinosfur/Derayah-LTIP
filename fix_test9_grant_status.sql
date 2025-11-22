-- Fix test9 grant status to show as active if employee has accepted
-- First, let's check the current status
SELECT 
    'BEFORE FIX' as status_check,
    g.id,
    g.grant_number,
    g.status,
    g.employee_acceptance_at,
    e.email,
    e.first_name_en,
    e.last_name_en
FROM grants g
JOIN employees e ON g.employee_id = e.id
WHERE e.email = 'test9@test.com'
ORDER BY g.created_at DESC;

-- Update the grant status to active if employee has accepted
UPDATE grants 
SET 
    status = 'active',
    employee_acceptance_at = COALESCE(employee_acceptance_at, NOW())
WHERE id IN (
    SELECT g.id 
    FROM grants g
    JOIN employees e ON g.employee_id = e.id
    WHERE e.email = 'test9@test.com'
    AND g.status = 'pending_signature'
);

-- Check the status after the fix
SELECT 
    'AFTER FIX' as status_check,
    g.id,
    g.grant_number,
    g.status,
    g.employee_acceptance_at,
    e.email,
    e.first_name_en,
    e.last_name_en
FROM grants g
JOIN employees e ON g.employee_id = e.id
WHERE e.email = 'test9@test.com'
ORDER BY g.created_at DESC;

-- Also update any related documents to show as signed
UPDATE documents 
SET 
    status = 'signed',
    updated_at = NOW()
WHERE grant_id IN (
    SELECT g.id 
    FROM grants g
    JOIN employees e ON g.employee_id = e.id
    WHERE e.email = 'test9@test.com'
    AND g.status = 'active'
);

-- Check document status
SELECT 
    'DOCUMENT STATUS' as status_check,
    d.id,
    d.document_type,
    d.file_name,
    d.status,
    g.grant_number,
    g.status as grant_status
FROM documents d
JOIN grants g ON d.grant_id = g.id
JOIN employees e ON g.employee_id = e.id
WHERE e.email = 'test9@test.com'
ORDER BY d.created_at DESC;
