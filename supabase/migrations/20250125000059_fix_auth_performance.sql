/*
  # Fix Auth Performance Issues
  
  This migration addresses potential performance issues with the unified auth system
  that might be causing login lag for admin@derayah.com
*/

-- 1. Ensure admin user exists and is properly configured
DO $$
DECLARE
  v_admin_user_id uuid;
  v_company_id uuid;
  v_existing_user_id uuid;
BEGIN
  -- Get company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE NOTICE 'Company not found, skipping admin setup';
    RETURN;
  END IF;
  
  -- Check if admin user exists
  SELECT id INTO v_existing_user_id
  FROM auth.users
  WHERE email = 'admin@derayah.com';
  
  IF v_existing_user_id IS NULL THEN
    -- Create admin user
    v_admin_user_id := gen_random_uuid();
    
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_admin_user_id,
      'authenticated',
      'authenticated',
      'admin@derayah.com',
      crypt('Admin123!', gen_salt('bf')),
      now(),
      now(),
      now()
    );
    
    RAISE NOTICE 'Created admin user: %', v_admin_user_id;
  ELSE
    v_admin_user_id := v_existing_user_id;
    RAISE NOTICE 'Using existing admin user: %', v_admin_user_id;
  END IF;
  
  -- Ensure company_users entry exists
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
  ) ON CONFLICT (company_id, user_id) DO UPDATE SET
    role = 'super_admin',
    is_active = true,
    updated_at = now();
    
  RAISE NOTICE 'Admin user setup complete';
END;
$$;

-- 2. Optimize user_roles view for better performance
DROP VIEW IF EXISTS user_roles;

CREATE VIEW user_roles AS
SELECT 
  u.id as user_id,
  u.email,
  cu.company_id,
  cu.role,
  cu.is_active,
  CASE 
    WHEN cu.role = 'super_admin' THEN 'super_admin'
    WHEN cu.role IN ('hr_admin', 'finance_admin', 'legal_admin') THEN 'company_admin'
    WHEN EXISTS (SELECT 1 FROM employees e WHERE e.user_id = u.id) THEN 'employee'
    ELSE 'unknown'
  END as user_type
FROM auth.users u
LEFT JOIN company_users cu ON u.id = cu.user_id
WHERE u.email_confirmed_at IS NOT NULL;

-- 3. Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_user_id ON company_users(user_id);
CREATE INDEX IF NOT EXISTS idx_company_users_company_id ON company_users(company_id);
CREATE INDEX IF NOT EXISTS idx_employees_user_id ON employees(user_id);
CREATE INDEX IF NOT EXISTS idx_auth_users_email ON auth.users(email);

-- 4. Simplify RLS policies to reduce complexity
DROP POLICY IF EXISTS "Users can view own employee data" ON employees;
DROP POLICY IF EXISTS "Company admins can view company employees" ON employees;
DROP POLICY IF EXISTS "HR admins can manage employees" ON employees;

-- Create simpler, more efficient policies
CREATE POLICY "Employees can view own data"
  ON employees FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Company admins can view employees"
  ON employees FOR SELECT TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  );

CREATE POLICY "HR admins can manage employees"
  ON employees FOR ALL TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin')
    )
  );

-- 5. Test the setup
SELECT 
  '=== FINAL VERIFICATION ===' as info;

SELECT 
  u.id,
  u.email,
  u.email_confirmed_at,
  cu.role,
  cu.is_active,
  c.company_name_en
FROM auth.users u
LEFT JOIN company_users cu ON u.id = cu.user_id
LEFT JOIN companies c ON cu.company_id = c.id
WHERE u.email = 'admin@derayah.com';
