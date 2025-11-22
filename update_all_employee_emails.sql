-- Update ALL Employee Emails for Derayah Financial
-- Run this SQL directly in your Supabase SQL Editor

-- First, let's see current employee emails
SELECT 
  '=== CURRENT EMPLOYEE EMAILS ===' as info;

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

-- Now let's update all employee emails to more realistic ones
DO $$
DECLARE
  v_company_id uuid;
  v_employee_id uuid;
  v_employee_count integer := 0;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE NOTICE 'Derayah Financial company not found';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Updating all employee emails for Derayah Financial...';
  
  -- Update Sarah Al-Mansouri to wajehah.sa@gmail.com
  UPDATE employees
  SET email = 'wajehah.sa@gmail.com',
      portal_access_enabled = true,
      portal_username = 'wajehah.sa',
      portal_password = 'Wajehah123!'
  WHERE company_id = v_company_id
  AND first_name_en = 'Sarah'
  AND last_name_en = 'Al-Mansouri';
  
  IF FOUND THEN
    v_employee_count := v_employee_count + 1;
    RAISE NOTICE 'Updated Sarah Al-Mansouri to wajehah.sa@gmail.com';
  END IF;
  
  -- Update Khalid Al-Zahrani to khalid.zahrani@gmail.com
  UPDATE employees
  SET email = 'khalid.zahrani@gmail.com',
      portal_access_enabled = true,
      portal_username = 'khalid.zahrani',
      portal_password = 'Khalid123!'
  WHERE company_id = v_company_id
  AND first_name_en = 'Khalid'
  AND last_name_en = 'Al-Zahrani';
  
  IF FOUND THEN
    v_employee_count := v_employee_count + 1;
    RAISE NOTICE 'Updated Khalid Al-Zahrani to khalid.zahrani@gmail.com';
  END IF;
  
  -- Update Fatima Al-Rashid to fatima.rashid@gmail.com
  UPDATE employees
  SET email = 'fatima.rashid@gmail.com',
      portal_access_enabled = true,
      portal_username = 'fatima.rashid',
      portal_password = 'Fatima123!'
  WHERE company_id = v_company_id
  AND first_name_en = 'Fatima'
  AND last_name_en = 'Al-Rashid';
  
  IF FOUND THEN
    v_employee_count := v_employee_count + 1;
    RAISE NOTICE 'Updated Fatima Al-Rashid to fatima.rashid@gmail.com';
  END IF;
  
  -- Update any other employees with generic emails
  FOR v_employee_id IN 
    SELECT id FROM employees 
    WHERE company_id = v_company_id
    AND email LIKE '%@derayah.com'
  LOOP
    UPDATE employees
    SET email = LOWER(first_name_en) || '.' || LOWER(REPLACE(last_name_en, ' ', '')) || '@gmail.com',
        portal_access_enabled = true,
        portal_username = LOWER(first_name_en) || '.' || LOWER(REPLACE(last_name_en, ' ', '')),
        portal_password = INITCAP(first_name_en) || '123!'
    WHERE id = v_employee_id;
    
    v_employee_count := v_employee_count + 1;
    RAISE NOTICE 'Updated employee % to new email', v_employee_id;
  END LOOP;
  
  RAISE NOTICE 'Total employees updated: %', v_employee_count;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error updating employee emails: %', SQLERRM;
END;
$$;

-- Verify the updates
SELECT 
  '=== UPDATED EMPLOYEE EMAILS ===' as info;

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
ORDER BY first_name_en;

-- Show login credentials for testing
SELECT 
  '=== EMPLOYEE LOGIN CREDENTIALS ===' as info;

SELECT 
  first_name_en || ' ' || last_name_en as full_name,
  email,
  portal_username,
  portal_password,
  'Use this email and password to login to employee portal' as instructions
FROM employees 
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
AND portal_access_enabled = true
ORDER BY first_name_en;
