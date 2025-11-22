/*
  # Fix Ahmed Hassan's Authentication Identity
  
  1. Adds missing entry in auth.identities table
  2. This is required for Supabase authentication to work properly
  
  Note: The auth.identities table links users to their authentication providers
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
    AND email = 'test2@test.com';
  
  IF ahmed_user_id IS NOT NULL THEN
    -- Insert identity record if it doesn't exist
    INSERT INTO auth.identities (
      id,
      user_id,
      identity_data,
      provider,
      provider_id,
      last_sign_in_at,
      created_at,
      updated_at
    )
    SELECT
      gen_random_uuid(),
      ahmed_user_id,
      jsonb_build_object(
        'sub', ahmed_user_id::text,
        'email', 'test2@test.com',
        'email_verified', true,
        'provider', 'email'
      ),
      'email',
      ahmed_user_id::text,
      now(),
      now(),
      now()
    WHERE NOT EXISTS (
      SELECT 1 FROM auth.identities 
      WHERE user_id = ahmed_user_id AND provider = 'email'
    );
    
    RAISE NOTICE 'Auth identity created for user ID: %', ahmed_user_id;
  ELSE
    RAISE NOTICE 'Ahmed Hassan user not found';
  END IF;
END $$;
