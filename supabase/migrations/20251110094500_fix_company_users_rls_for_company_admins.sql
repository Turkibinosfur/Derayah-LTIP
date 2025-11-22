/*
  # Fix Company Users RLS for Company Admin Visibility

  After the SaaS split, company_admin users could no longer see their own
  `company_users` record, which prevented the frontend from resolving an
  active company (`getCurrentCompanyId` returned null).

  This migration tightens the SELECT policy so that any authenticated user can
  see rows where they are the linked `user_id`, while still allowing super_admins
  to view all rows for their companies.
*/

DO $block$
BEGIN
  -- Clean up older view policies that may conflict
  DROP POLICY IF EXISTS "Users can view company user associations" ON company_users;
  DROP POLICY IF EXISTS "Company users can view company users" ON company_users;
  DROP POLICY IF EXISTS "Authenticated users can view company users" ON company_users;
  DROP POLICY IF EXISTS "Users can view their company association" ON company_users;
  DROP POLICY IF EXISTS "Super admins can add company users" ON company_users;
  DROP POLICY IF EXISTS "Super admins can update company users" ON company_users;
  DROP POLICY IF EXISTS "Super admins can delete company users" ON company_users;
  DROP FUNCTION IF EXISTS public.is_super_admin_for_company(uuid);
  DROP TRIGGER IF EXISTS trg_company_users_super_admin_membership ON company_users;
  DROP FUNCTION IF EXISTS public.maintain_company_super_admin_membership();
END;
$block$;

CREATE TABLE IF NOT EXISTS company_super_admin_memberships (
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (company_id, user_id)
);

ALTER TABLE company_super_admin_memberships DISABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.touch_company_super_admin_membership()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    DELETE FROM company_super_admin_memberships
    WHERE company_id = OLD.company_id
      AND user_id = OLD.user_id;
    RETURN OLD;
  END IF;

  IF NEW.role = 'super_admin' AND COALESCE(NEW.is_active, true) THEN
    INSERT INTO company_super_admin_memberships (company_id, user_id, created_at, updated_at)
    VALUES (NEW.company_id, NEW.user_id, COALESCE(NEW.created_at, now()), now())
    ON CONFLICT (company_id, user_id) DO UPDATE
      SET updated_at = now();
  ELSE
    DELETE FROM company_super_admin_memberships
    WHERE company_id = NEW.company_id
      AND user_id = NEW.user_id;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$function$;

CREATE TRIGGER trg_company_users_super_admin_membership
AFTER INSERT OR UPDATE OR DELETE ON company_users
FOR EACH ROW EXECUTE FUNCTION public.touch_company_super_admin_membership();

DO $block$
BEGIN
  CREATE POLICY "Users can view their company association"
    ON company_users
    FOR SELECT
    TO authenticated
    USING (
      user_id = auth.uid()
      OR EXISTS (
        SELECT 1
        FROM company_super_admin_memberships m
        WHERE m.company_id = company_users.company_id
          AND m.user_id = auth.uid()
      )
    );

  CREATE POLICY "Super admins can add company users"
    ON company_users
    FOR INSERT
    TO authenticated
    WITH CHECK (
      EXISTS (
        SELECT 1
        FROM company_super_admin_memberships m
        WHERE m.company_id = company_users.company_id
          AND m.user_id = auth.uid()
      )
    );

  CREATE POLICY "Super admins can update company users"
    ON company_users
    FOR UPDATE
    TO authenticated
    USING (
      EXISTS (
        SELECT 1
        FROM company_super_admin_memberships m
        WHERE m.company_id = company_users.company_id
          AND m.user_id = auth.uid()
      )
    );

  CREATE POLICY "Super admins can delete company users"
    ON company_users
    FOR DELETE
    TO authenticated
    USING (
      EXISTS (
        SELECT 1
        FROM company_super_admin_memberships m
        WHERE m.company_id = company_users.company_id
          AND m.user_id = auth.uid()
      )
    );
END;
$block$;
