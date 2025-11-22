-- Create All Missing Auth Users
-- This script provides instructions for creating auth users for all employees

-- 1. Find all employees without auth users
SELECT 
  '=== EMPLOYEES WITHOUT AUTH USERS ===' as step,
  e.id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.portal_username,
  e.portal_password,
  e.created_at
FROM employees e
WHERE e.portal_access_enabled = true 
  AND e.user_id IS NULL
ORDER BY e.created_at DESC;

-- 2. Show detailed instructions for each employee
DO $$
DECLARE
  rec RECORD;
  v_count integer := 0;
BEGIN
  -- Count employees without auth users
  SELECT COUNT(*) INTO v_count
  FROM employees e
  WHERE e.portal_access_enabled = true 
    AND e.user_id IS NULL;
  
  IF v_count = 0 THEN
    RAISE NOTICE 'All employees with portal access have linked auth users.';
    RETURN;
  END IF;
  
  RAISE NOTICE '=== AUTH USERS NEEDED ===';
  RAISE NOTICE 'Found % employees without auth users:', v_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Please create auth users for the following employees:';
  RAISE NOTICE '';
  
  -- Show each employee that needs an auth user
  FOR rec IN 
    SELECT e.email, e.portal_username, e.portal_password, e.first_name_en, e.last_name_en
    FROM employees e
    WHERE e.portal_access_enabled = true 
      AND e.user_id IS NULL
    ORDER BY e.created_at DESC
  LOOP
    RAISE NOTICE 'Employee: % %', rec.first_name_en, rec.last_name_en;
    RAISE NOTICE 'Email: %', rec.email;
    RAISE NOTICE 'Portal Username: %', rec.portal_username;
    RAISE NOTICE 'Portal Password: %', rec.portal_password;
    RAISE NOTICE '---';
  END LOOP;
  
  RAISE NOTICE '';
  RAISE NOTICE 'INSTRUCTIONS:';
  RAISE NOTICE '1. Go to Supabase Dashboard > Authentication > Users';
  RAISE NOTICE '2. Click "Add user" for each employee above';
  RAISE NOTICE '3. Use the email and portal password shown above';
  RAISE NOTICE '4. Set Email Confirm to true';
  RAISE NOTICE '5. After creating all auth users, run the link_auth_users.sql script';
  
END;
$$;

-- 3. Show current auth users for reference
SELECT 
  '=== CURRENT AUTH USERS ===' as step,
  id,
  email,
  email_confirmed_at,
  created_at
FROM auth.users 
ORDER BY created_at DESC;

-- 4. Show employees who can already login
SELECT 
  '=== EMPLOYEES WHO CAN LOGIN ===' as step,
  e.id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.portal_username,
  u.email as auth_email,
  u.email_confirmed_at
FROM employees e
JOIN auth.users u ON e.user_id = u.id
WHERE e.portal_access_enabled = true
ORDER BY e.created_at DESC;

-- 5. Summary statistics
SELECT 
  '=== SUMMARY ===' as step,
  COUNT(*) as total_employees,
  COUNT(CASE WHEN portal_access_enabled = true THEN 1 END) as employees_with_portal_access,
  COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as employees_with_linked_auth_users,
  COUNT(CASE WHEN portal_access_enabled = true AND user_id IS NULL THEN 1 END) as employees_without_auth_users
FROM employees;
