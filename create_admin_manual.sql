-- Manual Admin User Creation
-- Run this step by step to create admin@derayah.com

-- Step 1: Check if company exists
SELECT 
  'Step 1: Check company' as step,
  id,
  company_name_en
FROM companies
WHERE company_name_en = 'Derayah Financial';

-- Step 2: Check if admin user exists
SELECT 
  'Step 2: Check admin user' as step,
  id,
  email,
  email_confirmed_at
FROM auth.users 
WHERE email = 'admin@derayah.com';

-- Step 3: If admin user exists, get their ID and run this:
-- (Replace 'YOUR_ADMIN_USER_ID_HERE' with the actual user ID from Step 2)

/*
-- Check if already linked
SELECT 
  'Step 3a: Check existing link' as step,
  cu.id,
  cu.role,
  cu.is_active
FROM company_users cu
WHERE cu.user_id = 'YOUR_ADMIN_USER_ID_HERE';

-- If no existing link, create it
INSERT INTO company_users (
  company_id,
  user_id,
  role,
  is_active,
  created_at
) VALUES (
  (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'),
  'YOUR_ADMIN_USER_ID_HERE',
  'super_admin',
  true,
  now()
);
*/

-- Step 4: Final verification
SELECT 
  'Step 4: Final verification' as step,
  cu.id,
  cu.role,
  cu.is_active,
  c.company_name_en,
  u.email
FROM company_users cu
JOIN companies c ON cu.company_id = c.id
JOIN auth.users u ON cu.user_id = u.id
WHERE u.email = 'admin@derayah.com';
