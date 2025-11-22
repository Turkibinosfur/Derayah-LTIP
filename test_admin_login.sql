-- Test Admin Login Setup
-- Run this in Supabase SQL Editor to verify admin@derayah.com setup

-- 1. Check if admin user exists
SELECT 
  'Admin User Check' as test,
  id,
  email,
  email_confirmed_at,
  created_at
FROM auth.users 
WHERE email = 'admin@derayah.com';

-- 2. Check company_users association
SELECT 
  'Company Users Check' as test,
  cu.id,
  cu.role,
  cu.is_active,
  c.company_name_en
FROM company_users cu
JOIN companies c ON cu.company_id = c.id
JOIN auth.users u ON cu.user_id = u.id
WHERE u.email = 'admin@derayah.com';

-- 3. Test password hash
SELECT 
  'Password Test' as test,
  CASE 
    WHEN encrypted_password = crypt('Admin123!', encrypted_password) 
    THEN 'Password matches' 
    ELSE 'Password does not match' 
  END as password_check
FROM auth.users 
WHERE email = 'admin@derayah.com';

-- 4. Check RLS policies
SELECT 
  'RLS Policies' as test,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE tablename IN ('companies', 'company_users')
ORDER BY tablename, policyname;
