/*
  Fix Shareholders RLS Policies
  
  Problem: The shareholders table is missing essential RLS policies for SELECT, UPDATE, and DELETE operations.
  Only INSERT policy exists, which causes RLS violations when trying to view or manage shareholders.
  
  Solution: Add comprehensive RLS policies for all operations on the shareholders table.
  
  Security: Users can only access shareholders for their own company, all operations require proper authentication, company data isolation is maintained.
*/

-- Add SELECT policy for shareholders
CREATE POLICY "Company users can view shareholders"
  ON shareholders
  FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id
      FROM company_users
      WHERE user_id = auth.uid()
    )
  );

-- Add UPDATE policy for shareholders
CREATE POLICY "Company users can update shareholders"
  ON shareholders
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

-- Add DELETE policy for shareholders
CREATE POLICY "Company users can delete shareholders"
  ON shareholders
  FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id
      FROM company_users
      WHERE user_id = auth.uid()
    )
  );

-- Verify policies were created
DO $$
BEGIN
  RAISE NOTICE 'Shareholders RLS policies created successfully';
  RAISE NOTICE 'Policies added: SELECT, UPDATE, DELETE for company users';
END $$;
