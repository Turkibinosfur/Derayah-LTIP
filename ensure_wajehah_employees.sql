-- Ensure wajehah.com@gmail.com and employee@example.com have employee records
-- Run this SQL directly in your Supabase SQL Editor

-- First, let's see what employees currently exist
SELECT 
  '=== CURRENT EMPLOYEES ===' as info;

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
ORDER BY first_name_en;

-- Now let's ensure both emails have employee records
-- This will create or update employee records for both emails

-- For wajehah.com@gmail.com
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
  'EMP-WAJEHAH-001',
  '1234567890',
  'wajehah.com@gmail.com',
  'Wajehah',
  'Al-Zahrani',
  'Finance',
  'Senior Analyst',
  '2024-01-01',
  'active',
  true,
  'wajehah.com',
  'WajehahCom123!',
  now(),
  now()
WHERE NOT EXISTS (
  SELECT 1 FROM employees 
  WHERE email = 'wajehah.com@gmail.com' 
  AND company_id = (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial')
);

-- For employee@example.com
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
  '1234567891',
  'employee@example.com',
  'Fatima',
  'Al-Zahrani',
  'Finance',
  'Senior Analyst',
  '2024-01-01',
  'active',
  true,
  'wajehah.sa',
  'WajehahSa123!',
  now(),
  now()
WHERE NOT EXISTS (
  SELECT 1 FROM employees 
  WHERE email = 'employee@example.com' 
  AND company_id = (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial')
);

-- Update existing records if they exist
UPDATE employees
SET portal_access_enabled = true,
    portal_username = 'wajehah.com',
    portal_password = 'WajehahCom123!'
WHERE email = 'wajehah.com@gmail.com'
AND company_id = (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial');

UPDATE employees
SET portal_access_enabled = true,
    portal_username = 'wajehah.sa',
    portal_password = 'WajehahSa123!'
WHERE email = 'employee@example.com'
AND company_id = (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial');

-- Show final results
SELECT 
  '=== FINAL EMPLOYEE RECORDS ===' as info;

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
AND email IN ('wajehah.com@gmail.com', 'employee@example.com')
ORDER BY email;

-- Show all employees
SELECT 
  '=== ALL EMPLOYEES AFTER UPDATE ===' as info;

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
ORDER BY first_name_en;
