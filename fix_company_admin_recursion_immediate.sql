-- IMMEDIATE FIX: Run this in Supabase SQL Editor to fix infinite recursion
-- This creates a membership table approach (same as super_admin) to avoid recursion

-- Step 1: Create company_admin_memberships table
CREATE TABLE IF NOT EXISTS company_admin_memberships (
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (company_id, user_id)
);

-- Disable RLS on this table
ALTER TABLE company_admin_memberships DISABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_company_admin_memberships_company_id ON company_admin_memberships(company_id);
CREATE INDEX IF NOT EXISTS idx_company_admin_memberships_user_id ON company_admin_memberships(user_id);

-- Step 2: Create trigger function to maintain memberships
CREATE OR REPLACE FUNCTION public.touch_company_admin_membership()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    DELETE FROM company_admin_memberships
    WHERE company_id = OLD.company_id AND user_id = OLD.user_id;
    RETURN OLD;
  END IF;

  IF NEW.role = 'company_admin' AND COALESCE(NEW.is_active, true) THEN
    INSERT INTO company_admin_memberships (company_id, user_id, created_at, updated_at)
    VALUES (NEW.company_id, NEW.user_id, COALESCE(NEW.created_at, now()), now())
    ON CONFLICT (company_id, user_id) DO UPDATE SET updated_at = now();
  ELSE
    DELETE FROM company_admin_memberships
    WHERE company_id = NEW.company_id AND user_id = NEW.user_id;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$function$;

-- Step 3: Create trigger
DROP TRIGGER IF EXISTS trg_company_users_company_admin_membership ON company_users;
CREATE TRIGGER trg_company_users_company_admin_membership
AFTER INSERT OR UPDATE OR DELETE ON company_users
FOR EACH ROW EXECUTE FUNCTION public.touch_company_admin_membership();

-- Step 4: Populate existing data (using SECURITY DEFINER to bypass RLS)
DO $$
BEGIN
  INSERT INTO company_admin_memberships (company_id, user_id, created_at, updated_at)
  SELECT company_id, user_id, created_at, now()
  FROM company_users
  WHERE role = 'company_admin' AND is_active = true
  ON CONFLICT (company_id, user_id) DO NOTHING;
END $$;

-- Step 5: Update the helper function to use membership tables only
DROP FUNCTION IF EXISTS public.is_admin_for_company(uuid);

CREATE OR REPLACE FUNCTION public.is_admin_for_company(p_company_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
  -- Check super_admin membership (no RLS on this table)
  IF EXISTS (
    SELECT 1 FROM company_super_admin_memberships m
    WHERE m.company_id = p_company_id AND m.user_id = auth.uid()
  ) THEN
    RETURN true;
  END IF;
  
  -- Check company_admin membership (no RLS on this table)
  -- This avoids querying company_users which causes infinite recursion
  RETURN EXISTS (
    SELECT 1 FROM company_admin_memberships m
    WHERE m.company_id = p_company_id AND m.user_id = auth.uid()
  );
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.is_admin_for_company(uuid) TO authenticated;

-- Step 6: CRITICAL - Update the UPDATE policy to use the new function
-- Drop the old policy first
DROP POLICY IF EXISTS "Super admins can update company users" ON company_users;
DROP POLICY IF EXISTS "Admins can update company users" ON company_users;

-- Create the new UPDATE policy that uses the membership table function
CREATE POLICY "Admins can update company users"
  ON company_users
  FOR UPDATE
  TO authenticated
  USING (
    public.is_admin_for_company(company_users.company_id)
  );

-- Verify the fix
SELECT 'Fix applied successfully! Company admin memberships created and UPDATE policy updated.' as status;

