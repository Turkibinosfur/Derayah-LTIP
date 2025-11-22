/*
  Fix Portfolios RLS Policy for Company Admin
  
  Problem: The portfolios RLS policy might not properly allow company_admin users
  to view company reserved portfolios (where employee_id IS NULL). This causes
  "Company reserved portfolio not found" errors when trying to transfer shares.
  
  Solution: Update the portfolios RLS policy to explicitly handle company reserved
  portfolios (employee_id IS NULL) and ensure company_admin can access them.
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view relevant portfolios" ON portfolios;
DROP POLICY IF EXISTS "Employees can view own portfolios" ON portfolios;
DROP POLICY IF EXISTS "Company admins can view company portfolios" ON portfolios;

-- Create a comprehensive policy that handles:
-- 1. Employees viewing their own portfolios (employee_id matches their user_id)
-- 2. Company admins viewing company reserved portfolios (employee_id IS NULL)
-- 3. Company admins viewing employee portfolios in their company
CREATE POLICY "Users can view relevant portfolios"
  ON portfolios FOR SELECT TO authenticated
  USING (
    -- Employees can view their own portfolios
    (
      employee_id IS NOT NULL
      AND employee_id IN (SELECT id FROM employees WHERE user_id = auth.uid())
    )
    OR 
    -- Company admins can view company reserved portfolios (employee_id IS NULL)
    (
      employee_id IS NULL
      AND company_id IN (
        SELECT company_id FROM company_users
        WHERE user_id = auth.uid()
        AND role IN ('super_admin', 'company_admin', 'hr_admin', 'finance_admin')
      )
    )
    OR
    -- Company admins can view employee portfolios in their company
    (
      employee_id IS NOT NULL
      AND company_id IN (
        SELECT company_id FROM company_users
        WHERE user_id = auth.uid()
        AND role IN ('super_admin', 'company_admin', 'hr_admin', 'finance_admin')
      )
      AND EXISTS (
        SELECT 1 FROM employees
        WHERE employees.id = portfolios.employee_id
        AND employees.company_id = portfolios.company_id
      )
    )
  );

-- Verify the policy was created
SELECT 
  '=== VERIFICATION: Portfolios RLS Policies ===' as info;

SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'portfolios'
ORDER BY policyname;

