-- Check the current status of test9's grant
SELECT 
    g.id,
    g.grant_number,
    g.status,
    g.employee_acceptance_at,
    g.created_at,
    e.first_name_en,
    e.last_name_en,
    e.email,
    ip.plan_name_en
FROM grants g
JOIN employees e ON g.employee_id = e.id
LEFT JOIN incentive_plans ip ON g.plan_id = ip.id
WHERE e.email = 'test9@test.com'
ORDER BY g.created_at DESC;

-- Check if there are any documents for this grant
SELECT 
    d.id,
    d.document_type,
    d.file_name,
    d.created_at,
    g.grant_number,
    g.status as grant_status
FROM documents d
JOIN grants g ON d.grant_id = g.id
JOIN employees e ON g.employee_id = e.id
WHERE e.email = 'test9@test.com'
ORDER BY d.created_at DESC;

-- Check the current grant status in detail
SELECT 
    'Current Grant Status' as info,
    g.status,
    g.employee_acceptance_at,
    CASE 
        WHEN g.employee_acceptance_at IS NOT NULL THEN 'Employee has accepted'
        ELSE 'Employee has not accepted'
    END as acceptance_status,
    CASE 
        WHEN g.status = 'active' THEN 'Grant is active'
        WHEN g.status = 'pending_signature' THEN 'Grant is pending signature'
        ELSE 'Grant status: ' || g.status
    END as status_description
FROM grants g
JOIN employees e ON g.employee_id = e.id
WHERE e.email = 'test9@test.com'
ORDER BY g.created_at DESC
LIMIT 1;
