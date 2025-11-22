-- Avoid Return Type Issues
-- This script creates functions that avoid return type issues entirely

-- 1. Drop all problematic functions
DROP FUNCTION IF EXISTS get_employees_with_portal_status_v2();
DROP FUNCTION IF EXISTS get_employees_with_portal_status();
DROP FUNCTION IF EXISTS get_employees_portal_status_json();
DROP FUNCTION IF EXISTS get_employee_portal_status(uuid);

-- 2. Create a simple function that returns a table with proper types
CREATE OR REPLACE FUNCTION get_employees_portal_info()
RETURNS TABLE(
  id uuid,
  first_name text,
  last_name text,
  email text,
  portal_access_enabled boolean,
  portal_username text,
  user_id uuid,
  auth_user_exists boolean,
  auth_email text,
  can_login boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.first_name_en,
    e.last_name_en,
    e.email,
    e.portal_access_enabled,
    e.portal_username,
    e.user_id,
    (u.id IS NOT NULL) as auth_user_exists,
    u.email as auth_email,
    (e.portal_access_enabled = true AND e.user_id IS NOT NULL AND u.id IS NOT NULL) as can_login
  FROM employees e
  LEFT JOIN auth.users u ON e.user_id = u.id
  ORDER BY e.created_at DESC;
END;
$$;

-- 3. Test the function
SELECT 
  '=== TESTING EMPLOYEES PORTAL INFO ===' as step,
  *
FROM get_employees_portal_info();

-- 4. Create a function to get employees with portal access only
CREATE OR REPLACE FUNCTION get_employees_with_portal_access()
RETURNS TABLE(
  id uuid,
  first_name text,
  last_name text,
  email text,
  portal_username text,
  user_id uuid,
  auth_user_exists boolean,
  auth_email text,
  can_login boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.first_name_en,
    e.last_name_en,
    e.email,
    e.portal_username,
    e.user_id,
    (u.id IS NOT NULL) as auth_user_exists,
    u.email as auth_email,
    (e.user_id IS NOT NULL AND u.id IS NOT NULL) as can_login
  FROM employees e
  LEFT JOIN auth.users u ON e.user_id = u.id
  WHERE e.portal_access_enabled = true
  ORDER BY e.created_at DESC;
END;
$$;

-- 5. Test the portal access function
SELECT 
  '=== TESTING EMPLOYEES WITH PORTAL ACCESS ===' as step,
  *
FROM get_employees_with_portal_access();

-- 6. Create a function to get employees without auth users
CREATE OR REPLACE FUNCTION get_employees_without_auth_users()
RETURNS TABLE(
  id uuid,
  first_name text,
  last_name text,
  email text,
  portal_username text,
  portal_password text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.first_name_en,
    e.last_name_en,
    e.email,
    e.portal_username,
    e.portal_password
  FROM employees e
  WHERE e.portal_access_enabled = true 
    AND e.user_id IS NULL
  ORDER BY e.created_at DESC;
END;
$$;

-- 7. Test the function
SELECT 
  '=== TESTING EMPLOYEES WITHOUT AUTH USERS ===' as step,
  *
FROM get_employees_without_auth_users();

-- 8. Create a function to enable portal access
CREATE OR REPLACE FUNCTION enable_employee_portal_access_final(
  p_employee_id uuid,
  p_portal_username text,
  p_portal_password text DEFAULT 'Employee123!'
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_employee_record employees%ROWTYPE;
  v_auth_user_id uuid;
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
  
  -- Check if auth user already exists
  SELECT id INTO v_auth_user_id
  FROM auth.users
  WHERE email = v_employee_record.email;
  
  IF v_auth_user_id IS NOT NULL THEN
    -- Auth user exists, link it
    UPDATE employees SET
      user_id = v_auth_user_id,
      portal_access_enabled = true,
      portal_username = p_portal_username,
      portal_password = p_portal_password,
      updated_at = now()
    WHERE id = p_employee_id;
    
    RETURN json_build_object(
      'success', true,
      'message', 'Portal access enabled and linked to existing auth user',
      'employee_id', p_employee_id,
      'auth_user_id', v_auth_user_id,
      'email', v_employee_record.email,
      'can_login', true
    );
  ELSE
    -- Auth user doesn't exist, need manual creation
    UPDATE employees SET
      portal_access_enabled = true,
      portal_username = p_portal_username,
      portal_password = p_portal_password,
      updated_at = now()
    WHERE id = p_employee_id;
    
    RETURN json_build_object(
      'success', false,
      'message', 'Portal access enabled but auth user needs manual creation',
      'employee_id', p_employee_id,
      'email', v_employee_record.email,
      'password', p_portal_password,
      'portal_username', p_portal_username,
      'instructions', json_build_object(
        'step1', 'Go to Supabase Dashboard > Authentication > Users',
        'step2', 'Click "Add user"',
        'step3', 'Email: ' || v_employee_record.email,
        'step4', 'Password: ' || p_portal_password,
        'step5', 'Set Email Confirm to true',
        'step6', 'Click "Create user"'
      ),
      'can_login', false
    );
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Error: ' || SQLERRM,
      'employee_id', p_employee_id
    );
END;
$$;

-- 9. Test the enable portal access function
SELECT 
  '=== TESTING ENABLE PORTAL ACCESS ===' as step,
  enable_employee_portal_access_final(
    (SELECT id FROM employees WHERE email = 'test3@test.com' LIMIT 1),
    'test3',
    'Employee123!'
  );

-- 10. Final verification
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
