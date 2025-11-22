-- Update Employees Component
-- This script provides the SQL functions needed for the frontend to automatically create auth users

-- 1. Create function to enable portal access and create auth user
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

-- 2. Create function to disable portal access
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

-- 3. Create function to check portal access status
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

-- 4. Test the functions
SELECT 
  '=== TESTING ENABLE PORTAL ACCESS ===' as step,
  enable_employee_portal_access(
    (SELECT id FROM employees WHERE email = 'test3@test.com' LIMIT 1),
    'test3',
    'Employee123!'
  );

-- 5. Test status check
SELECT 
  '=== TESTING STATUS CHECK ===' as step,
  check_employee_portal_status(
    (SELECT id FROM employees WHERE email = 'test3@test.com' LIMIT 1)
  );

-- 6. Final verification
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
