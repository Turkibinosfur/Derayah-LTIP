-- Check CURRENT employee emails in the database
-- Run this SQL directly in your Supabase SQL Editor

-- Show all employees under Derayah Financial with their current emails
SELECT 
  '=== CURRENT EMPLOYEE EMAILS IN DATABASE ===' as info;

SELECT 
  id,
  first_name_en,
  last_name_en,
  email,
  portal_access_enabled,
  portal_username,
  portal_password,
  created_at
FROM employees 
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
ORDER BY first_name_en;

-- Check specifically for the emails you mentioned
SELECT 
  '=== CHECKING SPECIFIC EMAILS ===' as info;

-- Check for wajehah.com@gmail.com
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM employees WHERE email = 'wajehah.com@gmail.com' AND company_id = (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial')) 
    THEN '✓ wajehah.com@gmail.com EXISTS'
    ELSE '✗ wajehah.com@gmail.com NOT FOUND'
  END as wajehah_com_status;

-- Check for wajehah.sa@gmail.com
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM employees WHERE email = 'wajehah.sa@gmail.com' AND company_id = (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial')) 
    THEN '✓ wajehah.sa@gmail.com EXISTS'
    ELSE '✗ wajehah.sa@gmail.com NOT FOUND'
  END as wajehah_sa_status;

-- Show all unique emails in the database
SELECT 
  '=== ALL UNIQUE EMAILS IN DATABASE ===' as info;

SELECT DISTINCT email, first_name_en, last_name_en
FROM employees 
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
ORDER BY email;
