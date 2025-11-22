/*
  # Implement Unified Supabase Auth System
  
  ## Overview
  This migration implements a unified authentication system using Supabase Auth for all user types:
  - Super Admin (system-wide access)
  - Company Admin (company-specific access) 
  - Employee (employee portal access)
  
  ## Changes
  1. Create Supabase auth users for all existing employees
  2. Link employee records to auth users via user_id
  3. Update RLS policies to work with unified auth
  4. Create helper functions for user role detection
  5. Set up proper user management functions
*/

-- =====================================================
-- 1. CREATE AUTH USERS FOR EXISTING EMPLOYEES
-- =====================================================

-- Function to create auth user for employee
CREATE OR REPLACE FUNCTION create_employee_auth_user(
  p_employee_id uuid,
  p_email text,
  p_password text DEFAULT 'Employee123!'
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
  v_employee_record record;
BEGIN
  -- Get employee record
  SELECT * INTO v_employee_record
  FROM employees
  WHERE id = p_employee_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Employee not found: %', p_employee_id;
  END IF;
  
  -- Create auth user
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    p_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    now(),
    now(),
    '',
    '',
    '',
    ''
  ) RETURNING id INTO v_user_id;
  
  -- Update employee record with user_id
  UPDATE employees
  SET user_id = v_user_id
  WHERE id = p_employee_id;
  
  RETURN v_user_id;
END;
$$;

-- =====================================================
-- 2. CREATE AUTH USERS FOR ALL EXISTING EMPLOYEES
-- =====================================================

DO $$
DECLARE
  emp_record RECORD;
  v_user_id uuid;
BEGIN
  -- Create auth users for all employees that don't have user_id
  FOR emp_record IN 
    SELECT id, email, first_name_en, last_name_en
    FROM employees 
    WHERE user_id IS NULL
    AND email IS NOT NULL
    AND email != ''
  LOOP
    BEGIN
      -- Create auth user
      v_user_id := create_employee_auth_user(
        emp_record.id,
        emp_record.email,
        'Employee123!'
      );
      
      RAISE NOTICE 'Created auth user for employee: % (%)', emp_record.first_name_en, emp_record.email;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE NOTICE 'Failed to create auth user for employee %: %', emp_record.email, SQLERRM;
    END;
  END LOOP;
END;
$$;

-- =====================================================
-- 3. CREATE USER ROLE DETECTION FUNCTIONS
-- =====================================================

-- Function to get user role in a company
CREATE OR REPLACE FUNCTION get_user_role(p_company_id uuid, p_user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_role text;
BEGIN
  SELECT role::text INTO v_role
  FROM company_users
  WHERE company_id = p_company_id AND user_id = p_user_id;
  
  RETURN COALESCE(v_role, 'employee');
END;
$$;

-- Function to check if user is super admin
CREATE OR REPLACE FUNCTION is_super_admin(p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM company_users
    WHERE user_id = p_user_id AND role = 'super_admin'
  );
END;
$$;

-- Function to check if user is company admin
CREATE OR REPLACE FUNCTION is_company_admin(p_company_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM company_users
    WHERE company_id = p_company_id 
    AND user_id = p_user_id 
    AND role IN ('super_admin', 'hr_admin', 'finance_admin', 'legal_admin')
  );
END;
$$;

-- Function to check if user is employee
CREATE OR REPLACE FUNCTION is_employee(p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM employees
    WHERE user_id = p_user_id
  );
END;
$$;

-- =====================================================
-- 4. UPDATE RLS POLICIES FOR UNIFIED AUTH
-- =====================================================

-- Drop existing employee policies
DROP POLICY IF EXISTS "Employees can view own data" ON employees;
DROP POLICY IF EXISTS "HR admins can manage employees" ON employees;

-- Create new unified employee policies
CREATE POLICY "Users can view own employee data"
  ON employees FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Company admins can view company employees"
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

-- Update grants policies
DROP POLICY IF EXISTS "Users can view relevant grants" ON grants;
DROP POLICY IF EXISTS "Admins can manage grants" ON grants;

CREATE POLICY "Employees can view own grants"
  ON grants FOR SELECT TO authenticated
  USING (
    employee_id IN (
      SELECT id FROM employees WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Company admins can view company grants"
  ON grants FOR SELECT TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  );

CREATE POLICY "HR admins can manage grants"
  ON grants FOR ALL TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin')
    )
  );

-- Update portfolios policies
DROP POLICY IF EXISTS "Users can view relevant portfolios" ON portfolios;

CREATE POLICY "Employees can view own portfolios"
  ON portfolios FOR SELECT TO authenticated
  USING (
    employee_id IN (
      SELECT id FROM employees WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Company admins can view company portfolios"
  ON portfolios FOR SELECT TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  );

-- =====================================================
-- 5. CREATE USER MANAGEMENT FUNCTIONS
-- =====================================================

-- Function to create company admin user
CREATE OR REPLACE FUNCTION create_company_admin(
  p_company_id uuid,
  p_email text,
  p_password text,
  p_role text DEFAULT 'hr_admin'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Create auth user
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
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    p_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    now(),
    now()
  ) RETURNING id INTO v_user_id;
  
  -- Create company user association
  INSERT INTO company_users (company_id, user_id, role)
  VALUES (p_company_id, v_user_id, p_role::user_role);
  
  RETURN v_user_id;
END;
$$;

-- Function to create employee user
CREATE OR REPLACE FUNCTION create_employee_user(
  p_employee_id uuid,
  p_email text,
  p_password text DEFAULT 'Employee123!'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
  v_company_id uuid;
BEGIN
  -- Get company_id from employee
  SELECT company_id INTO v_company_id
  FROM employees
  WHERE id = p_employee_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Employee not found: %', p_employee_id;
  END IF;
  
  -- Create auth user
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
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    p_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    now(),
    now()
  ) RETURNING id INTO v_user_id;
  
  -- Update employee with user_id
  UPDATE employees
  SET user_id = v_user_id
  WHERE id = p_employee_id;
  
  RETURN v_user_id;
END;
$$;

-- =====================================================
-- 6. CREATE USER ROLE VIEWS
-- =====================================================

-- View to get user roles and permissions
CREATE OR REPLACE VIEW user_roles AS
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

-- =====================================================
-- 7. VERIFICATION QUERIES
-- =====================================================

-- Show created auth users
SELECT 
  '=== AUTH USERS CREATED ===' as info;

SELECT 
  u.id,
  u.email,
  u.email_confirmed_at,
  e.first_name_en,
  e.last_name_en,
  e.company_id
FROM auth.users u
JOIN employees e ON u.id = e.user_id
ORDER BY u.created_at DESC;

-- Show user roles
SELECT 
  '=== USER ROLES ===' as info;

SELECT 
  user_id,
  email,
  company_id,
  role,
  user_type
FROM user_roles
ORDER BY user_type, email;

-- Show RLS policy status
SELECT 
  '=== RLS POLICIES STATUS ===' as info;

SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename IN ('employees', 'grants', 'portfolios', 'company_users')
ORDER BY tablename, policyname;
