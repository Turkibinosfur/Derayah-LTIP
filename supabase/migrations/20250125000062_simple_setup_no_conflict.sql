/*
  # Simple Setup Without ON CONFLICT
  
  This migration sets up the basic structure without using ON CONFLICT
  to avoid constraint issues.
*/

-- 1. Ensure company exists (without ON CONFLICT)
DO $$
DECLARE
  v_company_id uuid;
BEGIN
  -- Check if company exists
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  -- Create company if it doesn't exist
  IF v_company_id IS NULL THEN
    INSERT INTO companies (
      id,
      company_name_en,
      company_name_ar,
      tadawul_symbol,
      commercial_registration_number,
      verification_status,
      total_reserved_shares,
      available_shares,
      status,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      'Derayah Financial',
      'دارة المالية',
      'DERAYAH',
      '1010123456',
      'verified',
      10000000,
      10000000,
      'active',
      now(),
      now()
    );
    
    RAISE NOTICE 'Created Derayah Financial company';
  ELSE
    RAISE NOTICE 'Derayah Financial company already exists';
  END IF;
END;
$$;

-- 2. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_user_id ON company_users(user_id);
CREATE INDEX IF NOT EXISTS idx_company_users_company_id ON company_users(company_id);
CREATE INDEX IF NOT EXISTS idx_employees_user_id ON employees(user_id);

-- 3. Simplify RLS policies
DROP POLICY IF EXISTS "Company admins can view own company" ON companies;
DROP POLICY IF EXISTS "Company admins can update own company" ON companies;
DROP POLICY IF EXISTS "Users can view own company associations" ON company_users;
DROP POLICY IF EXISTS "Super admins can add company users" ON company_users;
DROP POLICY IF EXISTS "Super admins can update company users" ON company_users;
DROP POLICY IF EXISTS "Super admins can delete company users" ON company_users;

-- Create simpler policies
CREATE POLICY "Authenticated users can view companies"
  ON companies FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can view company users"
  ON company_users FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can manage company users"
  ON company_users FOR ALL TO authenticated
  USING (true);

-- 4. Create a simple user_roles view
DROP VIEW IF EXISTS user_roles;

CREATE VIEW user_roles AS
SELECT 
  cu.user_id,
  '' as email, -- Will be filled by application
  cu.company_id,
  cu.role,
  cu.is_active,
  CASE 
    WHEN cu.role = 'super_admin' THEN 'super_admin'
    WHEN cu.role IN ('hr_admin', 'finance_admin', 'legal_admin') THEN 'company_admin'
    WHEN EXISTS (SELECT 1 FROM employees e WHERE e.user_id = cu.user_id) THEN 'employee'
    ELSE 'unknown'
  END as user_type
FROM company_users cu
WHERE cu.is_active = true;

-- 5. Test the setup
SELECT 
  '=== SETUP COMPLETE ===' as info;

SELECT 
  'Companies' as table_name,
  count(*) as record_count
FROM companies
UNION ALL
SELECT 
  'Company Users' as table_name,
  count(*) as record_count
FROM company_users
UNION ALL
SELECT 
  'Employees' as table_name,
  count(*) as record_count
FROM employees;
