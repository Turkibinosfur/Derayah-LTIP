-- Fix Function Return Types
-- This script fixes the return type mismatch in the function

-- 1. Drop the problematic function
DROP FUNCTION IF EXISTS get_employees_with_portal_status_v2();

-- 2. Create the function with correct return types
CREATE OR REPLACE FUNCTION get_employees_with_portal_status_v2()
RETURNS TABLE(
  employee_id uuid,
  first_name varchar(255),
  last_name varchar(255),
  email varchar(255),
  portal_access_enabled boolean,
  portal_username varchar(255),
  user_id uuid,
  auth_user_exists boolean,
  auth_email varchar(255),
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

-- 3. Test the function
SELECT 
  '=== TESTING FUNCTION ===' as step,
  'Function created successfully' as status;

-- 4. Test the function with actual data
SELECT 
  '=== EMPLOYEES WITH PORTAL STATUS ===' as step,
  *
FROM get_employees_with_portal_status_v2();

-- 5. Alternative approach - create a simpler function that returns JSON
CREATE OR REPLACE FUNCTION get_employees_portal_status_json()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result json;
BEGIN
  SELECT json_agg(
    json_build_object(
      'employee_id', e.id,
      'first_name', e.first_name_en,
      'last_name', e.last_name_en,
      'email', e.email,
      'portal_access_enabled', e.portal_access_enabled,
      'portal_username', e.portal_username,
      'user_id', e.user_id,
      'auth_user_exists', u.id IS NOT NULL,
      'auth_email', u.email,
      'can_login', (e.portal_access_enabled = true AND e.user_id IS NOT NULL AND u.id IS NOT NULL)
    )
  ) INTO v_result
  FROM employees e
  LEFT JOIN auth.users u ON e.user_id = u.id
  ORDER BY e.created_at DESC;
  
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 6. Test the JSON function
SELECT 
  '=== TESTING JSON FUNCTION ===' as step,
  get_employees_portal_status_json();

-- 7. Create a function to get specific employee portal status
CREATE OR REPLACE FUNCTION get_employee_portal_status(
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
    'first_name', v_employee_record.first_name_en,
    'last_name', v_employee_record.last_name_en,
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

-- 8. Test the individual employee status function
SELECT 
  '=== TESTING INDIVIDUAL EMPLOYEE STATUS ===' as step,
  get_employee_portal_status(
    (SELECT id FROM employees WHERE email = 'test3@test.com' LIMIT 1)
  );

-- 9. Final verification
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
