-- Test Admin Setup
-- Run this to verify admin@derayah.com is properly configured

-- 1. Check if admin user exists in auth.users
SELECT 
  '=== ADMIN USER CHECK ===' as test,
  id,
  email,
  email_confirmed_at,
  created_at,
  last_sign_in_at
FROM auth.users 
WHERE email = 'admin@derayah.com';

-- 2. Check company_users association
SELECT 
  '=== COMPANY USERS CHECK ===' as test,
  cu.id,
  cu.role,
  cu.is_active,
  c.company_name_en
FROM company_users cu
JOIN companies c ON cu.company_id = c.id
JOIN auth.users u ON cu.user_id = u.id
WHERE u.email = 'admin@derayah.com';

-- 3. Check if company exists
SELECT 
  '=== COMPANY CHECK ===' as test,
  id,
  company_name_en,
  status
FROM companies
WHERE company_name_en = 'Derayah Financial';

-- 4. Test password (this will show if password hash is correct)
SELECT 
  '=== PASSWORD TEST ===' as test,
  CASE 
    WHEN encrypted_password = crypt('Admin123!', encrypted_password) 
    THEN 'Password matches' 
    ELSE 'Password does not match' 
  END as password_check
FROM auth.users 
WHERE email = 'admin@derayah.com';

-- 5. Check RLS policies
SELECT 
  '=== RLS POLICIES ===' as test,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE tablename IN ('companies', 'company_users')
ORDER BY tablename, policyname;
