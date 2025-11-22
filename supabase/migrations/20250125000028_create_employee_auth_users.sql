/*
  Migration to create Supabase auth users for employees.
  This migration will create auth users and link them to employee records.
  
  NOTE: This is a complex operation that requires careful handling.
  In production, you might want to use a different approach.
*/

DO $$
DECLARE
  rec RECORD;
  v_company_id uuid;
  v_auth_user_id uuid;
  v_employee_id uuid;
  v_employee_count integer;
  v_created_count integer := 0;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';

  IF v_company_id IS NULL THEN
    RAISE NOTICE 'Company "Derayah Financial" not found. Exiting migration.';
    RETURN;
  END IF;

  RAISE NOTICE 'Processing company ID: %', v_company_id;

  -- Count employees without auth users
  SELECT COUNT(*) INTO v_employee_count
  FROM employees
  WHERE company_id = v_company_id
  AND user_id IS NULL;

  RAISE NOTICE 'Employees without auth users: %', v_employee_count;

  IF v_employee_count = 0 THEN
    RAISE NOTICE 'All employees already have auth users. Exiting.';
    RETURN;
  END IF;

  RAISE NOTICE '=== CREATING AUTH USERS FOR EMPLOYEES ===';
  RAISE NOTICE 'WARNING: This is a complex operation. In production, consider:';
  RAISE NOTICE '1. Using Supabase Admin API to create users';
  RAISE NOTICE '2. Using a different authentication method';
  RAISE NOTICE '3. Manual user creation through Supabase dashboard';
  RAISE NOTICE '';

  -- For now, we'll just show what needs to be done
  FOR rec IN
    SELECT id, employee_number, first_name_en, last_name_en, email, portal_password
    FROM employees
    WHERE company_id = v_company_id
    AND user_id IS NULL
    ORDER BY employee_number
  LOOP
    RAISE NOTICE 'Employee needing auth user: % % (ID: %) | Email: % | Portal Password: %', 
      rec.first_name_en, rec.last_name_en, rec.id, rec.email,
      CASE WHEN rec.portal_password IS NOT NULL THEN '[SET]' ELSE '[NOT SET]' END;
    
    -- NOTE: We cannot directly create auth users in a migration
    -- This would need to be done through:
    -- 1. Supabase Admin API
    -- 2. Supabase Dashboard
    -- 3. A separate application script
    
    RAISE NOTICE '  → To create auth user for this employee:';
    RAISE NOTICE '    1. Go to Supabase Dashboard > Authentication > Users';
    RAISE NOTICE '    2. Create user with email: %', rec.email;
    RAISE NOTICE '    3. Set password (use portal_password if available)';
    RAISE NOTICE '    4. Update employee record with user_id';
    RAISE NOTICE '';
  END LOOP;

  RAISE NOTICE '=== ALTERNATIVE APPROACH ===';
  RAISE NOTICE 'Consider modifying the login system to:';
  RAISE NOTICE '1. Use portal_username + portal_password for login';
  RAISE NOTICE '2. Create a custom authentication method';
  RAISE NOTICE '3. Use a different auth provider';
  RAISE NOTICE '4. Implement username-based login instead of email-based';

END $$;
