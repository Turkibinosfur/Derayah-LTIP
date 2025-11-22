-- Final Admin User Linking Script
-- This script completely avoids ON CONFLICT and uses conditional logic

-- Step 1: Check current setup
SELECT 
  '=== CURRENT SETUP CHECK ===' as step,
  c.id as company_id,
  c.company_name_en,
  cu.id as company_user_id,
  cu.role,
  cu.is_active,
  u.email
FROM companies c
LEFT JOIN company_users cu ON cu.company_id = c.id AND cu.role = 'super_admin'
LEFT JOIN auth.users u ON cu.user_id = u.id
WHERE c.company_name_en = 'Derayah Financial';

-- Step 2: Get admin user ID (replace with actual user ID from Supabase Dashboard)
-- Go to Supabase Dashboard > Authentication > Users
-- Find admin@derayah.com and copy the User ID
-- Then replace 'YOUR_ADMIN_USER_ID_HERE' below with the actual ID

/*
-- Step 3: Link admin user (run this after getting the user ID)
DO $$
DECLARE
  v_company_id uuid;
  v_admin_user_id uuid := 'YOUR_ADMIN_USER_ID_HERE'; -- Replace with actual user ID
  v_existing_count integer;
BEGIN
  -- Get company ID
  SELECT id INTO v_company_id 
  FROM companies 
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Company not found. Please run the migration first.';
  END IF;
  
  -- Check if already linked
  SELECT COUNT(*) INTO v_existing_count
  FROM company_users
  WHERE user_id = v_admin_user_id AND company_id = v_company_id;
  
  -- Link if not already linked
  IF v_existing_count = 0 THEN
    INSERT INTO company_users (
      company_id,
      user_id,
      role,
      is_active,
      created_at
    ) VALUES (
      v_company_id,
      v_admin_user_id,
      'super_admin',
      true,
      now()
    );
    
    RAISE NOTICE 'Admin user linked successfully!';
  ELSE
    RAISE NOTICE 'Admin user already linked.';
  END IF;
END;
$$;
*/

-- Step 4: Final verification
SELECT 
  '=== FINAL VERIFICATION ===' as step,
  c.company_name_en,
  cu.role,
  cu.is_active,
  u.email,
  u.email_confirmed_at
FROM companies c
JOIN company_users cu ON cu.company_id = c.id
JOIN auth.users u ON cu.user_id = u.id
WHERE c.company_name_en = 'Derayah Financial' 
  AND cu.role = 'super_admin';
