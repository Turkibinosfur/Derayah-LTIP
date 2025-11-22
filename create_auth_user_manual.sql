-- Manual Auth User Creation Instructions
-- This script provides step-by-step instructions to create the auth user

-- Step 1: Check if auth user exists
SELECT 
  '=== AUTH USER CHECK ===' as step,
  CASE 
    WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = 'wajehah.sa@gmail.com') 
    THEN 'Auth user exists' 
    ELSE 'Auth user missing - follow instructions below' 
  END as status;

-- Step 2: If auth user doesn't exist, show instructions
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'wajehah.sa@gmail.com') THEN
    RAISE NOTICE '=== AUTH USER MISSING ===';
    RAISE NOTICE 'Please create the auth user manually:';
    RAISE NOTICE '';
    RAISE NOTICE '1. Go to Supabase Dashboard';
    RAISE NOTICE '2. Navigate to Authentication > Users';
    RAISE NOTICE '3. Click "Add user" button';
    RAISE NOTICE '4. Fill in the details:';
    RAISE NOTICE '   - Email: wajehah.sa@gmail.com';
    RAISE NOTICE '   - Password: Employee123!';
    RAISE NOTICE '   - Email Confirm: true';
    RAISE NOTICE '5. Click "Create user"';
    RAISE NOTICE '6. Confirm the email if prompted';
    RAISE NOTICE '7. Then run the quick_fix_wajehah_login.sql script';
    RAISE NOTICE '';
    RAISE NOTICE 'ALTERNATIVE: You can also use the Supabase CLI:';
    RAISE NOTICE 'supabase auth users create wajehah.sa@gmail.com --password Employee123!';
  ELSE
    RAISE NOTICE 'Auth user exists for wajehah.sa@gmail.com';
    RAISE NOTICE 'You can proceed with the quick_fix_wajehah_login.sql script';
  END IF;
END;
$$;

-- Step 3: Show current auth users (for reference)
SELECT 
  '=== CURRENT AUTH USERS ===' as step,
  id,
  email,
  email_confirmed_at,
  created_at
FROM auth.users 
ORDER BY created_at DESC
LIMIT 10;

-- Step 4: Show what the employee record should look like
SELECT 
  '=== EXPECTED EMPLOYEE RECORD ===' as step,
  'The employee record should have:' as info,
  'id: uuid' as field1,
  'company_id: uuid (Derayah Financial)' as field2,
  'first_name_en: Fatima' as field3,
  'last_name_en: Al-Zahrani' as field4,
  'email: wajehah.sa@gmail.com' as field5,
  'user_id: uuid (from auth.users)' as field6,
  'portal_access_enabled: true' as field7,
  'portal_username: wajehah.sa' as field8,
  'portal_password: Employee123!' as field9;
