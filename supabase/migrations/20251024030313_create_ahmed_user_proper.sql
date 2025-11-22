/*
  # Create Ahmed Hassan User Properly
  
  1. Deletes existing test2@test.com user
  2. Uses proper password hashing
  3. Creates complete user record
  4. Links to Ahmed Hassan employee
*/

DO $$
DECLARE
  old_user_id uuid;
  new_user_id uuid;
  employee_rec record;
  hashed_password text;
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
  
  -- Unlink and delete old user
  IF old_user_id IS NOT NULL THEN
    UPDATE employees SET user_id = NULL WHERE id = employee_rec.id;
    DELETE FROM auth.identities WHERE user_id = old_user_id;
    DELETE FROM auth.sessions WHERE user_id = old_user_id;
    DELETE FROM auth.users WHERE id = old_user_id;
    RAISE NOTICE 'Deleted old user: %', old_user_id;
  END IF;
  
  -- Generate new user ID
  new_user_id := gen_random_uuid();
  
  -- Hash password properly (Test123!)
  hashed_password := crypt('Test123!', gen_salt('bf', 10));
  
  -- Create new auth user with complete structure
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    invited_at,
    confirmation_token,
    confirmation_sent_at,
    recovery_token,
    recovery_sent_at,
    email_change_token_new,
    email_change,
    email_change_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at,
    phone,
    phone_confirmed_at,
    phone_change,
    phone_change_token,
    phone_change_sent_at,
    email_change_token_current,
    email_change_confirm_status,
    banned_until,
    reauthentication_token,
    reauthentication_sent_at,
    is_sso_user,
    deleted_at,
    is_anonymous,
    role,
    aud
  ) VALUES (
    new_user_id,
    '00000000-0000-0000-0000-000000000000',
    'ahmed.hassan@derayah.com',
    hashed_password,
    now(),
    NULL,
    '',
    NULL,
    '',
    NULL,
    '',
    '',
    NULL,
    NULL,
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object(
      'sub', new_user_id::text,
      'email', 'ahmed.hassan@derayah.com',
      'email_verified', true,
      'phone_verified', false
    ),
    NULL,
    now(),
    now(),
    NULL,
    NULL,
    '',
    '',
    NULL,
    '',
    0,
    NULL,
    '',
    NULL,
    false,
    NULL,
    false,
    'authenticated',
    'authenticated'
  );
  
  -- Create identity record
  INSERT INTO auth.identities (
    id,
    provider_id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    new_user_id::text,
    new_user_id,
    jsonb_build_object(
      'sub', new_user_id::text,
      'email', 'ahmed.hassan@derayah.com',
      'email_verified', true,
      'phone_verified', false
    ),
    'email',
    NULL,
    now(),
    now()
  );
  
  -- Link to employee
  UPDATE employees 
  SET 
    user_id = new_user_id,
    email = 'ahmed.hassan@derayah.com'
  WHERE id = employee_rec.id;
  
  RAISE NOTICE 'Created new user: % for employee: %', new_user_id, employee_rec.id;
  RAISE NOTICE 'Email: ahmed.hassan@derayah.com';
  RAISE NOTICE 'Password: Test123!';
END $$;
