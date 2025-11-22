-- Auto Auth User Creation SQL Only
-- This script creates SQL functions for automatically creating auth users when portal access is enabled

-- 1. Create a function to automatically create auth user for employee
CREATE OR REPLACE FUNCTION create_employee_auth_user_auto(
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
      'step7', 'Run link_auth_users.sql to link the user'
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

-- 2. Create a function to enable portal access and automatically create auth user
CREATE OR REPLACE FUNCTION enable_employee_portal_access_auto(
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
    -- Auth user exists, link it
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
        'step7', 'Run link_auth_users.sql to link the user'
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

-- 3. Create a function to automatically link existing auth users
CREATE OR REPLACE FUNCTION auto_link_existing_auth_users()
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

-- 4. Create a function to get all employees with portal status
CREATE OR REPLACE FUNCTION get_all_employees_portal_status()
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
  LEFT JOIN auth.users u ON e.user_id = u.id;
  
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 5. Create a function to get employees without auth users
CREATE OR REPLACE FUNCTION get_employees_without_auth_users()
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
      'portal_password', e.portal_password,
      'instructions', json_build_object(
        'step1', 'Go to Supabase Dashboard > Authentication > Users',
        'step2', 'Click "Add user"',
        'step3', 'Email: ' || e.email,
        'step4', 'Password: ' || COALESCE(e.portal_password, 'Employee123!'),
        'step5', 'Set Email Confirm to true',
        'step6', 'Click "Create user"'
      )
    )
  ) INTO v_result
  FROM employees e
  WHERE e.portal_access_enabled = true 
    AND e.user_id IS NULL;
  
  RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 6. Test the functions
SELECT 
  '=== TESTING AUTO AUTH USER CREATION ===' as step,
  create_employee_auth_user_auto(
    (SELECT id FROM employees WHERE email = 'test3@test.com' LIMIT 1),
    'test3@test.com',
    'Employee123!'
  );

-- 7. Test enable portal access
SELECT 
  '=== TESTING ENABLE PORTAL ACCESS ===' as step,
  enable_employee_portal_access_auto(
    (SELECT id FROM employees WHERE email = 'test3@test.com' LIMIT 1),
    'test3',
    'Employee123!'
  );

-- 8. Test auto-linking
SELECT 
  '=== TESTING AUTO-LINKING ===' as step,
  auto_link_existing_auth_users();

-- 9. Get all employees with portal status
SELECT 
  '=== ALL EMPLOYEES WITH PORTAL STATUS ===' as step,
  get_all_employees_portal_status();

-- 10. Get employees without auth users
SELECT 
  '=== EMPLOYEES WITHOUT AUTH USERS ===' as step,
  get_employees_without_auth_users();

-- 11. Final verification
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
