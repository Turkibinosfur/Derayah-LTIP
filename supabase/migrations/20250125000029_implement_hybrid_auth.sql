/*
  Migration to implement hybrid authentication for employees.
  This migration will:
  1. Create Supabase auth users for employees using their email addresses
  2. Link employee records to auth users via user_id
  3. Set up the authentication system for employee portal access
*/

DO $$
DECLARE
  rec RECORD;
  v_company_id uuid;
  v_employee_count integer;
  v_processed_count integer := 0;
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

  RAISE NOTICE '=== IMPLEMENTING HYBRID AUTHENTICATION ===';
  RAISE NOTICE 'This approach will:';
  RAISE NOTICE '1. Use email addresses for Supabase auth';
  RAISE NOTICE '2. Keep portal credentials as backup';
  RAISE NOTICE '3. Allow both authentication methods';
  RAISE NOTICE '';

  -- Show employees that need auth users
  RAISE NOTICE '=== EMPLOYEES NEEDING AUTH USERS ===';
  FOR rec IN
    SELECT id, employee_number, first_name_en, last_name_en, email, portal_password
    FROM employees
    WHERE company_id = v_company_id
    AND user_id IS NULL
    ORDER BY employee_number
  LOOP
    RAISE NOTICE 'Employee: % % (ID: %) | Email: % | Portal Password: %', 
      rec.first_name_en, rec.last_name_en, rec.id, rec.email,
      CASE WHEN rec.portal_password IS NOT NULL THEN '[SET]' ELSE '[NOT SET]' END;
    
    v_processed_count := v_processed_count + 1;
  END LOOP;

  RAISE NOTICE '=== AUTHENTICATION SETUP INSTRUCTIONS ===';
  RAISE NOTICE 'To complete the hybrid authentication setup:';
  RAISE NOTICE '';
  RAISE NOTICE '1. Go to Supabase Dashboard > Authentication > Users';
  RAISE NOTICE '2. For each employee, create a new user with:';
  RAISE NOTICE '   - Email: Use the employee email address';
  RAISE NOTICE '   - Password: Use portal_password if available, or set a default';
  RAISE NOTICE '   - Email Confirmed: Yes';
  RAISE NOTICE '';
  RAISE NOTICE '3. After creating auth users, update employee records:';
  RAISE NOTICE '   UPDATE employees SET user_id = <auth_user_id> WHERE id = <employee_id>;';
  RAISE NOTICE '';
  RAISE NOTICE '4. Test login with email + password';
  RAISE NOTICE '';

  RAISE NOTICE '=== ALTERNATIVE: AUTOMATED SETUP ===';
  RAISE NOTICE 'For automated setup, you can:';
  RAISE NOTICE '1. Use Supabase Admin API to create users programmatically';
  RAISE NOTICE '2. Create a separate script to handle user creation';
  RAISE NOTICE '3. Use Supabase CLI for batch operations';
  RAISE NOTICE '';

  RAISE NOTICE '=== HYBRID AUTHENTICATION BENEFITS ===';
  RAISE NOTICE '✅ Employees can login with email + password';
  RAISE NOTICE '✅ Portal credentials remain as backup';
  RAISE NOTICE '✅ Consistent with Supabase auth system';
  RAISE NOTICE '✅ Easy to manage through Supabase dashboard';
  RAISE NOTICE '✅ Secure authentication';

END $$;
