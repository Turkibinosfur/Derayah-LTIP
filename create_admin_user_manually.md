# Manual Admin User Creation

Since we can't directly access the `auth.users` table through migrations, please follow these steps to create the admin user manually:

## Step 1: Create Admin User in Supabase Dashboard

1. Go to your Supabase Dashboard
2. Navigate to **Authentication** > **Users**
3. Click **"Add user"**
4. Fill in the details:
   - **Email**: `admin@derayah.com`
   - **Password**: `Admin123!`
   - **Email Confirm**: ✅ (check this box)
5. Click **"Create user"**
6. Copy the **User ID** that gets generated

## Step 2: Run the Simple Auth Fix Migration

Run this migration in your Supabase SQL Editor:
```sql
-- Run: 20250125000060_simple_auth_fix.sql
```

## Step 3: Link Admin User to Company

After creating the user, run this SQL to link them to the company:

```sql
-- Replace 'YOUR_ADMIN_USER_ID' with the actual User ID from Step 1
INSERT INTO company_users (
  company_id,
  user_id,
  role,
  is_active,
  created_at
) VALUES (
  (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'),
  'YOUR_ADMIN_USER_ID',
  'super_admin',
  true,
  now()
) ON CONFLICT (company_id, user_id) DO UPDATE SET
  role = 'super_admin',
  is_active = true,
  updated_at = now();
```

## Step 4: Test the Login

1. Go to your application login page
2. Use credentials:
   - **Email**: `admin@derayah.com`
   - **Password**: `Admin123!`
3. The login should now work without lag

## Alternative: Use Supabase CLI

If you have Supabase CLI installed, you can also create the user via command line:

```bash
supabase auth users create admin@derayah.com --password Admin123! --email-confirm
```

Then get the user ID and run the linking SQL from Step 3.
