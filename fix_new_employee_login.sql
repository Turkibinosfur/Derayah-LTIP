-- Fix New Employee Login
-- This script helps fix the "Invalid login credentials" issue for new employees

-- 1. Check current state of employees with portal access
SELECT 
  '=== EMPLOYEES WITH PORTAL ACCESS ===' as step,
  e.id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.portal_access_enabled,
  e.portal_username,
  e.user_id,
  u.email as auth_email,
  u.email_confirmed_at,
  CASE 
    WHEN e.portal_access_enabled = true AND e.user_id IS NOT NULL AND u.id IS NOT NULL 
    THEN 'Can Login' 
    ELSE 'Cannot Login' 
  END as login_status
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
WHERE e.portal_access_enabled = true
ORDER BY e.created_at DESC;

-- 2. Check all auth users
SELECT 
  '=== ALL AUTH USERS ===' as step,
  id,
  email,
  email_confirmed_at,
  created_at,
  last_sign_in_at
FROM auth.users 
ORDER BY created_at DESC;

-- 3. Find employees without auth users
SELECT 
  '=== EMPLOYEES WITHOUT AUTH USERS ===' as step,
  e.id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.portal_username,
  e.portal_password,
  'Needs Auth User Creation' as status
FROM employees e
WHERE e.portal_access_enabled = true 
  AND e.user_id IS NULL
ORDER BY e.created_at DESC;

-- 4. Create a function to link existing auth users to employees
CREATE OR REPLACE FUNCTION link_employee_to_existing_auth_user(
  p_employee_id uuid,
  p_auth_user_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_employee_record employees%ROWTYPE;
  v_auth_user_record auth.users%ROWTYPE;
BEGIN
  -- Get employee record
  SELECT * INTO v_employee_record
  FROM employees
  WHERE id = p_employee_id;
  
  IF v_employee_record IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Employee record not found',
      'employee_id', p_employee_id
    );
  END IF;
  
  -- Get auth user record
  SELECT * INTO v_auth_user_record
  FROM auth.users
  WHERE id = p_auth_user_id;
  
  IF v_auth_user_record IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Auth user not found',
      'auth_user_id', p_auth_user_id
    );
  END IF;
  
  -- Link employee to auth user
  UPDATE employees SET
    user_id = p_auth_user_id,
    updated_at = now()
  WHERE id = p_employee_id;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Employee linked to auth user successfully',
    'employee_id', p_employee_id,
    'auth_user_id', p_auth_user_id,
    'employee_email', v_employee_record.email,
    'auth_email', v_auth_user_record.email
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Error: ' || SQLERRM,
      'employee_id', p_employee_id
    );
END;
$$;

-- 5. Create a function to auto-link employees to existing auth users by email
CREATE OR REPLACE FUNCTION auto_link_employees_by_email()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  rec RECORD;
  v_linked_count integer := 0;
  v_failed_count integer := 0;
BEGIN
  -- Find employees with portal access but no linked auth user
  FOR rec IN 
    SELECT e.id, e.email, e.first_name_en, e.last_name_en
    FROM employees e
    WHERE e.portal_access_enabled = true 
      AND e.user_id IS NULL
      AND EXISTS (
        SELECT 1 FROM auth.users u WHERE u.email = e.email
      )
  LOOP
    -- Link employee to existing auth user
    UPDATE employees SET
      user_id = (SELECT id FROM auth.users WHERE email = rec.email),
      updated_at = now()
    WHERE id = rec.id;
    
    v_linked_count := v_linked_count + 1;
  END LOOP;
  
  -- Find employees with portal access but no auth user exists
  FOR rec IN 
    SELECT e.id, e.email, e.first_name_en, e.last_name_en
    FROM employees e
    WHERE e.portal_access_enabled = true 
      AND e.user_id IS NULL
      AND NOT EXISTS (
        SELECT 1 FROM auth.users u WHERE u.email = e.email
      )
  LOOP
    v_failed_count := v_failed_count + 1;
  END LOOP;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Auto-linking completed',
    'linked_count', v_linked_count,
    'failed_count', v_failed_count,
    'total_processed', v_linked_count + v_failed_count
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Error: ' || SQLERRM
    );
END;
$$;

-- 6. Test auto-linking
SELECT 
  '=== TESTING AUTO-LINKING ===' as step,
  auto_link_employees_by_email();

-- 7. Get employees that still need auth users
SELECT 
  '=== EMPLOYEES STILL NEEDING AUTH USERS ===' as step,
  e.id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.portal_username,
  e.portal_password,
  'Manual Auth User Creation Required' as status
FROM employees e
WHERE e.portal_access_enabled = true 
  AND e.user_id IS NULL
ORDER BY e.created_at DESC;

-- 8. Final verification
SELECT 
  '=== FINAL VERIFICATION ===' as step,
  e.id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.portal_access_enabled,
  e.portal_username,
  e.user_id,
  u.email as auth_email,
  u.email_confirmed_at,
  CASE 
    WHEN e.portal_access_enabled = true AND e.user_id IS NOT NULL AND u.id IS NOT NULL 
    THEN 'Can Login' 
    ELSE 'Cannot Login' 
  END as login_status
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
WHERE e.portal_access_enabled = true
ORDER BY e.created_at DESC;
