-- Simple Auto Auth Fixed
-- This script creates new functions with unique names to avoid conflicts

-- 1. Create function to manage employee portal access
CREATE OR REPLACE FUNCTION manage_employee_portal_access_v2(
  p_employee_id uuid,
  p_enable boolean,
  p_portal_username text DEFAULT NULL,
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
  
  IF p_enable THEN
    -- Enable portal access
    -- Check if auth user already exists
    SELECT id INTO v_auth_user_id
    FROM auth.users
    WHERE email = v_employee_record.email;
    
    IF v_auth_user_id IS NOT NULL THEN
      -- Auth user exists, link it
      UPDATE employees SET
        user_id = v_auth_user_id,
        portal_access_enabled = true,
        portal_username = COALESCE(p_portal_username, v_employee_record.portal_username),
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
        portal_username = COALESCE(p_portal_username, v_employee_record.portal_username),
        portal_password = p_portal_password,
        updated_at = now()
      WHERE id = p_employee_id;
      
      RETURN json_build_object(
        'success', false,
        'message', 'Portal access enabled but auth user needs manual creation',
        'employee_id', p_employee_id,
        'email', v_employee_record.email,
        'password', p_portal_password,
        'portal_username', COALESCE(p_portal_username, v_employee_record.portal_username),
        'instructions', json_build_object(
          'step1', 'Go to Supabase Dashboard > Authentication > Users',
          'step2', 'Click "Add user"',
          'step3', 'Email: ' || v_employee_record.email,
          'step4', 'Password: ' || p_portal_password,
          'step5', 'Set Email Confirm to true',
          'step6', 'Click "Create user"',
          'step7', 'Run link_auth_users.sql to link the user'
        ),
        'can_login', false
      );
    END IF;
  ELSE
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
      'email', v_employee_record.email,
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

-- 2. Create function to get all employees with portal status
CREATE OR REPLACE FUNCTION get_employees_with_portal_status_v2()
RETURNS TABLE(
  employee_id uuid,
  first_name text,
  last_name text,
  email text,
  portal_access_enabled boolean,
  portal_username text,
  user_id uuid,
  auth_user_exists boolean,
  auth_email text,
  can_login boolean
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
    e.portal_access_enabled,
    e.portal_username,
    e.user_id,
    (u.id IS NOT NULL) as auth_user_exists,
    u.email as auth_email,
    (e.portal_access_enabled = true AND e.user_id IS NOT NULL AND u.id IS NOT NULL) as can_login
  FROM employees e
  LEFT JOIN auth.users u ON e.user_id = u.id
  ORDER BY e.created_at DESC;
END;
$$;

-- 3. Create function to automatically link existing auth users
CREATE OR REPLACE FUNCTION auto_link_existing_auth_users_v2()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  rec RECORD;
  v_linked_count integer := 0;
  v_failed_count integer := 0;
  v_result json;
BEGIN
  -- Find employees with portal access but no linked auth user
  FOR rec IN 
    SELECT e.id, e.email, e.first_name_en, e.last_name_en
    FROM employees e
    WHERE e.portal_access_enabled = true 
      AND e.user_id IS NULL
      AND EXISTS (
        SELECT 1 FROM auth.users u WHERE u.email = e.email
      )
  LOOP
    -- Link employee to existing auth user
    UPDATE employees SET
      user_id = (SELECT id FROM auth.users WHERE email = rec.email),
      updated_at = now()
    WHERE id = rec.id;
    
    v_linked_count := v_linked_count + 1;
  END LOOP;
  
  -- Find employees with portal access but no auth user exists
  FOR rec IN 
    SELECT e.id, e.email, e.first_name_en, e.last_name_en
    FROM employees e
    WHERE e.portal_access_enabled = true 
      AND e.user_id IS NULL
      AND NOT EXISTS (
        SELECT 1 FROM auth.users u WHERE u.email = e.email
      )
  LOOP
    v_failed_count := v_failed_count + 1;
  END LOOP;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Auto-linking completed',
    'linked_count', v_linked_count,
    'failed_count', v_failed_count,
    'total_processed', v_linked_count + v_failed_count
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Error: ' || SQLERRM
    );
END;
$$;

-- 4. Test the functions
SELECT 
  '=== TESTING PORTAL ACCESS MANAGEMENT ===' as step,
  manage_employee_portal_access_v2(
    (SELECT id FROM employees WHERE email = 'test3@test.com' LIMIT 1),
    true,
    'test3',
    'Employee123!'
  );

-- 5. Test auto-linking
SELECT 
  '=== TESTING AUTO-LINKING ===' as step,
  auto_link_existing_auth_users_v2();

-- 6. Get all employees with portal status
SELECT 
  '=== EMPLOYEES WITH PORTAL STATUS ===' as step,
  *
FROM get_employees_with_portal_status_v2();

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
WHERE e.portal_access_enabled = true
ORDER BY e.created_at DESC;
