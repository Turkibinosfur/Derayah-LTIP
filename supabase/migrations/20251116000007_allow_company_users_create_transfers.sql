/*
  Add INSERT and UPDATE policies for share_transfers table
  
  Problem: Company admins and other company users cannot insert share transfers,
  causing RLS policy violations when trying to transfer shares.
  
  Solution: Add INSERT and UPDATE policies that allow company users to create transfers
  for their company, with proper validation checks.
*/

-- Create INSERT policy for share_transfers (drop and recreate for consistency)
DO $$
BEGIN
  -- Drop existing policy if it exists (to ensure we have the latest version)
  DROP POLICY IF EXISTS "Company users can create transfers" ON share_transfers;
  
  -- Create the INSERT policy using EXISTS for better clarity and reliability
  CREATE POLICY "Company users can create transfers"
    ON share_transfers
    FOR INSERT
    TO authenticated
    WITH CHECK (
      -- User must belong to the company
      EXISTS (
        SELECT 1 FROM company_users
        WHERE user_id = auth.uid()
        AND company_id = share_transfers.company_id
      )
      AND
      -- If employee_id is specified, it must belong to an employee in the same company
      (
        share_transfers.employee_id IS NULL
        OR EXISTS (
          SELECT 1 FROM employees
          WHERE id = share_transfers.employee_id
          AND company_id = share_transfers.company_id
        )
      )
      AND
      -- If grant_id is specified, it must belong to a grant in the same company
      (
        share_transfers.grant_id IS NULL
        OR EXISTS (
          SELECT 1 FROM grants
          WHERE id = share_transfers.grant_id
          AND company_id = share_transfers.company_id
        )
      )
      AND
      -- Both portfolios must belong to the same company
      EXISTS (
        SELECT 1 FROM portfolios
        WHERE id = share_transfers.from_portfolio_id
        AND company_id = share_transfers.company_id
      )
      AND
      EXISTS (
        SELECT 1 FROM portfolios
        WHERE id = share_transfers.to_portfolio_id
        AND company_id = share_transfers.company_id
      )
    );
    
  RAISE NOTICE '✅ Created/Updated INSERT policy for share_transfers';
END $$;

-- Create UPDATE policy for share_transfers (only if it doesn't exist)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'share_transfers' 
    AND policyname = 'Company users can update transfers'
  ) THEN
    CREATE POLICY "Company users can update transfers"
      ON share_transfers
      FOR UPDATE
      TO authenticated
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
    RAISE NOTICE '✅ Created UPDATE policy for share_transfers';
  ELSE
    RAISE NOTICE 'ℹ️ UPDATE policy already exists for share_transfers';
  END IF;
END $$;

-- Verify policies were created
SELECT 
  '=== VERIFICATION: share_transfers RLS policies ===' as info;

SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'share_transfers'
ORDER BY cmd, policyname;

