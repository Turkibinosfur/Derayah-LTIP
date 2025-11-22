-- Fix JSON Agg Order By
-- This script fixes the ORDER BY clause issue in JSON aggregation functions

-- 1. Drop the problematic functions
DROP FUNCTION IF EXISTS get_employees_portal_status_simple();
DROP FUNCTION IF EXISTS get_employees_with_portal_access_only();
DROP FUNCTION IF EXISTS get_all_employees_portal_status();

-- 2. Create fixed JSON functions without ORDER BY in aggregation
CREATE OR REPLACE FUNCTION get_employees_portal_status_simple()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result json;
BEGIN
  SELECT json_agg(
    json_build_object(
      'employee_id', e.id,
      'first_name', e.first_name_en,
      'last_name', e.last_name_en,
      'email', e.email,
      'portal_access_enabled', e.portal_access_enabled,
      'portal_username', e.portal_username,
      'user_id', e.user_id,
      'auth_user_exists', u.id IS NOT NULL,
      'auth_email', u.email,
      'auth_email_confirmed', u.email_confirmed_at IS NOT NULL,
      'can_login', (e.portal_access_enabled = true AND e.user_id IS NOT NULL AND u.id IS NOT NULL)
    )
  ) INTO v_result
  FROM employees e
  LEFT JOIN auth.users u ON e.user_id = u.id;
  
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 3. Create function to get employees with portal access only
CREATE OR REPLACE FUNCTION get_employees_with_portal_access_only()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result json;
BEGIN
  SELECT json_agg(
    json_build_object(
      'employee_id', e.id,
      'first_name', e.first_name_en,
      'last_name', e.last_name_en,
      'email', e.email,
      'portal_username', e.portal_username,
      'user_id', e.user_id,
      'auth_user_exists', u.id IS NOT NULL,
      'auth_email', u.email,
      'can_login', (e.user_id IS NOT NULL AND u.id IS NOT NULL)
    )
  ) INTO v_result
  FROM employees e
  LEFT JOIN auth.users u ON e.user_id = u.id
  WHERE e.portal_access_enabled = true;
  
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 4. Create function to get all employees with portal status
CREATE OR REPLACE FUNCTION get_all_employees_portal_status()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result json;
BEGIN
  SELECT json_agg(
    json_build_object(
      'employee_id', e.id,
      'first_name', e.first_name_en,
      'last_name', e.last_name_en,
      'email', e.email,
      'portal_access_enabled', e.portal_access_enabled,
      'portal_username', e.portal_username,
      'user_id', e.user_id,
      'auth_user_exists', u.id IS NOT NULL,
      'auth_email', u.email,
      'auth_email_confirmed', u.email_confirmed_at IS NOT NULL,
      'can_login', (e.portal_access_enabled = true AND e.user_id IS NOT NULL AND u.id IS NOT NULL)
    )
  ) INTO v_result
  FROM employees e
  LEFT JOIN auth.users u ON e.user_id = u.id;
  
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 5. Create function to get employees without auth users
CREATE OR REPLACE FUNCTION get_employees_without_auth_users()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result json;
BEGIN
  SELECT json_agg(
    json_build_object(
      'employee_id', e.id,
      'first_name', e.first_name_en,
      'last_name', e.last_name_en,
      'email', e.email,
      'portal_username', e.portal_username,
      'portal_password', e.portal_password,
      'instructions', json_build_object(
        'step1', 'Go to Supabase Dashboard > Authentication > Users',
        'step2', 'Click "Add user"',
        'step3', 'Email: ' || e.email,
        'step4', 'Password: ' || COALESCE(e.portal_password, 'Employee123!'),
        'step5', 'Set Email Confirm to true',
        'step6', 'Click "Create user"'
      )
    )
  ) INTO v_result
  FROM employees e
  WHERE e.portal_access_enabled = true 
    AND e.user_id IS NULL;
  
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 6. Test all functions
SELECT 
  '=== TESTING SIMPLE PORTAL STATUS ===' as step,
  get_employees_portal_status_simple();

SELECT 
  '=== TESTING PORTAL ACCESS ONLY ===' as step,
  get_employees_with_portal_access_only();

SELECT 
  '=== TESTING ALL EMPLOYEES STATUS ===' as step,
  get_all_employees_portal_status();

SELECT 
  '=== TESTING EMPLOYEES WITHOUT AUTH USERS ===' as step,
  get_employees_without_auth_users();

-- 7. Create a function to enable portal access
CREATE OR REPLACE FUNCTION enable_portal_access_simple()
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
  WHERE email = 'test3@test.com';
  
  IF v_employee_record IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Employee record not found'
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
      portal_username = 'test3',
      portal_password = 'Employee123!',
      updated_at = now()
    WHERE id = v_employee_record.id;
    
    RETURN json_build_object(
      'success', true,
      'message', 'Portal access enabled and linked to existing auth user',
      'employee_id', v_employee_record.id,
      'auth_user_id', v_auth_user_id,
      'email', v_employee_record.email,
      'can_login', true
    );
  ELSE
    -- Auth user doesn't exist, need manual creation
    UPDATE employees SET
      portal_access_enabled = true,
      portal_username = 'test3',
      portal_password = 'Employee123!',
      updated_at = now()
    WHERE id = v_employee_record.id;
    
    RETURN json_build_object(
      'success', false,
      'message', 'Portal access enabled but auth user needs manual creation',
      'employee_id', v_employee_record.id,
      'email', v_employee_record.email,
      'password', 'Employee123!',
      'portal_username', 'test3',
      'instructions', json_build_object(
        'step1', 'Go to Supabase Dashboard > Authentication > Users',
        'step2', 'Click "Add user"',
        'step3', 'Email: ' || v_employee_record.email,
        'step4', 'Password: Employee123!',
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
      'message', 'Error: ' || SQLERRM
    );
END;
$$;

-- 8. Test the enable portal access function
SELECT 
  '=== TESTING ENABLE PORTAL ACCESS ===' as step,
  enable_portal_access_simple();

-- 9. Final verification
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
