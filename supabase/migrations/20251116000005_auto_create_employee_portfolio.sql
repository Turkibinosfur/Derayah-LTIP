/*
  Auto-Create Employee Vested Portfolio
  
  Problem: When employees are created, they don't automatically get a vested portfolio.
  This causes "Employee vested portfolio not found" errors when trying to transfer shares.
  
  Solution: 
  1. Create a trigger function that automatically creates an employee_vested portfolio
     when a new employee is created
  2. Backfill portfolios for existing employees that don't have one
*/

-- 1. Function to create employee vested portfolio
CREATE OR REPLACE FUNCTION create_employee_vested_portfolio()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_portfolio_id uuid;
  v_portfolio_number text;
BEGIN
  -- Skip if portfolio already exists
  IF EXISTS (
    SELECT 1 FROM portfolios 
    WHERE employee_id = NEW.id 
    AND portfolio_type = 'employee_vested'
  ) THEN
    RETURN NEW;
  END IF;

  -- Generate portfolio number from employee number
  v_portfolio_number := 'PORT-EMPLOYEE-' || COALESCE(NEW.employee_number, SUBSTRING(NEW.id::text, 1, 8));

  -- Create employee vested portfolio
  INSERT INTO portfolios (
    id,
    portfolio_type,
    company_id,
    employee_id,
    total_shares,
    available_shares,
    locked_shares,
    portfolio_number,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    'employee_vested',
    NEW.company_id,
    NEW.id,
    0,  -- Initially 0 shares
    0,  -- Initially 0 available
    0,  -- Initially 0 locked
    v_portfolio_number,
    now(),
    now()
  ) RETURNING id INTO v_portfolio_id;
  
  RAISE NOTICE 'Created employee vested portfolio % for employee % (%)', 
    v_portfolio_id, NEW.first_name_en || ' ' || NEW.last_name_en, NEW.employee_number;
  
  RETURN NEW;
END;
$$;

-- 2. Create trigger to auto-create portfolio when employee is created
DROP TRIGGER IF EXISTS trigger_create_employee_portfolio ON employees;
CREATE TRIGGER trigger_create_employee_portfolio
  AFTER INSERT ON employees
  FOR EACH ROW
  EXECUTE FUNCTION create_employee_vested_portfolio();

-- 3. Backfill portfolios for existing employees that don't have one
DO $$
DECLARE
  employee_rec RECORD;
  v_portfolio_id uuid;
  v_portfolio_number text;
  v_created_count integer := 0;
BEGIN
  RAISE NOTICE '=== Starting portfolio backfill for existing employees ===';
  
  FOR employee_rec IN 
    SELECT 
      e.id,
      e.company_id,
      e.employee_number,
      e.first_name_en,
      e.last_name_en
    FROM employees e
    WHERE NOT EXISTS (
      SELECT 1 FROM portfolios 
      WHERE portfolios.employee_id = e.id 
      AND portfolios.portfolio_type = 'employee_vested'
    )
  LOOP
    -- Generate portfolio number
    v_portfolio_number := 'PORT-EMPLOYEE-' || COALESCE(employee_rec.employee_number, SUBSTRING(employee_rec.id::text, 1, 8));

    -- Create portfolio
    INSERT INTO portfolios (
      id,
      portfolio_type,
      company_id,
      employee_id,
      total_shares,
      available_shares,
      locked_shares,
      portfolio_number,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      'employee_vested',
      employee_rec.company_id,
      employee_rec.id,
      0,
      0,
      0,
      v_portfolio_number,
      now(),
      now()
    ) RETURNING id INTO v_portfolio_id;
    
    v_created_count := v_created_count + 1;
    RAISE NOTICE 'Created portfolio for existing employee: % % (ID: %, Portfolio: %)', 
      employee_rec.first_name_en, employee_rec.last_name_en, employee_rec.id, v_portfolio_number;
  END LOOP;
  
  RAISE NOTICE '=== Backfill complete: Created % portfolio(s) for existing employees ===', v_created_count;
END;
$$;

-- 4. Add INSERT policy for portfolios (to allow creating employee portfolios)
DROP POLICY IF EXISTS "Company admins can create portfolios" ON portfolios;
CREATE POLICY "Company admins can create portfolios"
  ON portfolios FOR INSERT TO authenticated
  WITH CHECK (
    -- Company admins can create company reserved portfolios
    (
      portfolio_type = 'company_reserved'
      AND employee_id IS NULL
      AND company_id IN (
        SELECT company_id FROM company_users
        WHERE user_id = auth.uid()
        AND role IN ('super_admin', 'company_admin', 'hr_admin', 'finance_admin')
      )
    )
    OR
    -- Company admins can create employee portfolios for employees in their company
    (
      portfolio_type = 'employee_vested'
      AND employee_id IS NOT NULL
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
    OR
    -- Employees can create their own portfolio (though trigger should handle this)
    (
      portfolio_type = 'employee_vested'
      AND employee_id IN (SELECT id FROM employees WHERE user_id = auth.uid())
    )
  );

-- 5. Verify portfolios were created
SELECT 
  '=== VERIFICATION: Employee Portfolios ===' as info;

SELECT 
  e.employee_number,
  e.first_name_en || ' ' || e.last_name_en as employee_name,
  e.email,
  p.portfolio_number,
  p.total_shares,
  p.available_shares,
  p.locked_shares,
  CASE 
    WHEN p.id IS NULL THEN '❌ Missing'
    ELSE '✅ Exists'
  END as portfolio_status
FROM employees e
LEFT JOIN portfolios p ON p.employee_id = e.id AND p.portfolio_type = 'employee_vested'
ORDER BY e.employee_number;

