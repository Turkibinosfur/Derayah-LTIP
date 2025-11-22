/*
  # Expand Company Admin Permissions

  Adjust RLS policies so `company_admin` users can view and manage core company
  data (employees, grants, vesting schedules, portfolios, audit logs).
*/

-- Employees: allow company_admin to view and manage
DROP POLICY IF EXISTS "Employees can view own data" ON employees;
DROP POLICY IF EXISTS "Company admins can view employees" ON employees;
DROP POLICY IF EXISTS "Company admins can view company employees" ON employees;
DROP POLICY IF EXISTS "HR admins can manage employees" ON employees;
DROP POLICY IF EXISTS "Admins can manage employees" ON employees;
CREATE POLICY "Employees can view own data"
  ON employees FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
        AND role IN ('super_admin', 'company_admin', 'hr_admin', 'finance_admin')
    )
  );

CREATE POLICY "Admins can manage employees"
  ON employees FOR ALL TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
        AND role IN ('super_admin', 'company_admin', 'hr_admin')
    )
  );

-- Portfolios: allow company_admin to view
DROP POLICY IF EXISTS "Users can view relevant portfolios" ON portfolios;
DROP POLICY IF EXISTS "Employees can view own portfolios" ON portfolios;
DROP POLICY IF EXISTS "Company admins can view company portfolios" ON portfolios;
CREATE POLICY "Users can view relevant portfolios"
  ON portfolios FOR SELECT TO authenticated
  USING (
    employee_id IN (SELECT id FROM employees WHERE user_id = auth.uid())
    OR company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
        AND role IN ('super_admin', 'company_admin', 'finance_admin')
    )
  );

-- Grants: allow company_admin to view and manage
DROP POLICY IF EXISTS "Users can view relevant grants" ON grants;
DROP POLICY IF EXISTS "Employees can view own grants" ON grants;
DROP POLICY IF EXISTS "Company admins can view company grants" ON grants;
DROP POLICY IF EXISTS "Admins can manage grants" ON grants;
DROP POLICY IF EXISTS "HR admins can manage grants" ON grants;
CREATE POLICY "Users can view relevant grants"
  ON grants FOR SELECT TO authenticated
  USING (
    employee_id IN (SELECT id FROM employees WHERE user_id = auth.uid())
    OR company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
        AND role IN ('super_admin', 'company_admin', 'hr_admin', 'finance_admin')
    )
  );

CREATE POLICY "Admins can manage grants"
  ON grants FOR ALL TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
        AND role IN ('super_admin', 'company_admin', 'hr_admin')
    )
  );

-- Vesting schedules: allow company_admin to view
DROP POLICY IF EXISTS "Users can view relevant vesting schedules" ON vesting_schedules;
DROP POLICY IF EXISTS "Company admins can view relevant vesting schedules" ON vesting_schedules;
CREATE POLICY "Users can view relevant vesting schedules"
  ON vesting_schedules FOR SELECT TO authenticated
  USING (
    grant_id IN (
      SELECT g.id FROM grants g
      JOIN employees e ON g.employee_id = e.id
      WHERE e.user_id = auth.uid()
    )
    OR grant_id IN (
      SELECT g.id FROM grants g
      WHERE g.company_id IN (
        SELECT company_id FROM company_users
        WHERE user_id = auth.uid()
          AND role IN ('super_admin', 'company_admin', 'hr_admin', 'finance_admin')
      )
    )
  );

-- Audit logs: allow company_admin to view
DROP POLICY IF EXISTS "Company admins can view own audit logs" ON audit_logs;
DROP POLICY IF EXISTS "Company admins can view audit logs" ON audit_logs;
CREATE POLICY "Company admins can view own audit logs"
  ON audit_logs FOR SELECT TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
        AND role IN ('super_admin', 'company_admin', 'finance_admin', 'legal_admin')
    )
  );

-- Ensure seeded admin roles have expanded UI permissions
UPDATE company_users
SET permissions = COALESCE(permissions, '{}'::jsonb) || jsonb_build_object(
  'dashboard', true,
  'users', true,
  'employees', true,
  'ltip_pools', true,
  'plans', true,
  'vesting_schedules', true,
  'vesting_events', true,
  'transfers', true,
  'performance_metrics', true,
  'grants', true,
  'documents', true,
  'cap_table', true,
  'portfolio', true,
  'settings', true
)
WHERE role = 'super_admin';

UPDATE company_users
SET permissions = COALESCE(permissions, '{}'::jsonb) || jsonb_build_object(
  'dashboard', true,
  'users', true,
  'employees', true,
  'ltip_pools', true,
  'plans', true,
  'vesting_schedules', true,
  'vesting_events', true,
  'transfers', true,
  'performance_metrics', true,
  'grants', true,
  'documents', true,
  'cap_table', true,
  'portfolio', true,
  'settings', true
)
WHERE role = 'company_admin';

UPDATE company_users
SET permissions = COALESCE(permissions, '{}'::jsonb) || jsonb_build_object(
  'dashboard', true,
  'employees', true,
  'ltip_pools', true,
  'plans', true,
  'vesting_schedules', true,
  'vesting_events', true,
  'transfers', true,
  'performance_metrics', true,
  'grants', true,
  'documents', true,
  'cap_table', true,
  'portfolio', true
)
WHERE role = 'hr_admin';

UPDATE company_users
SET permissions = COALESCE(permissions, '{}'::jsonb) || jsonb_build_object(
  'dashboard', true,
  'employees', true,
  'ltip_pools', true,
  'plans', true,
  'vesting_schedules', true,
  'vesting_events', true,
  'transfers', true,
  'performance_metrics', true,
  'grants', true,
  'documents', true,
  'cap_table', true,
  'portfolio', true,
  'settings', true
)
WHERE role = 'finance_admin';

UPDATE company_users
SET permissions = COALESCE(permissions, '{}'::jsonb) || jsonb_build_object(
  'dashboard', true,
  'employees', true,
  'plans', true,
  'vesting_schedules', true,
  'vesting_events', true,
  'performance_metrics', true,
  'grants', true,
  'documents', true,
  'cap_table', true,
  'portfolio', true
)
WHERE role = 'legal_admin';

