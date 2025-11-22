/*
  Summary Check
  
  This migration provides a clear summary of the current state after fixes.
  It will show exactly what's working and what might still need attention.
*/

DO $$
DECLARE
  v_company_id uuid;
  v_plan_id uuid;
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
    AND plan_code = 'DESP-2025-001';
  
  RAISE NOTICE '=== FINAL STATUS SUMMARY ===';
  RAISE NOTICE 'Company: Derayah Financial (%)', v_company_id;
  
  -- Plan status
  FOR rec IN 
    SELECT 
      plan_name_en,
      plan_code,
      total_shares_allocated,
      shares_granted,
      shares_available,
      status
    FROM incentive_plans
    WHERE company_id = v_company_id
  LOOP
    RAISE NOTICE 'Plan: % (%)', rec.plan_name_en, rec.plan_code;
    RAISE NOTICE '  Total Allocated: %', rec.total_shares_allocated;
    RAISE NOTICE '  Shares Granted: %', rec.shares_granted;
    RAISE NOTICE '  Shares Available: %', rec.shares_available;
    RAISE NOTICE '  Status: %', rec.status;
  END LOOP;
  
  -- Employee shares summary
  RAISE NOTICE 'Employee Shares Summary:';
  FOR rec IN 
    SELECT 
      e.first_name_en,
      e.last_name_en,
      e.employee_number,
      COALESCE(SUM(g.total_shares), 0) as total_shares,
      COALESCE(SUM(g.vested_shares), 0) as vested_shares,
      COALESCE(SUM(g.remaining_unvested_shares), 0) as unvested_shares
    FROM employees e
    LEFT JOIN grants g ON e.id = g.employee_id AND g.company_id = v_company_id
    WHERE e.company_id = v_company_id
    GROUP BY e.id, e.first_name_en, e.last_name_en, e.employee_number
    ORDER BY e.employee_number
  LOOP
    RAISE NOTICE '  % % (%): % total, % vested, % unvested', 
      rec.first_name_en, rec.last_name_en, rec.employee_number, 
      rec.total_shares, rec.vested_shares, rec.unvested_shares;
  END LOOP;
  
  -- Grants summary
  RAISE NOTICE 'Grants Summary:';
  FOR rec IN 
    SELECT 
      grant_number,
      total_shares,
      status,
      e.first_name_en,
      e.last_name_en
    FROM grants g
    LEFT JOIN employees e ON g.employee_id = e.id
    WHERE g.company_id = v_company_id
    ORDER BY g.grant_number
  LOOP
    RAISE NOTICE '  %: % shares, status=%, employee=% %', 
      rec.grant_number, rec.total_shares, rec.status, rec.first_name_en, rec.last_name_en;
  END LOOP;
  
  -- Company users check
  RAISE NOTICE 'Company Users:';
  FOR rec IN 
    SELECT user_id, role
    FROM company_users
    WHERE company_id = v_company_id
  LOOP
    RAISE NOTICE '  User: %, Role: %', rec.user_id, rec.role;
  END LOOP;
  
  RAISE NOTICE '=== SUMMARY COMPLETE ===';
  
END $$;
