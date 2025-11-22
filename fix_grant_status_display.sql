-- Comprehensive fix for grant status display issues
-- This script ensures that grants show the correct status in the company portal

-- First, let's check all grants and their current status
SELECT 
    'CURRENT GRANT STATUS' as info,
    g.id,
    g.grant_number,
    g.status,
    g.employee_acceptance_at,
    e.email,
    e.first_name_en,
    e.last_name_en,
    ip.plan_name_en
FROM grants g
JOIN employees e ON g.employee_id = e.id
LEFT JOIN incentive_plans ip ON g.plan_id = ip.id
ORDER BY g.created_at DESC;

-- Update grants that have employee acceptance but wrong status
UPDATE grants 
SET 
    status = 'active',
    employee_acceptance_at = COALESCE(employee_acceptance_at, NOW())
WHERE 
    employee_acceptance_at IS NOT NULL 
    AND status != 'active';

-- Update grants that should be active based on acceptance
UPDATE grants 
SET 
    status = 'active'
WHERE 
    status = 'pending_signature' 
    AND employee_acceptance_at IS NOT NULL;

-- Check the status after updates
SELECT 
    'AFTER STATUS UPDATES' as info,
    g.id,
    g.grant_number,
    g.status,
    g.employee_acceptance_at,
    e.email,
    e.first_name_en,
    e.last_name_en
FROM grants g
JOIN employees e ON g.employee_id = e.id
ORDER BY g.created_at DESC;

-- Also update any related documents to reflect the grant status
UPDATE documents 
SET 
    status = CASE 
        WHEN g.status = 'active' THEN 'signed'
        WHEN g.status = 'pending_signature' THEN 'pending_signature'
        ELSE 'draft'
    END,
    updated_at = NOW()
FROM grants g
WHERE documents.grant_id = g.id;

-- Check document status after updates
SELECT 
    'DOCUMENT STATUS AFTER UPDATE' as info,
    d.id,
    d.document_type,
    d.file_name,
    d.status,
    g.grant_number,
    g.status as grant_status,
    e.email
FROM documents d
JOIN grants g ON d.grant_id = g.id
JOIN employees e ON g.employee_id = e.id
ORDER BY d.created_at DESC;

-- Final verification - show all grants with their status
SELECT 
    'FINAL VERIFICATION' as info,
    g.grant_number,
    g.status as grant_status,
    g.employee_acceptance_at,
    e.email,
    e.first_name_en,
    e.last_name_en,
    CASE 
        WHEN g.status = 'active' THEN '✓ Should show as Active in portal'
        WHEN g.status = 'pending_signature' THEN '⏳ Should show as Pending Signature in portal'
        ELSE '❓ Unknown status: ' || g.status
    END as portal_display
FROM grants g
JOIN employees e ON g.employee_id = e.id
ORDER BY g.created_at DESC;
