/*
  # Recreate Ahmed Hassan User - Final Fix
  
  1. Unlinks user from employee
  2. Deletes existing problematic auth user  
  3. Creates new auth user with all required fields
  4. Creates identity with provider_id (email is generated)
  5. Links to existing employee record
*/

DO $$
DECLARE
  old_user_id uuid;
  new_user_id uuid;
  employee_rec record;
BEGIN
  -- Get the employee record
  SELECT id, company_id INTO employee_rec
  FROM employees
  WHERE first_name_en = 'Ahmed' 
    AND last_name_en = 'Hassan';
  
  IF employee_rec.id IS NULL THEN
    RAISE EXCEPTION 'Ahmed Hassan employee record not found';
  END IF;
  
  -- Get old user_id if exists
  SELECT user_id INTO old_user_id
  FROM employees
  WHERE id = employee_rec.id;
  
  -- Unlink from employee first
  IF old_user_id IS NOT NULL THEN
    UPDATE employees SET user_id = NULL WHERE id = employee_rec.id;
    
    -- Now delete old auth records
    DELETE FROM auth.identities WHERE user_id = old_user_id;
    DELETE FROM auth.users WHERE id = old_user_id;
    RAISE NOTICE 'Deleted old user: %', old_user_id;
  END IF;
  
  -- Generate new user ID
  new_user_id := gen_random_uuid();
  
  -- Create new auth user
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    role,
    aud,
    is_sso_user,
    is_anonymous
  ) VALUES (
    new_user_id,
    '00000000-0000-0000-0000-000000000000',
    'test2@test.com',
    crypt('Emplo123!', gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"name":"Ahmed Hassan"}'::jsonb,
    false,
    'authenticated',
    'authenticated',
    false,
    false
  );
  
  -- Create identity record with provider_id (email column is generated from identity_data)
  INSERT INTO auth.identities (
    provider_id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    new_user_id::text,
    new_user_id,
    jsonb_build_object(
      'sub', new_user_id::text,
      'email', 'test2@test.com',
      'email_verified', true,
      'provider', 'email'
    ),
    'email',
    now(),
    now(),
    now()
  );
  
  -- Link to employee
  UPDATE employees 
  SET 
    user_id = new_user_id,
    email = 'test2@test.com'
  WHERE id = employee_rec.id;
  
  RAISE NOTICE 'Created new user: % for employee: %', new_user_id, employee_rec.id;
END $$;
