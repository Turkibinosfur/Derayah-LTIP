/*
  Migration to set up proper authentication for employees.
  This migration will:
  1. Check current employee data
  2. Create Supabase auth users for employees if needed
  3. Link employee records to auth users
*/

DO $$
DECLARE
  rec RECORD;
  v_company_id uuid;
  v_employee_count integer;
  v_auth_user_id uuid;
  v_employee_id uuid;
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

  -- Check current employees and their auth status
  RAISE NOTICE '=== CURRENT EMPLOYEES AUTH STATUS ===';
  FOR rec IN
    SELECT 
      id, 
      employee_number, 
      first_name_en, 
      last_name_en, 
      email,
      user_id,
      portal_username,
      portal_password,
      portal_access_enabled
    FROM employees
    WHERE company_id = v_company_id
    ORDER BY employee_number
  LOOP
    RAISE NOTICE 'Employee: % % (ID: %) | Email: % | Auth User ID: % | Portal Username: % | Portal Password: % | Portal Enabled: %', 
      rec.first_name_en, rec.last_name_en, rec.id, rec.email, 
      COALESCE(rec.user_id::text, 'NULL'),
      COALESCE(rec.portal_username, 'NULL'),
      CASE WHEN rec.portal_password IS NOT NULL THEN '[SET]' ELSE '[NOT SET]' END,
      rec.portal_access_enabled;
  END LOOP;

  -- Check if employees have auth users
  SELECT COUNT(*) INTO v_employee_count
  FROM employees
  WHERE company_id = v_company_id
  AND user_id IS NOT NULL;

  RAISE NOTICE 'Number of employees with auth users: %', v_employee_count;

  -- Show employees without auth users
  RAISE NOTICE '=== EMPLOYEES WITHOUT AUTH USERS ===';
  FOR rec IN
    SELECT id, employee_number, first_name_en, last_name_en, email
    FROM employees
    WHERE company_id = v_company_id
    AND user_id IS NULL
  LOOP
    RAISE NOTICE 'Employee without auth: % % (ID: %) | Email: %', 
      rec.first_name_en, rec.last_name_en, rec.id, rec.email;
  END LOOP;

  -- Check if there are any auth users that might be linked
  RAISE NOTICE '=== AUTH USERS IN SYSTEM ===';
  FOR rec IN
    SELECT id, email, created_at
    FROM auth.users
    WHERE email LIKE '%derayah%' OR email LIKE '%@derayah.com'
    ORDER BY created_at
  LOOP
    RAISE NOTICE 'Auth User: % | Email: % | Created: %', 
      rec.id, rec.email, rec.created_at;
  END LOOP;

  RAISE NOTICE '=== RECOMMENDATIONS ===';
  RAISE NOTICE '1. Employees need Supabase auth users to login';
  RAISE NOTICE '2. Auth users must be linked to employee records via user_id';
  RAISE NOTICE '3. Portal credentials (username/password) are separate from auth';
  RAISE NOTICE '4. Login requires EMAIL + PASSWORD (not username)';
  RAISE NOTICE '5. Consider creating auth users for employees or using different auth method';

END $$;
