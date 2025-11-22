-- =====================================================
-- DIAGNOSTIC: Check company_users access issue
-- =====================================================
-- Run this to find out why the access check is failing

-- Step 1: What is your current auth.uid()?
SELECT 
  'Step 1: Your auth.uid()' as step,
  auth.uid()::text as user_id;

-- Step 2: Check ALL company_users records (as superuser/without RLS)
-- This will show us all records in the table
SELECT 
  'Step 2: All company_users records' as step,
  user_id::text,
  company_id::text,
  role,
  is_active,
  created_at
FROM company_users
ORDER BY company_id, role;

-- Step 3: Check if your auth.uid() exists in company_users at all
SELECT 
  'Step 3: Does your user_id exist?' as step,
  COUNT(*) as count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Your user_id exists in company_users'
    ELSE '❌ Your user_id NOT found in company_users'
  END as result
FROM company_users
WHERE user_id = auth.uid();

-- Step 4: Check your company_users record specifically
SELECT 
  'Step 4: Your company_users record' as step,
  user_id::text,
  company_id::text,
  role,
  is_active,
  CASE 
    WHEN is_active = false THEN '❌ Account is INACTIVE - This is the problem!'
    WHEN company_id != 'b7c082c7-79ff-4a62-8c79-a2b2a08110b1' THEN '⚠️ Different company_id'
    ELSE '✅ Looks good'
  END as status
FROM company_users
WHERE user_id = auth.uid();

-- Step 5: Test the function directly with your actual values
-- First, let's see what user_id and company_id to use
SELECT 
  'Step 5: Test function with actual values' as step,
  cu.user_id::text,
  cu.company_id::text,
  cu.role,
  check_user_company_access(cu.user_id, cu.company_id) as function_result,
  CASE 
    WHEN check_user_company_access(cu.user_id, cu.company_id) THEN '✅ Function works!'
    ELSE '❌ Function returns false'
  END as result
FROM company_users cu
WHERE cu.user_id = auth.uid()
LIMIT 1;

-- Step 6: Check if there are multiple records for your user_id
SELECT 
  'Step 6: Multiple records check' as step,
  COUNT(*) as record_count,
  array_agg(company_id::text) as company_ids,
  array_agg(role) as roles,
  array_agg(is_active) as active_statuses
FROM company_users
WHERE user_id = auth.uid();

-- Step 7: Manual test - check the company_users record without RLS
-- This uses a SECURITY DEFINER approach to see the actual data
DO $$
DECLARE
  v_user_id uuid;
  v_company_id uuid;
  v_exists boolean;
BEGIN
  v_user_id := auth.uid();
  
  -- Get the first company_id for this user
  SELECT company_id INTO v_company_id
  FROM company_users
  WHERE user_id = v_user_id
  LIMIT 1;
  
  IF v_company_id IS NULL THEN
    RAISE NOTICE '❌ No company_users record found for user_id: %', v_user_id;
  ELSE
    -- Check if record exists and is active
    SELECT EXISTS (
      SELECT 1 
      FROM company_users
      WHERE user_id = v_user_id
      AND company_id = v_company_id
      AND is_active = true
    ) INTO v_exists;
    
    IF v_exists THEN
      RAISE NOTICE '✅ Record found: user_id=%, company_id=%, is_active=true', v_user_id, v_company_id;
    ELSE
      -- Check if it exists but is inactive
      SELECT EXISTS (
        SELECT 1 
        FROM company_users
        WHERE user_id = v_user_id
        AND company_id = v_company_id
      ) INTO v_exists;
      
      IF v_exists THEN
        RAISE NOTICE '⚠️ Record exists but is_active=false for user_id=%, company_id=%', v_user_id, v_company_id;
      ELSE
        RAISE NOTICE '❌ Record not found for user_id=%, company_id=%', v_user_id, v_company_id;
      END IF;
    END IF;
  END IF;
END $$;

