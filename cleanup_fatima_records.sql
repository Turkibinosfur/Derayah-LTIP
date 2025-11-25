-- Clean up Fatima records - Remove Fatima Al-Rashid and ensure everything is linked to Fatima Al-Zahrani
-- Run this SQL directly in your Supabase SQL Editor

-- First, let's see what Fatima records currently exist
SELECT 
  '=== CURRENT FATIMA RECORDS ===' as info;

SELECT 
  id,
  first_name_en,
  last_name_en,
  email,
  portal_access_enabled,
  created_at
FROM employees 
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
AND (first_name_en ILIKE '%fatima%' OR last_name_en ILIKE '%rashid%' OR last_name_en ILIKE '%zahrani%')
ORDER BY first_name_en, last_name_en;

-- Now let's clean up and consolidate Fatima records
DO $$
DECLARE
  v_company_id uuid;
  v_fatima_zahrani_id uuid;
  v_fatima_rashid_id uuid;
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
  
  RAISE NOTICE 'Cleaning up Fatima records...';
  
  -- Find Fatima Al-Zahrani record (the one we want to keep)
  SELECT id INTO v_fatima_zahrani_id
  FROM employees
  WHERE company_id = v_company_id
  AND first_name_en = 'Fatima'
  AND last_name_en = 'Al-Zahrani';
  
  -- Find Fatima Al-Rashid record (the one we want to remove)
  SELECT id INTO v_fatima_rashid_id
  FROM employees
  WHERE company_id = v_company_id
  AND first_name_en = 'Fatima'
  AND last_name_en = 'Al-Rashid';
  
  -- If Fatima Al-Zahrani doesn't exist, create her
  IF v_fatima_zahrani_id IS NULL THEN
    RAISE NOTICE 'Creating Fatima Al-Zahrani record...';
    
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
    ) VALUES (
      gen_random_uuid(),
      v_company_id,
      'EMP-FATIMA-001',
      '1234567892',
      'employee@example.com',
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
    ) RETURNING id INTO v_fatima_zahrani_id;
    
    RAISE NOTICE 'Created Fatima Al-Zahrani: %', v_fatima_zahrani_id;
  ELSE
    RAISE NOTICE 'Fatima Al-Zahrani already exists: %', v_fatima_zahrani_id;
    
    -- Update her record to ensure correct email and portal access
    UPDATE employees
    SET email = 'employee@example.com',
        portal_access_enabled = true,
        portal_username = 'wajehah.sa',
        portal_password = 'WajehahSa123!'
    WHERE id = v_fatima_zahrani_id;
    
    RAISE NOTICE 'Updated Fatima Al-Zahrani with correct email and portal access';
  END IF;
  
  -- If Fatima Al-Rashid exists, we need to transfer any related data before deleting
  IF v_fatima_rashid_id IS NOT NULL THEN
    RAISE NOTICE 'Found Fatima Al-Rashid: %, transferring data to Fatima Al-Zahrani...', v_fatima_rashid_id;
    
    -- Transfer any grants from Fatima Al-Rashid to Fatima Al-Zahrani
    UPDATE grants
    SET employee_id = v_fatima_zahrani_id
    WHERE employee_id = v_fatima_rashid_id;
    
    -- Transfer any portfolios from Fatima Al-Rashid to Fatima Al-Zahrani
    UPDATE portfolios
    SET employee_id = v_fatima_zahrani_id
    WHERE employee_id = v_fatima_rashid_id;
    
    -- Transfer any vesting schedules from Fatima Al-Rashid to Fatima Al-Zahrani
    UPDATE vesting_schedules
    SET grant_id = (
      SELECT g.id FROM grants g 
      WHERE g.employee_id = v_fatima_zahrani_id 
      LIMIT 1
    )
    WHERE grant_id IN (
      SELECT id FROM grants WHERE employee_id = v_fatima_rashid_id
    );
    
    -- Transfer any documents from Fatima Al-Rashid to Fatima Al-Zahrani
    UPDATE documents
    SET employee_id = v_fatima_zahrani_id
    WHERE employee_id = v_fatima_rashid_id;
    
    -- Transfer any notifications from Fatima Al-Rashid to Fatima Al-Zahrani
    UPDATE employee_notifications
    SET employee_id = v_fatima_zahrani_id
    WHERE employee_id = v_fatima_rashid_id;
    
    -- Now delete Fatima Al-Rashid
    DELETE FROM employees
    WHERE id = v_fatima_rashid_id;
    
    RAISE NOTICE 'Deleted Fatima Al-Rashid and transferred all related data to Fatima Al-Zahrani';
  ELSE
    RAISE NOTICE 'No Fatima Al-Rashid record found';
  END IF;
  
  -- Clean up any other Fatima records that might exist
  FOR v_employee_count IN 
    SELECT COUNT(*) FROM employees 
    WHERE company_id = v_company_id
    AND first_name_en = 'Fatima'
    AND last_name_en != 'Al-Zahrani'
  LOOP
    IF v_employee_count > 0 THEN
      RAISE NOTICE 'Found % other Fatima records, cleaning up...', v_employee_count;
      
      -- Delete any other Fatima records
      DELETE FROM employees
      WHERE company_id = v_company_id
      AND first_name_en = 'Fatima'
      AND last_name_en != 'Al-Zahrani';
      
      RAISE NOTICE 'Cleaned up % other Fatima records', v_employee_count;
    END IF;
  END LOOP;
  
  RAISE NOTICE 'Fatima cleanup completed successfully';
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error during Fatima cleanup: %', SQLERRM;
END;
$$;

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
  portal_password,
  created_at
FROM employees 
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
AND first_name_en = 'Fatima'
ORDER BY last_name_en;

-- Show all employees to verify cleanup
SELECT 
  '=== ALL EMPLOYEES AFTER CLEANUP ===' as info;

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
