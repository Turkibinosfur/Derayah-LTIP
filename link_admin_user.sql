-- Link Admin User to Company
-- Run this AFTER creating admin@derayah.com user in Supabase Dashboard

-- First, check if the user exists (you'll need to replace the UUID with the actual user ID)
SELECT 
  'Check if admin user exists' as step,
  id,
  email,
  email_confirmed_at
FROM auth.users 
WHERE email = 'admin@derayah.com';

-- If the user exists, get their ID and run this:
-- (Replace 'YOUR_ADMIN_USER_ID_HERE' with the actual user ID from above query)

/*
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
) ON CONFLICT (company_id, user_id) DO UPDATE SET
  role = 'super_admin',
  is_active = true,
  updated_at = now();
*/

-- Verify the setup
SELECT 
  'Final verification' as step,
  cu.id,
  cu.role,
  cu.is_active,
  c.company_name_en,
  u.email
FROM company_users cu
JOIN companies c ON cu.company_id = c.id
JOIN auth.users u ON cu.user_id = u.id
WHERE u.email = 'admin@derayah.com';
