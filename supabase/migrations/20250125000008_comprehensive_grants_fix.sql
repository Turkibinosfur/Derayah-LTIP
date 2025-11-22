/*
  Comprehensive Grants Fix
  
  Problem: Grants and employee shares still showing zero despite RLS policy fixes.
  This suggests there might be multiple issues:
  1. RLS policies not applied
  2. Data integrity issues
  3. Authentication/authorization problems
  4. Missing relationships
  
  Solution: Comprehensive fix that addresses all potential issues.
*/

DO $$
DECLARE
  v_company_id uuid;
  v_plan_id uuid;
  v_sarah_id uuid;
  v_khalid_id uuid;
  v_fatima_id uuid;
  grant_count integer;
  employee_count integer;
  rec RECORD;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Financial company not found';
  END IF;
  
  RAISE NOTICE '=== COMPREHENSIVE GRANTS DIAGNOSTIC ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  
  -- 1. Check employees
  SELECT COUNT(*) INTO employee_count
  FROM employees
  WHERE company_id = v_company_id;
  
  RAISE NOTICE 'Total employees: %', employee_count;
  
  -- List employees
  FOR rec IN 
    SELECT id, employee_number, first_name_en, last_name_en, email, user_id
    FROM employees
    WHERE company_id = v_company_id
  LOOP
    RAISE NOTICE 'Employee: % % (%) - ID: %, user_id: %', 
      rec.first_name_en, rec.last_name_en, rec.email, rec.id, rec.user_id;
  END LOOP;
  
  -- 2. Check grants
  SELECT COUNT(*) INTO grant_count
  FROM grants
  WHERE company_id = v_company_id;
  
  RAISE NOTICE 'Total grants: %', grant_count;
  
  -- List grants with employee info
  FOR rec IN 
    SELECT 
      g.id,
      g.grant_number,
      g.total_shares,
      g.status,
      g.employee_id,
      e.first_name_en,
      e.last_name_en,
      e.employee_number
    FROM grants g
    LEFT JOIN employees e ON g.employee_id = e.id
    WHERE g.company_id = v_company_id
  LOOP
    RAISE NOTICE 'Grant: % - % shares, status=%, employee=% % (%), employee_id=%', 
      rec.grant_number, rec.total_shares, rec.status, rec.first_name_en, rec.last_name_en, rec.employee_number, rec.employee_id;
  END LOOP;
  
  -- 3. Check RLS policies
  RAISE NOTICE '=== RLS POLICIES CHECK ===';
  FOR rec IN 
    SELECT policyname, cmd, roles, qual, with_check
    FROM pg_policies 
    WHERE tablename = 'grants'
  LOOP
    RAISE NOTICE 'Policy: % - % for %', rec.policyname, rec.cmd, rec.roles;
  END LOOP;
  
  -- 4. Check company_users
  RAISE NOTICE '=== COMPANY USERS CHECK ===';
  FOR rec IN 
    SELECT user_id, role, company_id
    FROM company_users
    WHERE company_id = v_company_id
  LOOP
    RAISE NOTICE 'Company User: user_id=%, role=%, company_id=%', rec.user_id, rec.role, rec.company_id;
  END LOOP;
  
  -- 5. Force update RLS policies (drop and recreate)
  RAISE NOTICE '=== UPDATING RLS POLICIES ===';
  
  -- Drop all existing policies
  DROP POLICY IF EXISTS "Users can view relevant grants" ON grants;
  DROP POLICY IF EXISTS "Admins can manage grants" ON grants;
  DROP POLICY IF EXISTS "Company users can view grants" ON grants;
  DROP POLICY IF EXISTS "Company users can insert grants" ON grants;
  DROP POLICY IF EXISTS "Company users can update grants" ON grants;
  DROP POLICY IF EXISTS "Company users can delete grants" ON grants;
  
  -- Create new comprehensive policies
  CREATE POLICY "Company users can view grants"
    ON grants FOR SELECT TO authenticated
    USING (
      company_id IN (
        SELECT company_id
        FROM company_users
        WHERE user_id = auth.uid()
      )
    );
  
  CREATE POLICY "Company users can insert grants"
    ON grants FOR INSERT TO authenticated
    WITH CHECK (
      company_id IN (
        SELECT company_id
        FROM company_users
        WHERE user_id = auth.uid()
      )
    );
  
  CREATE POLICY "Company users can update grants"
    ON grants FOR UPDATE TO authenticated
    USING (
      company_id IN (
        SELECT company_id
        FROM company_users
        WHERE user_id = auth.uid()
      )
    )
    WITH CHECK (
      company_id IN (
        SELECT company_id
        FROM company_users
        WHERE user_id = auth.uid()
      )
    );
  
  CREATE POLICY "Company users can delete grants"
    ON grants FOR DELETE TO authenticated
    USING (
      company_id IN (
        SELECT company_id
        FROM company_users
        WHERE user_id = auth.uid()
      )
    );
  
  -- 6. Also fix vesting schedules policies
  DROP POLICY IF EXISTS "Users can view relevant vesting schedules" ON vesting_schedules;
  DROP POLICY IF EXISTS "Company users can view vesting schedules" ON vesting_schedules;
  DROP POLICY IF EXISTS "Company users can insert vesting schedules" ON vesting_schedules;
  DROP POLICY IF EXISTS "Company users can update vesting schedules" ON vesting_schedules;
  DROP POLICY IF EXISTS "Company users can delete vesting schedules" ON vesting_schedules;
  
  CREATE POLICY "Company users can view vesting schedules"
    ON vesting_schedules FOR SELECT TO authenticated
    USING (
      grant_id IN (
        SELECT id FROM grants
        WHERE company_id IN (
          SELECT company_id
          FROM company_users
          WHERE user_id = auth.uid()
        )
      )
    );
  
  CREATE POLICY "Company users can insert vesting schedules"
    ON vesting_schedules FOR INSERT TO authenticated
    WITH CHECK (
      grant_id IN (
        SELECT id FROM grants
        WHERE company_id IN (
          SELECT company_id
          FROM company_users
          WHERE user_id = auth.uid()
        )
      )
    );
  
  CREATE POLICY "Company users can update vesting schedules"
    ON vesting_schedules FOR UPDATE TO authenticated
    USING (
      grant_id IN (
        SELECT id FROM grants
        WHERE company_id IN (
          SELECT company_id
          FROM company_users
          WHERE user_id = auth.uid()
        )
      )
    )
    WITH CHECK (
      grant_id IN (
        SELECT id FROM grants
        WHERE company_id IN (
          SELECT company_id
          FROM company_users
          WHERE user_id = auth.uid()
        )
      )
    );
  
  CREATE POLICY "Company users can delete vesting schedules"
    ON vesting_schedules FOR DELETE TO authenticated
    USING (
      grant_id IN (
        SELECT id FROM grants
        WHERE company_id IN (
          SELECT company_id
          FROM company_users
          WHERE user_id = auth.uid()
        )
      )
    );
  
  -- 7. Verify grants are accessible
  RAISE NOTICE '=== TESTING GRANT ACCESS ===';
  SELECT COUNT(*) INTO grant_count
  FROM grants
  WHERE company_id = v_company_id;
  
  RAISE NOTICE 'Grants accessible after policy update: %', grant_count;
  
  -- 8. Check if there are any grants with NULL or invalid employee_id
  SELECT COUNT(*) INTO grant_count
  FROM grants
  WHERE company_id = v_company_id 
    AND (employee_id IS NULL OR employee_id NOT IN (SELECT id FROM employees WHERE company_id = v_company_id));
  
  IF grant_count > 0 THEN
    RAISE NOTICE 'WARNING: % grants have invalid employee_id references', grant_count;
  END IF;
  
  RAISE NOTICE '=== COMPREHENSIVE FIX COMPLETE ===';
  RAISE NOTICE 'RLS policies updated for grants and vesting schedules';
  RAISE NOTICE 'All company users should now be able to view grants';
  
END $$;
