-- Check ACTUAL employee emails in the database
-- Run this SQL directly in your Supabase SQL Editor

-- First, let's see all employees under Derayah Financial
SELECT 
  '=== ALL EMPLOYEES UNDER DERAyah FINANCIAL ===' as info;

SELECT 
  id,
  employee_number,
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

-- Now let's check specifically for the emails mentioned
SELECT 
  '=== CHECKING SPECIFIC EMAILS ===' as info;

-- Check for Sarah's original email
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM employees WHERE email = 'sarah.mansouri@derayah.com' AND company_id = (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial')) 
    THEN '✓ sarah.mansouri@derayah.com EXISTS'
    ELSE '✗ sarah.mansouri@derayah.com NOT FOUND'
  END as sarah_original;

-- Check for Sarah's updated email
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM employees WHERE email = 'wajehah.sa@gmail.com' AND company_id = (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial')) 
    THEN '✓ wajehah.sa@gmail.com EXISTS'
    ELSE '✗ wajehah.sa@gmail.com NOT FOUND'
  END as sarah_updated;

-- Check for Khalid's email
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM employees WHERE email = 'khalid.zahrani@derayah.com' AND company_id = (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial')) 
    THEN '✓ khalid.zahrani@derayah.com EXISTS'
    ELSE '✗ khalid.zahrani@derayah.com NOT FOUND'
  END as khalid_email;

-- Check for Fatima's original email
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM employees WHERE email = 'fatima.rashid@derayah.com' AND company_id = (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial')) 
    THEN '✓ fatima.rashid@derayah.com EXISTS'
    ELSE '✗ fatima.rashid@derayah.com NOT FOUND'
  END as fatima_original;

-- Check for any other emails that might exist
SELECT 
  '=== OTHER EMAILS FOUND ===' as info;

SELECT DISTINCT email, first_name_en, last_name_en
FROM employees 
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
AND email NOT IN ('sarah.mansouri@derayah.com', 'khalid.zahrani@derayah.com', 'fatima.rashid@derayah.com', 'wajehah.sa@gmail.com')
ORDER BY email;
