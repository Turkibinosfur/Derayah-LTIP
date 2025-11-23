-- Fix companies UPDATE policy to allow all admin roles to update company settings
-- This allows hr_admin, legal_admin, and company_admin roles to update company information
-- including the new brand_color field

DROP POLICY IF EXISTS "Company admins can update own company" ON companies;

CREATE POLICY "Company admins can update own company"
  ON companies FOR UPDATE TO authenticated
  USING (
    id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() 
      AND is_active = true
      AND role IN ('super_admin', 'finance_admin', 'hr_admin', 'legal_admin', 'company_admin')
    )
  );

