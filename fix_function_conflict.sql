-- Fix Function Conflict
-- This script drops existing functions and recreates them with the correct signatures

-- 1. Drop existing functions that might conflict
DROP FUNCTION IF EXISTS create_employee_auth_user(uuid, text, text);
DROP FUNCTION IF EXISTS create_employee_auth_user_simple(uuid, text, text);
DROP FUNCTION IF EXISTS link_employee_to_auth_user(uuid, uuid);
DROP FUNCTION IF EXISTS enable_employee_portal_access(uuid, text, text);
DROP FUNCTION IF EXISTS disable_employee_portal_access(uuid);
DROP FUNCTION IF EXISTS check_employee_portal_status(uuid);
DROP FUNCTION IF EXISTS manage_employee_portal_access(uuid, boolean, text, text);
DROP FUNCTION IF EXISTS get_employees_with_portal_status();
DROP FUNCTION IF EXISTS auto_link_existing_auth_users();
DROP FUNCTION IF EXISTS get_employees_needing_auth_users();

-- 2. Drop trigger and trigger function
DROP TRIGGER IF EXISTS trigger_auto_create_auth_user ON employees;
DROP FUNCTION IF EXISTS trigger_create_employee_auth_user();

-- 3. Now create the functions with correct signatures
CREATE OR REPLACE FUNCTION create_employee_auth_user(
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

-- 4. Create function to link existing auth users
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

-- 5. Create function to enable portal access
CREATE OR REPLACE FUNCTION enable_employee_portal_access(
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
    -- Auth user exists, just link it
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
      'email', v_employee_record.email
    );
  END IF;
  
  -- Auth user doesn't exist, need manual creation
  -- Update employee record with portal access
  UPDATE employees SET
    portal_access_enabled = true,
    portal_username = p_portal_username,
    portal_password = p_portal_password,
    updated_at = now()
  WHERE id = p_employee_id;
  
  RETURN json_build_object(
    'success', false,
    'message', 'Portal access enabled but auth user needs to be created manually',
    'instructions', json_build_object(
      'step1', 'Go to Supabase Dashboard > Authentication > Users',
      'step2', 'Click "Add user"',
      'step3', 'Email: ' || v_employee_record.email,
      'step4', 'Password: ' || p_portal_password,
      'step5', 'Set Email Confirm to true',
      'step6', 'Click "Create user"',
      'step7', 'Run link_auth_users.sql to link the user'
    ),
    'employee_id', p_employee_id,
    'email', v_employee_record.email,
    'password', p_portal_password,
    'portal_username', p_portal_username
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

-- 6. Create function to disable portal access
CREATE OR REPLACE FUNCTION disable_employee_portal_access(
  p_employee_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_employee_record employees%ROWTYPE;
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
  
  -- Disable portal access
  UPDATE employees SET
    portal_access_enabled = false,
    portal_username = NULL,
    portal_password = NULL,
    user_id = NULL,
    updated_at = now()
  WHERE id = p_employee_id;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Portal access disabled successfully',
    'employee_id', p_employee_id,
    'email', v_employee_record.email
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

-- 7. Create function to check portal status
CREATE OR REPLACE FUNCTION check_employee_portal_status(
  p_employee_id uuid
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
  
  -- Get auth user record if linked
  IF v_employee_record.user_id IS NOT NULL THEN
    SELECT * INTO v_auth_user_record
    FROM auth.users
    WHERE id = v_employee_record.user_id;
  END IF;
  
  RETURN json_build_object(
    'success', true,
    'employee_id', p_employee_id,
    'email', v_employee_record.email,
    'portal_access_enabled', v_employee_record.portal_access_enabled,
    'portal_username', v_employee_record.portal_username,
    'user_id', v_employee_record.user_id,
    'auth_user_exists', v_auth_user_record.id IS NOT NULL,
    'auth_email', v_auth_user_record.email,
    'auth_email_confirmed', v_auth_user_record.email_confirmed_at IS NOT NULL,
    'can_login', v_employee_record.portal_access_enabled = true 
      AND v_employee_record.user_id IS NOT NULL 
      AND v_auth_user_record.id IS NOT NULL
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

-- 8. Test the functions
SELECT 
  '=== TESTING FUNCTIONS ===' as step,
  'Functions created successfully' as status;

-- 9. Test with test3@test.com
SELECT 
  '=== TESTING WITH TEST3@TEST.COM ===' as step,
  enable_employee_portal_access(
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
  u.email_confirmed_at
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
WHERE e.portal_access_enabled = true
ORDER BY e.created_at DESC;
