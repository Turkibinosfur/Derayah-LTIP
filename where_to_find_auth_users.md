# Where to Find Auth Users and Their Credentials

## 1. Supabase Dashboard (Recommended)

### Step-by-Step Instructions:

1. **Go to Supabase Dashboard**
   - Open your browser and go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
   - Sign in with your Supabase account

2. **Select Your Project**
   - Click on your Derayah project

3. **Navigate to Authentication**
   - In the left sidebar, click on "Authentication"
   - Then click on "Users"

4. **View All Users**
   - You'll see a list of all auth users
   - Each user shows:
     - Email address
     - User ID
     - Created date
     - Last sign-in date
     - Email confirmation status

5. **Add New User**
   - Click "Add user" button
   - Enter email: `test6@test.com`
   - Enter password: `Employee123!`
   - Set "Email Confirm" to true
   - Click "Create user"

## 2. SQL Query (Alternative)

You can also run this SQL query in the Supabase SQL Editor:

```sql
-- Show all auth users
SELECT 
  id,
  email,
  email_confirmed_at,
  created_at,
  last_sign_in_at
FROM auth.users 
ORDER BY created_at DESC;
```

## 3. Current Employee Status

Run this query to see which employees need auth users:

```sql
-- Show employees without auth users
SELECT 
  e.id,
  e.first_name_en,
  e.last_name_en,
  e.email,
  e.portal_username,
  e.portal_password,
  'Needs Auth User Creation' as status
FROM employees e
WHERE e.portal_access_enabled = true 
  AND e.user_id IS NULL
ORDER BY e.created_at DESC;
```

## 4. Quick Fix for test6@test.com

1. **Create Auth User**:
   - Go to Supabase Dashboard > Authentication > Users
   - Click "Add user"
   - Email: `test6@test.com`
   - Password: `Employee123!`
   - Set Email Confirm to true
   - Click "Create user"

2. **Link to Employee**:
   - Run this SQL query:
   ```sql
   SELECT link_employee_to_auth_by_email('test6@test.com');
   ```

3. **Test Login**:
   - Email: `test6@test.com`
   - Password: `Employee123!`

## 5. View All Credentials

To see all employee credentials and their auth status, run:

```sql
-- Show all employee credentials and auth status
SELECT 
  e.id as employee_id,
  e.first_name_en,
  e.last_name_en,
  e.email as employee_email,
  e.portal_username,
  e.portal_password,
  e.portal_access_enabled,
  u.email as auth_email,
  u.email_confirmed_at,
  CASE 
    WHEN e.portal_access_enabled = true AND e.user_id IS NOT NULL AND u.id IS NOT NULL 
    THEN 'Ready to Login' 
    WHEN e.portal_access_enabled = true AND e.user_id IS NULL
    THEN 'Needs Auth User Creation'
    ELSE 'Portal Access Disabled'
  END as status
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
ORDER BY e.created_at DESC;
```
