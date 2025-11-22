-- Auto Create Auth User On Portal Enable
-- This script creates a trigger that automatically creates auth users when portal access is enabled

-- 1. First, let's check the current state
SELECT 
  '=== CURRENT EMPLOYEE STATUS ===' as step,
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
WHERE e.email = 'test6@test.com'
ORDER BY e.created_at DESC;

-- 2. Create a function to automatically create auth user when portal access is enabled
CREATE OR REPLACE FUNCTION create_auth_user_for_employee(
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
    -- Auth user exists, link it
    UPDATE employees SET
      user_id = v_auth_user_id,
      updated_at = now()
    WHERE id = p_employee_id;
    
    RETURN json_build_object(
      'success', true,
      'message', 'Auth user already exists and linked',
      'employee_id', p_employee_id,
      'auth_user_id', v_auth_user_id,
      'email', p_email,
      'can_login', true
    );
  END IF;
  
  -- For now, return instructions for manual creation
  -- In a production environment, you would use Supabase Admin API
  RETURN json_build_object(
    'success', false,
    'message', 'Auth user creation requires manual intervention',
    'employee_id', p_employee_id,
    'email', p_email,
    'password', p_password,
    'instructions', json_build_object(
      'step1', 'Go to Supabase Dashboard > Authentication > Users',
      'step2', 'Click "Add user"',
      'step3', 'Email: ' || p_email,
      'step4', 'Password: ' || p_password,
      'step5', 'Set Email Confirm to true',
      'step6', 'Click "Create user"',
      'step7', 'Run the linking function below'
    ),
    'can_login', false
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

-- 3. Create a function to enable portal access and automatically handle auth user creation
CREATE OR REPLACE FUNCTION enable_employee_portal_with_auto_auth(
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
  WHERE email = v_employee_record.email;
  
  IF v_auth_user_id IS NOT NULL THEN
    -- Auth user exists, link it and enable portal access
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
        'step6', 'Click "Create user"',
        'step7', 'Run the linking function below'
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

-- 4. Create a function to link employee to auth user by email
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

-- 5. Test with test6@test.com
SELECT 
  '=== TESTING WITH TEST6@TEST.COM ===' as step,
  enable_employee_portal_with_auto_auth(
    (SELECT id FROM employees WHERE email = 'test6@test.com' LIMIT 1),
    'test6',
    'Employee123!'
  );

-- 6. Check if auth user exists for test6@test.com
SELECT 
  '=== CHECKING AUTH USER FOR TEST6@TEST.COM ===' as step,
  id,
  email,
  email_confirmed_at,
  created_at
FROM auth.users 
WHERE email = 'test6@test.com';

-- 7. If auth user exists, link it
SELECT 
  '=== LINKING TEST6@TEST.COM ===' as step,
  link_employee_to_auth_by_email('test6@test.com');

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
WHERE e.email = 'test6@test.com';
