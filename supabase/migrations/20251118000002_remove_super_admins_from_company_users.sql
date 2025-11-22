/*
  # Remove Super Admins from Company Users
  
  Super admins should not be linked to specific companies in company_users table.
  They should only exist in company_super_admin_memberships for cross-company access.
  
  This migration:
  1. Removes all super_admin role entries from company_users
  2. Ensures super admins are tracked only in company_super_admin_memberships
  3. Adds super admins to company_super_admin_memberships for all existing companies
  4. Super admins can access all companies through the operating console
*/

-- Step 1: Get all super admin user IDs before deleting from company_users
DO $$
DECLARE
  v_super_admin_ids uuid[];
  v_company_id uuid;
  v_user_id uuid;
BEGIN
  -- Collect all unique super admin user IDs
  SELECT ARRAY_AGG(DISTINCT user_id) INTO v_super_admin_ids
  FROM company_users
  WHERE role = 'super_admin';
  
  IF v_super_admin_ids IS NULL OR array_length(v_super_admin_ids, 1) IS NULL THEN
    RAISE NOTICE 'No super admin users found in company_users';
  ELSE
    RAISE NOTICE 'Found % super admin user(s) to migrate', array_length(v_super_admin_ids, 1);
    
    -- For each super admin, add them to company_super_admin_memberships for all companies
    FOREACH v_user_id IN ARRAY v_super_admin_ids
    LOOP
      -- Add super admin to all existing companies
      FOR v_company_id IN SELECT id FROM companies
      LOOP
        INSERT INTO company_super_admin_memberships (company_id, user_id, created_at, updated_at)
        VALUES (v_company_id, v_user_id, now(), now())
        ON CONFLICT (company_id, user_id) DO UPDATE
          SET updated_at = now();
      END LOOP;
      
      RAISE NOTICE 'Added super admin % to all companies in company_super_admin_memberships', v_user_id;
    END LOOP;
  END IF;
END;
$$;

-- Step 2: Remove all super_admin entries from company_users
-- They should only exist in company_super_admin_memberships
DELETE FROM company_users 
WHERE role = 'super_admin';

-- Step 3: Verify the cleanup
DO $$
DECLARE
  v_remaining_count integer;
  v_memberships_count integer;
BEGIN
  SELECT COUNT(*) INTO v_remaining_count
  FROM company_users
  WHERE role = 'super_admin';
  
  SELECT COUNT(*) INTO v_memberships_count
  FROM company_super_admin_memberships;
  
  IF v_remaining_count > 0 THEN
    RAISE NOTICE 'Warning: % super_admin entries still exist in company_users', v_remaining_count;
  ELSE
    RAISE NOTICE 'Success: All super_admin entries removed from company_users';
  END IF;
  
  RAISE NOTICE 'Super admin memberships in company_super_admin_memberships: %', v_memberships_count;
END;
$$;

-- Note: Super admins are now tracked only in company_super_admin_memberships
-- which allows them to access all companies through the operating console
-- without being tied to any specific company in company_users

