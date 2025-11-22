-- Link Auth Users to Employee Records
-- This script links existing auth users to employee records

-- 1. Check current linking status
SELECT 
  '=== CURRENT LINKING STATUS ===' as step,
  e.id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id,
  e.portal_access_enabled,
  CASE 
    WHEN u.id IS NOT NULL THEN 'Linked' 
    ELSE 'Not linked' 
  END as link_status,
  u.email as auth_email
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
WHERE e.portal_access_enabled = true
ORDER BY e.created_at DESC;

-- 2. Link auth users to employee records
DO $$
DECLARE
  rec RECORD;
  v_linked_count integer := 0;
  v_total_count integer := 0;
BEGIN
  -- Count total employees with portal access
  SELECT COUNT(*) INTO v_total_count
  FROM employees e
  WHERE e.portal_access_enabled = true;
  
  -- Link each employee to their corresponding auth user
  FOR rec IN 
    SELECT e.id, e.email, e.first_name_en, e.last_name_en
    FROM employees e
    WHERE e.portal_access_enabled = true
    ORDER BY e.created_at DESC
  LOOP
    -- Try to find matching auth user
    UPDATE employees SET
      user_id = (
        SELECT id FROM auth.users WHERE email = rec.email
      ),
      updated_at = now()
    WHERE id = rec.id
      AND user_id IS NULL;
    
    -- Check if linking was successful
    IF FOUND THEN
      v_linked_count := v_linked_count + 1;
      RAISE NOTICE 'Linked employee % % (%) to auth user', 
        rec.first_name_en, rec.last_name_en, rec.email;
    ELSE
      RAISE NOTICE 'No auth user found for employee % % (%)', 
        rec.first_name_en, rec.last_name_en, rec.email;
    END IF;
  END LOOP;
  
  RAISE NOTICE '=== LINKING COMPLETE ===';
  RAISE NOTICE 'Total employees with portal access: %', v_total_count;
  RAISE NOTICE 'Successfully linked: %', v_linked_count;
  RAISE NOTICE 'Still need auth users: %', v_total_count - v_linked_count;
  
END;
$$;

-- 3. Final verification
SELECT 
  '=== FINAL VERIFICATION ===' as step,
  e.id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id,
  e.portal_access_enabled,
  u.email as auth_email,
  u.email_confirmed_at,
  CASE 
    WHEN u.id IS NOT NULL THEN 'SUCCESS: Can login' 
    ELSE 'FAILED: Cannot login - no auth user' 
  END as login_status
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
WHERE e.portal_access_enabled = true
ORDER BY e.created_at DESC;

-- 4. Test the exact query used by EmployeeLogin.tsx for each employee
SELECT 
  '=== LOGIN QUERY TEST ===' as step,
  e.id,
  e.company_id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id
FROM employees e
WHERE e.user_id IN (
  SELECT id FROM auth.users WHERE email IN (
    SELECT email FROM employees WHERE portal_access_enabled = true
  )
);
