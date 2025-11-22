-- Simple Fatima cleanup - Ensure only Fatima Al-Zahrani exists with wajehah.sa@gmail.com
-- Run this SQL directly in your Supabase SQL Editor

-- First, delete any Fatima Al-Rashid records
DELETE FROM employees
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
AND first_name_en = 'Fatima'
AND last_name_en = 'Al-Rashid';

-- Delete any other Fatima records that aren't Al-Zahrani
DELETE FROM employees
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
AND first_name_en = 'Fatima'
AND last_name_en != 'Al-Zahrani';

-- Now ensure Fatima Al-Zahrani exists with correct email
INSERT INTO employees (
  id,
  company_id,
  employee_number,
  national_id,
  email,
  first_name_en,
  last_name_en,
  department,
  job_title,
  hire_date,
  employment_status,
  portal_access_enabled,
  portal_username,
  portal_password,
  created_at,
  updated_at
)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'),
  'EMP-FATIMA-001',
  '1234567892',
  'wajehah.sa@gmail.com',
  'Fatima',
  'Al-Zahrani',
  'Data Science',
  'Data Scientist',
  '2023-09-10',
  'active',
  true,
  'wajehah.sa',
  'WajehahSa123!',
  now(),
  now()
WHERE NOT EXISTS (
  SELECT 1 FROM employees 
  WHERE company_id = (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial')
  AND first_name_en = 'Fatima'
  AND last_name_en = 'Al-Zahrani'
);

-- Update existing Fatima Al-Zahrani to ensure correct email and portal access
UPDATE employees
SET email = 'wajehah.sa@gmail.com',
    portal_access_enabled = true,
    portal_username = 'wajehah.sa',
    portal_password = 'WajehahSa123!'
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
AND first_name_en = 'Fatima'
AND last_name_en = 'Al-Zahrani';

-- Show final results
SELECT 
  '=== FINAL FATIMA RECORDS ===' as info;

SELECT 
  id,
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
AND first_name_en = 'Fatima'
ORDER BY last_name_en;

-- Show all employees
SELECT 
  '=== ALL EMPLOYEES ===' as info;

SELECT 
  id,
  first_name_en,
  last_name_en,
  email,
  portal_access_enabled
FROM employees 
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
ORDER BY first_name_en, last_name_en;
