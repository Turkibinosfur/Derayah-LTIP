/*
  Debug Grants Issue
  
  Problem: 
  1. Sarah Al-Mansouri has a grant with 50,000 shares but shows zero in incentive plans
  2. Available shares shows 950,000 instead of actual available shares
  
  Solution: Debug the grants data and fix the calculation
*/

DO $$
DECLARE
  v_company_id uuid;
  v_plan_id uuid;
  total_granted numeric;
  rec RECORD;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Financial company not found';
  END IF;
  
  -- Get the plan ID
  SELECT id INTO v_plan_id
  FROM incentive_plans
  WHERE company_id = v_company_id 
    AND plan_name_en = 'Derayah Employee Stock Plan 2025';
  
  IF v_plan_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Employee Stock Plan 2025 not found';
  END IF;
  
  RAISE NOTICE '=== DEBUGGING GRANTS ISSUE ===';
  RAISE NOTICE 'Company ID: %', v_company_id;
  RAISE NOTICE 'Plan ID: %', v_plan_id;
  
  -- 1. Check Sarah's employee record
  RAISE NOTICE '=== SARAH AL-MANSOURI EMPLOYEE RECORD ===';
  FOR rec IN 
    SELECT 
      id,
      first_name_en,
      last_name_en,
      employee_number,
      employment_status
    FROM employees
    WHERE company_id = v_company_id 
      AND (first_name_en ILIKE '%sarah%' OR last_name_en ILIKE '%mansouri%')
  LOOP
    RAISE NOTICE 'Employee: % % (ID: %, Number: %, Status: %)', 
      rec.first_name_en, rec.last_name_en, rec.id, rec.employee_number, rec.employment_status;
  END LOOP;
  
  -- 2. Check Sarah's grants
  RAISE NOTICE '=== SARAH AL-MANSOURI GRANTS ===';
  FOR rec IN 
    SELECT 
      g.id,
      g.grant_number,
      g.total_shares,
      g.status,
      g.plan_id,
      e.first_name_en,
      e.last_name_en
    FROM grants g
    JOIN employees e ON g.employee_id = e.id
    WHERE g.company_id = v_company_id 
      AND (e.first_name_en ILIKE '%sarah%' OR e.last_name_en ILIKE '%mansouri%')
  LOOP
    RAISE NOTICE 'Grant: % - % % - % shares (Status: %, Plan: %)', 
      rec.grant_number, rec.first_name_en, rec.last_name_en, rec.total_shares, rec.status, rec.plan_id;
  END LOOP;
  
  -- 3. Check all grants for the plan
  RAISE NOTICE '=== ALL GRANTS FOR DERAYAH EMPLOYEE STOCK PLAN 2025 ===';
  FOR rec IN 
    SELECT 
      g.id,
      g.grant_number,
      g.total_shares,
      g.status,
      e.first_name_en,
      e.last_name_en
    FROM grants g
    JOIN employees e ON g.employee_id = e.id
    WHERE g.plan_id = v_plan_id
  LOOP
    RAISE NOTICE 'Grant: % - % % - % shares (Status: %)', 
      rec.grant_number, rec.first_name_en, rec.last_name_en, rec.total_shares, rec.status;
  END LOOP;
  
  -- 4. Calculate total granted shares for the plan
  SELECT COALESCE(SUM(total_shares), 0)
  INTO total_granted
  FROM grants
  WHERE plan_id = v_plan_id 
    AND status = 'active';
  
  RAISE NOTICE 'Total Granted Shares (Active): %', total_granted;
  
  -- 5. Check plan details
  RAISE NOTICE '=== PLAN DETAILS ===';
  FOR rec IN 
    SELECT 
      plan_name_en,
      total_shares_allocated,
      shares_granted,
      shares_available,
      status
    FROM incentive_plans
    WHERE id = v_plan_id
  LOOP
    RAISE NOTICE 'Plan: %', rec.plan_name_en;
    RAISE NOTICE '  Total Allocated: %', rec.total_shares_allocated;
    RAISE NOTICE '  Shares Granted (stored): %', rec.shares_granted;
    RAISE NOTICE '  Shares Available (stored): %', rec.shares_available;
    RAISE NOTICE '  Status: %', rec.status;
    
    -- Calculate what the available should be
    RAISE NOTICE '  Calculated Available (Total - Granted): %', rec.total_shares_allocated - total_granted;
  END LOOP;
  
  -- 6. Check if there are any grants with different status
  RAISE NOTICE '=== GRANTS BY STATUS ===';
  FOR rec IN 
    SELECT 
      status,
      COUNT(*) as count,
      SUM(total_shares) as total_shares
    FROM grants
    WHERE plan_id = v_plan_id
    GROUP BY status
  LOOP
    RAISE NOTICE 'Status: % - Count: %, Total Shares: %', 
      rec.status, rec.count, rec.total_shares;
  END LOOP;
  
  RAISE NOTICE '=== DEBUGGING COMPLETE ===';
  
END $$;
