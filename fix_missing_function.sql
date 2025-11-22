-- Fix Missing Function
-- Create the create_employee_auth_user_auto function that the frontend needs

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
      'email', p_email,
      'can_login', true
    );
  ELSE
    -- Auth user doesn't exist, enable portal access but provide instructions
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
      'email', p_email,
      'password', p_portal_password,
      'portal_username', p_portal_username,
      'instructions', json_build_object(
        'step1', 'Go to Supabase Dashboard > Authentication > Users',
        'step2', 'Click "Add user"',
        'step3', 'Email: ' || p_email,
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
