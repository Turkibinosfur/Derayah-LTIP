-- Auto Create Auth User Function
-- This function automatically creates auth users for employees when portal access is enabled

-- 1. Create a function to automatically create auth user for employee
CREATE OR REPLACE FUNCTION create_employee_auth_user(
  p_employee_id uuid,
  p_email text,
  p_password text DEFAULT 'Employee123!'
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_auth_user_id uuid;
  v_employee_record employees%ROWTYPE;
BEGIN
  -- Get employee record
  SELECT * INTO v_employee_record
  FROM employees
  WHERE id = p_employee_id;
  
  IF v_employee_record IS NULL THEN
    RAISE NOTICE 'Employee record not found for ID: %', p_employee_id;
    RETURN false;
  END IF;
  
  -- Check if auth user already exists
  SELECT id INTO v_auth_user_id
  FROM auth.users
  WHERE email = p_email;
  
  IF v_auth_user_id IS NOT NULL THEN
    RAISE NOTICE 'Auth user already exists for email: %', p_email;
    -- Link existing auth user to employee
    UPDATE employees SET
      user_id = v_auth_user_id,
      updated_at = now()
    WHERE id = p_employee_id;
    RETURN true;
  END IF;
  
  -- Create auth user using Supabase admin API
  -- Note: This requires the service role key
  PERFORM auth.admin_create_user(
    email := p_email,
    password := p_password,
    email_confirm := true
  );
  
  -- Get the created auth user ID
  SELECT id INTO v_auth_user_id
  FROM auth.users
  WHERE email = p_email;
  
  IF v_auth_user_id IS NULL THEN
    RAISE NOTICE 'Failed to create auth user for email: %', p_email;
    RETURN false;
  END IF;
  
  -- Link auth user to employee
  UPDATE employees SET
    user_id = v_auth_user_id,
    updated_at = now()
  WHERE id = p_employee_id;
  
  RAISE NOTICE 'Auth user created and linked for employee: % (%)', 
    v_employee_record.first_name_en || ' ' || v_employee_record.last_name_en, 
    p_email;
  
  RETURN true;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error creating auth user for %: %', p_email, SQLERRM;
    RETURN false;
END;
$$;

-- 2. Create a trigger function to automatically create auth user when portal access is enabled
CREATE OR REPLACE FUNCTION trigger_create_employee_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_password text;
BEGIN
  -- Only process if portal access is being enabled
  IF NEW.portal_access_enabled = true AND (OLD.portal_access_enabled = false OR OLD.portal_access_enabled IS NULL) THEN
    -- Use portal password if available, otherwise use default
    v_password := COALESCE(NEW.portal_password, 'Employee123!');
    
    -- Create auth user
    PERFORM create_employee_auth_user(
      NEW.id,
      NEW.email,
      v_password
    );
  END IF;
  
  RETURN NEW;
END;
$$;

-- 3. Create trigger on employees table
DROP TRIGGER IF EXISTS trigger_auto_create_auth_user ON employees;
CREATE TRIGGER trigger_auto_create_auth_user
  AFTER UPDATE ON employees
  FOR EACH ROW
  EXECUTE FUNCTION trigger_create_employee_auth_user();

-- 4. Test the function with existing employees
DO $$
DECLARE
  rec RECORD;
  v_success boolean;
BEGIN
  RAISE NOTICE '=== TESTING AUTO AUTH USER CREATION ===';
  
  -- Test with test3@test.com
  FOR rec IN 
    SELECT id, email, first_name_en, last_name_en, portal_password
    FROM employees 
    WHERE email = 'test3@test.com' 
      AND portal_access_enabled = true
      AND user_id IS NULL
  LOOP
    v_success := create_employee_auth_user(
      rec.id,
      rec.email,
      COALESCE(rec.portal_password, 'Employee123!')
    );
    
    IF v_success THEN
      RAISE NOTICE 'SUCCESS: Auth user created for % (%)', rec.first_name_en, rec.email;
    ELSE
      RAISE NOTICE 'FAILED: Could not create auth user for % (%)', rec.first_name_en, rec.email;
    END IF;
  END LOOP;
END;
$$;

-- 5. Verify the setup
SELECT 
  '=== VERIFICATION ===' as step,
  e.id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.user_id,
  e.portal_access_enabled,
  u.email as auth_email,
  u.email_confirmed_at
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
WHERE e.portal_access_enabled = true
ORDER BY e.created_at DESC;
