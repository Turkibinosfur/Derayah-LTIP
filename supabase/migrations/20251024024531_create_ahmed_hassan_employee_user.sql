/*
  # Create Employee User for Ahmed Hassan
  
  1. Creates auth user with email: ahmed.hassan@sauditech.com
  2. Links the auth user to the existing employee record
  
  Note: This migration creates a user account for testing the employee portal.
  Password will be: Emplo123!
*/

-- Insert auth user for Ahmed Hassan
-- Using INSERT INTO auth.users with the proper structure
DO $$
DECLARE
  new_user_id uuid;
BEGIN
  -- Generate a new UUID for the user
  new_user_id := gen_random_uuid();
  
  -- Insert into auth.users
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
    aud
  ) VALUES (
    new_user_id,
    '00000000-0000-0000-0000-000000000000',
    'ahmed.hassan@sauditech.com',
    crypt('Emplo123!', gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"name":"Ahmed Hassan"}'::jsonb,
    false,
    'authenticated',
    'authenticated'
  );
  
  -- Link the user to the employee record
  UPDATE employees 
  SET user_id = new_user_id
  WHERE first_name_en = 'Ahmed' 
    AND last_name_en = 'Hassan'
    AND email = 'ahmed.hassan@sauditech.com';
    
  RAISE NOTICE 'User created successfully with ID: %', new_user_id;
END $$;
