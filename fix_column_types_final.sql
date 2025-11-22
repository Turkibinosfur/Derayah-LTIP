-- Fix Column Types Final
-- This script fixes the column type mismatch by using the correct types

-- 1. Drop the problematic function
DROP FUNCTION IF EXISTS get_employees_with_portal_status_v2();

-- 2. Check the actual column types first
SELECT 
  '=== CHECKING COLUMN TYPES ===' as step,
  column_name,
  data_type,
  character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'employees' 
  AND column_name IN ('first_name_en', 'last_name_en', 'email', 'portal_username')
ORDER BY column_name;

-- 3. Create the function with correct return types based on actual schema
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
    e.first_name_en::text,
    e.last_name_en::text,
    e.email::text,
    e.portal_access_enabled,
    e.portal_username::text,
    e.user_id,
    (u.id IS NOT NULL) as auth_user_exists,
    u.email::text as auth_email,
    (e.portal_access_enabled = true AND e.user_id IS NOT NULL AND u.id IS NOT NULL) as can_login
  FROM employees e
  LEFT JOIN auth.users u ON e.user_id = u.id
  ORDER BY e.created_at DESC;
END;
$$;

-- 4. Test the function
SELECT 
  '=== TESTING FUNCTION ===' as step,
  'Function created successfully' as status;

-- 5. Test the function with actual data
SELECT 
  '=== EMPLOYEES WITH PORTAL STATUS ===' as step,
  *
FROM get_employees_with_portal_status_v2();

-- 6. Alternative approach - create a view instead of a function
CREATE OR REPLACE VIEW employees_portal_status AS
SELECT 
  e.id as employee_id,
  e.first_name_en as first_name,
  e.last_name_en as last_name,
  e.email,
  e.portal_access_enabled,
  e.portal_username,
  e.user_id,
  (u.id IS NOT NULL) as auth_user_exists,
  u.email as auth_email,
  u.email_confirmed_at as auth_email_confirmed,
  (e.portal_access_enabled = true AND e.user_id IS NOT NULL AND u.id IS NOT NULL) as can_login
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
ORDER BY e.created_at DESC;

-- 7. Test the view
SELECT 
  '=== TESTING VIEW ===' as step,
  *
FROM employees_portal_status;

-- 8. Create a simple function that returns JSON to avoid type issues
CREATE OR REPLACE FUNCTION get_employees_portal_status_simple()
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
      'auth_email_confirmed', u.email_confirmed_at IS NOT NULL,
      'can_login', (e.portal_access_enabled = true AND e.user_id IS NOT NULL AND u.id IS NOT NULL)
    )
  ) INTO v_result
  FROM employees e
  LEFT JOIN auth.users u ON e.user_id = u.id
  ORDER BY e.created_at DESC;
  
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 9. Test the simple JSON function
SELECT 
  '=== TESTING SIMPLE JSON FUNCTION ===' as step,
  get_employees_portal_status_simple();

-- 10. Create a function to get employees with portal access only
CREATE OR REPLACE FUNCTION get_employees_with_portal_access_only()
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
      'portal_username', e.portal_username,
      'user_id', e.user_id,
      'auth_user_exists', u.id IS NOT NULL,
      'auth_email', u.email,
      'can_login', (e.user_id IS NOT NULL AND u.id IS NOT NULL)
    )
  ) INTO v_result
  FROM employees e
  LEFT JOIN auth.users u ON e.user_id = u.id
  WHERE e.portal_access_enabled = true
  ORDER BY e.created_at DESC;
  
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 11. Test the portal access only function
SELECT 
  '=== TESTING PORTAL ACCESS ONLY ===' as step,
  get_employees_with_portal_access_only();

-- 12. Final verification
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
