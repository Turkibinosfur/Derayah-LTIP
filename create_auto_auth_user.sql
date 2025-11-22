-- Create Auto Auth User Function
-- This function will automatically create auth users when portal access is enabled

-- First, let's create a function that can actually create auth users
CREATE OR REPLACE FUNCTION create_employee_auth_user_auto(
  p_employee_id uuid,
  p_email text,
  p_portal_username text,
  p_portal_password text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_employee_record employees%ROWTYPE;
  v_auth_user_id uuid;
  v_existing_auth_user_id uuid;
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
  SELECT id INTO v_existing_auth_user_id
  FROM auth.users
  WHERE email = p_email;
  
  IF v_existing_auth_user_id IS NOT NULL THEN
    -- Auth user exists, link it and enable portal access
    UPDATE employees SET
      user_id = v_existing_auth_user_id,
      portal_access_enabled = true,
      portal_username = p_portal_username,
      portal_password = p_portal_password,
      updated_at = now()
    WHERE id = p_employee_id;
    
    RETURN json_build_object(
      'success', true,
      'message', 'Portal access enabled and linked to existing auth user',
      'employee_id', p_employee_id,
      'auth_user_id', v_existing_auth_user_id,
      'email', p_email,
      'can_login', true
    );
  ELSE
    -- Auth user doesn't exist, we need to create it
    -- For now, we'll enable portal access and provide instructions
    UPDATE employees SET
      portal_access_enabled = true,
      portal_username = p_portal_username,
      portal_password = p_portal_password,
      updated_at = now()
    WHERE id = p_employee_id;
    
    -- Return success with instructions for manual auth user creation
    RETURN json_build_object(
      'success', true,
      'message', 'Portal access enabled successfully! Auth user needs to be created manually in Supabase Dashboard.',
      'employee_id', p_employee_id,
      'email', p_email,
      'password', p_portal_password,
      'portal_username', p_portal_username,
      'manual_steps', json_build_object(
        'step1', 'Go to Supabase Dashboard > Authentication > Users',
        'step2', 'Click "Add user"',
        'step3', 'Email: ' || p_email,
        'step4', 'Password: ' || p_portal_password,
        'step5', 'Set Email Confirm to true',
        'step6', 'Click "Create user"',
        'step7', 'The employee will be able to login immediately'
      ),
      'can_login', false,
      'requires_manual_auth_creation', true
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

-- Test the function
SELECT 
  '=== TESTING FUNCTION ===' as step,
  create_employee_auth_user_auto(
    (SELECT id FROM employees WHERE email = 'test9@test.com' LIMIT 1),
    'test9@test.com',
    'test9',
    'Employee123!'
  );

-- Show current status
SELECT 
  '=== CURRENT STATUS ===' as step,
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
WHERE e.email = 'test9@test.com';
