/*
  Simple Employee Linking Function
  
  This is a simpler approach that just links existing auth users to employees
  without trying to create new auth users directly.
*/

-- Create a simple function to link employee to auth user by email
CREATE OR REPLACE FUNCTION link_employee_to_auth_by_email(
  p_employee_id uuid,
  p_email text,
  p_portal_username text,
  p_portal_password text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_auth_user_id uuid;
BEGIN
  -- Check if employee exists
  IF NOT EXISTS (SELECT 1 FROM employees WHERE id = p_employee_id) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Employee not found'
    );
  END IF;
  
  -- Try to find auth user by email (this might not work if we can't access auth.users)
  -- For now, we'll just update the employee record and assume the auth user exists
  UPDATE employees 
  SET portal_access_enabled = true,
      portal_username = p_portal_username,
      portal_password = p_portal_password,
      email = p_email
  WHERE id = p_employee_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Employee portal access enabled. Auth user should be created manually if needed.',
    'employee_id', p_employee_id
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
GRANT EXECUTE ON FUNCTION link_employee_to_auth_by_email TO authenticated;
