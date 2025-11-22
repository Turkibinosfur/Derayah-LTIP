/*
  Allow Company Admin to Manage Employee Financial Information
  
  Problem: The RLS policies on employee_financial_info table only allow 
  super_admin, hr_admin, and finance_admin roles to create/update financial info.
  Company admins (company_admin role) like admin@derayah.com cannot update 
  employee financial information, causing "Failed to save financial information" errors.
  
  Solution: Update all RLS policies on employee_financial_info to include 
  company_admin role alongside the existing admin roles.
*/

-- Drop and recreate SELECT policy to include company_admin
DROP POLICY IF EXISTS "Employees can view own financial info" ON employee_financial_info;

CREATE POLICY "Employees can view own financial info" ON employee_financial_info
  FOR SELECT USING (
    -- Employee can see their own financial info
    employee_id IN (
      SELECT id FROM employees WHERE user_id = auth.uid()
    )
    OR
    -- Company admins (including company_admin) can see financial info for employees in their company
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND role IN ('super_admin', 'hr_admin', 'finance_admin', 'company_admin')
    )
  );

-- Drop and recreate INSERT policy to include company_admin
DROP POLICY IF EXISTS "Company admins can create financial info" ON employee_financial_info;

CREATE POLICY "Company admins can create financial info" ON employee_financial_info
  FOR INSERT WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND role IN ('super_admin', 'hr_admin', 'finance_admin', 'company_admin')
    )
    AND employee_id IN (
      SELECT id FROM employees WHERE company_id = employee_financial_info.company_id
    )
  );

-- Drop and recreate UPDATE policy to include company_admin
DROP POLICY IF EXISTS "Users can update financial info" ON employee_financial_info;

CREATE POLICY "Users can update financial info" ON employee_financial_info
  FOR UPDATE USING (
    -- Company admins (including company_admin) can update any financial info in their company
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND role IN ('super_admin', 'hr_admin', 'finance_admin', 'company_admin')
    )
    OR
    -- Employees can update their own financial info if status is pending
    (
      employee_id IN (
        SELECT id FROM employees WHERE user_id = auth.uid()
      )
      AND account_status = 'pending'
    )
  );

-- Note: DELETE policy remains unchanged - only super_admin can delete for compliance/audit reasons
