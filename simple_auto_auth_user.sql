-- Simple Auto Auth User Creation
-- This script provides a simpler approach to automatically create auth users

-- 1. Create a simple function to create auth user
CREATE OR REPLACE FUNCTION create_employee_auth_user_simple(
  p_employee_id uuid,
  p_email text,
  p_password text DEFAULT 'Employee123!'
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_employee_record employees%ROWTYPE;
  v_auth_user_id uuid;
  v_result json;
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
  WHERE email = p_email;
  
  IF v_auth_user_id IS NOT NULL THEN
    -- Link existing auth user to employee
    UPDATE employees SET
      user_id = v_auth_user_id,
      updated_at = now()
    WHERE id = p_employee_id;
    
    RETURN json_build_object(
      'success', true,
      'message', 'Auth user already exists and linked',
      'employee_id', p_employee_id,
      'auth_user_id', v_auth_user_id,
      'email', p_email
    );
  END IF;
  
  -- For now, return instructions for manual creation
  -- In a production environment, you would use Supabase Admin API
  RETURN json_build_object(
    'success', false,
    'message', 'Auth user creation requires manual intervention',
    'instructions', json_build_object(
      'step1', 'Go to Supabase Dashboard > Authentication > Users',
      'step2', 'Click "Add user"',
      'step3', 'Email: ' || p_email,
      'step4', 'Password: ' || p_password,
      'step5', 'Set Email Confirm to true',
      'step6', 'Click "Create user"',
      'step7', 'Run link_auth_users.sql to link the user'
    ),
    'employee_id', p_employee_id,
    'email', p_email,
    'password', p_password
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

-- 2. Test the function
SELECT 
  '=== TESTING FUNCTION ===' as step,
  create_employee_auth_user_simple(
    (SELECT id FROM employees WHERE email = 'test3@test.com' LIMIT 1),
    'test3@test.com',
    'Employee123!'
  );

-- 3. Create a function to link existing auth users
CREATE OR REPLACE FUNCTION link_employee_to_auth_user(
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

-- 4. Test the linking function
SELECT 
  '=== TESTING LINKING FUNCTION ===' as step,
  link_employee_to_auth_user(
    (SELECT id FROM employees WHERE email = 'test3@test.com' LIMIT 1),
    (SELECT id FROM auth.users WHERE email = 'test3@test.com' LIMIT 1)
  );

-- 5. Create a function to get all employees needing auth users
CREATE OR REPLACE FUNCTION get_employees_needing_auth_users()
RETURNS TABLE(
  employee_id uuid,
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

-- 6. Test the function
SELECT 
  '=== EMPLOYEES NEEDING AUTH USERS ===' as step,
  *
FROM get_employees_needing_auth_users();

-- 7. Final verification
SELECT 
  '=== FINAL VERIFICATION ===' as step,
  e.id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id,
  e.portal_access_enabled,
  u.email as auth_email,
  u.email_confirmed_at
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
WHERE e.portal_access_enabled = true
ORDER BY e.created_at DESC;
