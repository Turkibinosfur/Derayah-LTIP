-- Fix Test6 Login Immediately
-- This script provides immediate solution for test6@test.com login issue

-- 1. Check current state of test6@test.com
SELECT 
  '=== TEST6@TEST.COM CURRENT STATE ===' as step,
  e.id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.portal_access_enabled,
  e.portal_username,
  e.portal_password,
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
WHERE e.email = 'test6@test.com';

-- 2. Check if auth user exists for test6@test.com
SELECT 
  '=== CHECKING AUTH USER FOR TEST6@TEST.COM ===' as step,
  id,
  email,
  email_confirmed_at,
  created_at
FROM auth.users 
WHERE email = 'test6@test.com';

-- 3. Create a function to link employee to auth user by email
CREATE OR REPLACE FUNCTION link_employee_to_auth_by_email(
  p_employee_email text
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
  WHERE email = p_employee_email;
  
  IF v_employee_record IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Employee record not found',
      'email', p_employee_email
    );
  END IF;
  
  -- Get auth user record
  SELECT * INTO v_auth_user_record
  FROM auth.users
  WHERE email = p_employee_email;
  
  IF v_auth_user_record IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Auth user not found for email: ' || p_employee_email,
      'instructions', json_build_object(
        'step1', 'Go to Supabase Dashboard > Authentication > Users',
        'step2', 'Click "Add user"',
        'step3', 'Email: ' || p_employee_email,
        'step4', 'Password: ' || COALESCE(v_employee_record.portal_password, 'Employee123!'),
        'step5', 'Set Email Confirm to true',
        'step6', 'Click "Create user"',
        'step7', 'Run this function again'
      )
    );
  END IF;
  
  -- Link employee to auth user
  UPDATE employees SET
    user_id = v_auth_user_record.id,
    updated_at = now()
  WHERE id = v_employee_record.id;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Employee linked to auth user successfully',
    'employee_id', v_employee_record.id,
    'auth_user_id', v_auth_user_record.id,
    'employee_email', v_employee_record.email,
    'auth_email', v_auth_user_record.email
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Error: ' || SQLERRM,
      'email', p_employee_email
    );
END;
$$;

-- 4. Test the linking function
SELECT 
  '=== TESTING LINKING FUNCTION ===' as step,
  link_employee_to_auth_by_email('test6@test.com');

-- 5. Create a function to test employee login
CREATE OR REPLACE FUNCTION test_employee_login(
  p_email text
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
  WHERE email = p_email;
  
  IF v_employee_record IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Employee record not found',
      'email', p_email
    );
  END IF;
  
  -- Get auth user record
  SELECT * INTO v_auth_user_record
  FROM auth.users
  WHERE email = p_email;
  
  IF v_auth_user_record IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Auth user not found - needs manual creation',
      'email', p_email,
      'instructions', json_build_object(
        'step1', 'Go to Supabase Dashboard > Authentication > Users',
        'step2', 'Click "Add user"',
        'step3', 'Email: ' || p_email,
        'step4', 'Password: ' || COALESCE(v_employee_record.portal_password, 'Employee123!'),
        'step5', 'Set Email Confirm to true',
        'step6', 'Click "Create user"'
      )
    );
  END IF;
  
  -- Check if employee is linked to auth user
  IF v_employee_record.user_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Employee not linked to auth user',
      'email', p_email,
      'employee_id', v_employee_record.id,
      'auth_user_id', v_auth_user_record.id,
      'action_required', 'Run link_employee_to_auth_by_email function'
    );
  END IF;
  
  IF v_employee_record.user_id != v_auth_user_record.id THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Employee linked to wrong auth user',
      'email', p_email,
      'employee_user_id', v_employee_record.user_id,
      'auth_user_id', v_auth_user_record.id,
      'action_required', 'Run link_employee_to_auth_by_email function'
    );
  END IF;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Employee login should work',
    'email', p_email,
    'employee_id', v_employee_record.id,
    'auth_user_id', v_auth_user_record.id,
    'portal_access_enabled', v_employee_record.portal_access_enabled,
    'can_login', true
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Error: ' || SQLERRM,
      'email', p_email
    );
END;
$$;

-- 6. Test employee login
SELECT 
  '=== TESTING EMPLOYEE LOGIN ===' as step,
  test_employee_login('test6@test.com');

-- 7. Final verification
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
WHERE e.email = 'test6@test.com';
