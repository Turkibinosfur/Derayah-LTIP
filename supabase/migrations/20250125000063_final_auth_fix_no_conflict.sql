/*
  # Final Auth Fix - No ON CONFLICT Issues
  
  This migration completely avoids ON CONFLICT clauses and uses conditional logic instead.
  This should resolve all constraint-related errors.
*/

-- 1. Ensure company exists (using conditional logic)
DO $$
DECLARE
  v_company_id uuid;
BEGIN
  -- Check if company exists
  SELECT id INTO v_company_id 
  FROM companies 
  WHERE company_name_en = 'Derayah Financial';
  
  -- If company doesn't exist, create it
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
    ) RETURNING id INTO v_company_id;
    
    RAISE NOTICE 'Company created with ID: %', v_company_id;
  ELSE
    RAISE NOTICE 'Company already exists with ID: %', v_company_id;
  END IF;
END;
$$;

-- 2. Create performance indexes
CREATE INDEX IF NOT EXISTS idx_company_users_user_id ON company_users(user_id);
CREATE INDEX IF NOT EXISTS idx_company_users_company_id ON company_users(company_id);
CREATE INDEX IF NOT EXISTS idx_employees_user_id ON employees(user_id);
CREATE INDEX IF NOT EXISTS idx_employees_company_id ON employees(company_id);

-- 3. Create simplified RLS policies
DROP POLICY IF EXISTS "Company users can view companies" ON companies;
DROP POLICY IF EXISTS "Company users can view company users" ON company_users;

CREATE POLICY "Company users can view companies" ON companies
  FOR SELECT USING (true);

CREATE POLICY "Company users can view company users" ON company_users
  FOR SELECT USING (true);

-- 4. Create a simple function to get company ID
CREATE OR REPLACE FUNCTION get_company_id()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_company_id uuid;
BEGIN
  SELECT id INTO v_company_id 
  FROM companies 
  WHERE company_name_en = 'Derayah Financial'
  LIMIT 1;
  
  RETURN v_company_id;
END;
$$;

-- 5. Create a function to check if admin user is linked
CREATE OR REPLACE FUNCTION is_admin_linked(p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count integer;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM company_users cu
  JOIN companies c ON cu.company_id = c.id
  WHERE cu.user_id = p_user_id 
    AND cu.role = 'super_admin'
    AND c.company_name_en = 'Derayah Financial';
  
  RETURN v_count > 0;
END;
$$;

-- 6. Create a function to link admin user (without ON CONFLICT)
CREATE OR REPLACE FUNCTION link_admin_user(p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_company_id uuid;
  v_existing_count integer;
BEGIN
  -- Get company ID
  v_company_id := get_company_id();
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Company not found';
  END IF;
  
  -- Check if user is already linked
  SELECT COUNT(*) INTO v_existing_count
  FROM company_users
  WHERE user_id = p_user_id AND company_id = v_company_id;
  
  -- If not linked, create the link
  IF v_existing_count = 0 THEN
    INSERT INTO company_users (
      company_id,
      user_id,
      role,
      is_active,
      created_at
    ) VALUES (
      v_company_id,
      p_user_id,
      'super_admin',
      true,
      now()
    );
    
    RAISE NOTICE 'Admin user linked successfully';
    RETURN true;
  ELSE
    RAISE NOTICE 'Admin user already linked';
    RETURN true;
  END IF;
END;
$$;

-- 7. Create a function to verify admin setup
CREATE OR REPLACE FUNCTION verify_admin_setup()
RETURNS TABLE(
  company_exists boolean,
  admin_linked boolean,
  company_id uuid,
  admin_user_id uuid
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_company_id uuid;
  v_admin_user_id uuid;
  v_company_exists boolean := false;
  v_admin_linked boolean := false;
BEGIN
  -- Check if company exists
  SELECT id INTO v_company_id 
  FROM companies 
  WHERE company_name_en = 'Derayah Financial';
  
  v_company_exists := (v_company_id IS NOT NULL);
  
  -- Check if admin is linked
  IF v_company_exists THEN
    SELECT cu.user_id INTO v_admin_user_id
    FROM company_users cu
    WHERE cu.company_id = v_company_id 
      AND cu.role = 'super_admin'
      AND cu.is_active = true
    LIMIT 1;
    
    v_admin_linked := (v_admin_user_id IS NOT NULL);
  END IF;
  
  RETURN QUERY SELECT v_company_exists, v_admin_linked, v_company_id, v_admin_user_id;
END;
$$;

-- 8. Run verification
SELECT * FROM verify_admin_setup();
