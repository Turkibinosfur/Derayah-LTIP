-- Update Three Main Employee Emails for Derayah Financial
-- Run this SQL directly in your Supabase SQL Editor

-- Update all three main employees with realistic Gmail addresses
UPDATE employees
SET email = 'employee@example.com',
    portal_access_enabled = true,
    portal_username = 'wajehah.sa',
    portal_password = 'Wajehah123!'
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
AND first_name_en = 'Sarah'
AND last_name_en = 'Al-Mansouri';

UPDATE employees
SET email = 'khalid.zahrani@gmail.com',
    portal_access_enabled = true,
    portal_username = 'khalid.zahrani',
    portal_password = 'Khalid123!'
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
AND first_name_en = 'Khalid'
AND last_name_en = 'Al-Zahrani';

UPDATE employees
SET email = 'fatima.rashid@gmail.com',
    portal_access_enabled = true,
    portal_username = 'fatima.rashid',
    portal_password = 'Fatima123!'
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
AND first_name_en = 'Fatima'
AND last_name_en = 'Al-Rashid';

-- Show the updated emails
SELECT 
  '=== UPDATED EMPLOYEE EMAILS ===' as info;

SELECT 
  first_name_en,
  last_name_en,
  email,
  portal_access_enabled,
  portal_username,
  portal_password
FROM employees 
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
ORDER BY first_name_en;
