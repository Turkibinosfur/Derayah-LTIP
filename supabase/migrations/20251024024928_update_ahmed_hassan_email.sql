/*
  # Update Ahmed Hassan's Email
  
  1. Updates email in auth.users table to test2@test.com
  2. Updates email in employees table to test2@test.com
  3. Maintains the link between auth user and employee record
*/

DO $$
DECLARE
  ahmed_user_id uuid;
BEGIN
  -- Get Ahmed's user_id
  SELECT user_id INTO ahmed_user_id
  FROM employees
  WHERE first_name_en = 'Ahmed' 
    AND last_name_en = 'Hassan'
    AND email = 'ahmed.hassan@sauditech.com';
  
  IF ahmed_user_id IS NOT NULL THEN
    -- Update email in auth.users
    UPDATE auth.users
    SET 
      email = 'test2@test.com',
      raw_user_meta_data = jsonb_set(
        COALESCE(raw_user_meta_data, '{}'::jsonb),
        '{email}',
        '"test2@test.com"'
      ),
      updated_at = now()
    WHERE id = ahmed_user_id;
    
    -- Update email in employees table
    UPDATE employees
    SET email = 'test2@test.com'
    WHERE user_id = ahmed_user_id;
    
    RAISE NOTICE 'Email updated successfully for user ID: %', ahmed_user_id;
  ELSE
    RAISE NOTICE 'Ahmed Hassan user not found';
  END IF;
END $$;
