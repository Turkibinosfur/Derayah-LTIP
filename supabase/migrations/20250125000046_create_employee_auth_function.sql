/*
  Create Server-Side Function for Employee Auth User Creation
  
  Problem: Client-side auth user creation fails because admin.createUser() requires server-side execution
  Solution: Create a server-side function that can be called from the client to create auth users
  
  This function will:
  1. Create Supabase auth users for employees
  2. Link employee records with auth user IDs
  3. Handle duplicate user scenarios
*/

-- Create function to create auth user for employee
CREATE OR REPLACE FUNCTION create_employee_auth_user(
  p_employee_id uuid,
  p_email text,
  p_password text,
  p_first_name text,
  p_last_name text,
  p_portal_username text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_auth_user_id uuid;
  v_result jsonb;
BEGIN
  -- Check if employee exists
  IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_employee_id) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Employee not found'
    );
  END IF;
  
  -- Check if auth user already exists for this email
  SELECT id INTO v_auth_user_id 
  FROM auth.users 
  WHERE email = p_email;
  
  IF v_auth_user_id IS NOT NULL THEN
    -- Update employee record with existing auth user ID
    UPDATE employees 
    SET user_id = v_auth_user_id,
        portal_access_enabled = true,
        portal_username = p_portal_username,
        portal_password = p_password
    WHERE id = p_employee_id;
    
    RETURN jsonb_build_object(
      'success', true,
      'message', 'Auth user already exists, linked to employee',
      'user_id', v_auth_user_id
    );
  END IF;
  
  -- Create new auth user
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    last_sign_in_at,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    p_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider": "email", "providers": ["email"]}',
    jsonb_build_object(
      'first_name', p_first_name,
      'last_name', p_last_name,
      'employee_id', p_employee_id,
      'portal_username', p_portal_username
    ),
    false,
    null,
    '',
    '',
    ''
  ) RETURNING id INTO v_auth_user_id;
  
  -- Update employee record with new auth user ID
  UPDATE employees 
  SET user_id = v_auth_user_id,
      portal_access_enabled = true,
      portal_username = p_portal_username,
      portal_password = p_password
  WHERE id = p_employee_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Auth user created successfully',
    'user_id', v_auth_user_id
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_employee_auth_user TO authenticated;

-- Create a simpler function that just links existing auth users
CREATE OR REPLACE FUNCTION link_employee_to_auth_user(
  p_employee_id uuid,
  p_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_auth_user_id uuid;
BEGIN
  -- Find auth user by email
  SELECT id INTO v_auth_user_id 
  FROM auth.users 
  WHERE email = p_email;
  
  IF v_auth_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'No auth user found with this email'
    );
  END IF;
  
  -- Update employee record
  UPDATE employees 
  SET user_id = v_auth_user_id,
      portal_access_enabled = true
  WHERE id = p_employee_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Employee linked to existing auth user',
    'user_id', v_auth_user_id
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION link_employee_to_auth_user TO authenticated;
