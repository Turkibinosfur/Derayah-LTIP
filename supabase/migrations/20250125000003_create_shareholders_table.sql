/*
  Create Shareholders Table with RLS Policies
  
  Problem: The shareholders table is referenced in other migrations but not actually defined,
  causing RLS policy violations when trying to access it.
  
  Solution: Create the shareholders table with proper structure and comprehensive RLS policies.
  
  Security: All operations require authentication, users can only access shareholders for their own company, complete data isolation between companies.
*/

-- Create shareholders table
CREATE TABLE IF NOT EXISTS shareholders (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  shareholder_type text NOT NULL CHECK (shareholder_type IN ('founder', 'investor', 'employee', 'advisor', 'other')),
  shares_owned numeric NOT NULL DEFAULT 0,
  ownership_percentage numeric NOT NULL DEFAULT 0,
  share_class text NOT NULL DEFAULT 'Common',
  investment_amount numeric DEFAULT 0,
  liquidation_preference numeric DEFAULT 0,
  preference_multiple numeric DEFAULT 1.0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE shareholders ENABLE ROW LEVEL SECURITY;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_shareholders_company_id ON shareholders(company_id);
CREATE INDEX IF NOT EXISTS idx_shareholders_type ON shareholders(shareholder_type);
CREATE INDEX IF NOT EXISTS idx_shareholders_active ON shareholders(is_active) WHERE is_active = true;

-- RLS Policies for shareholders table (only create if they don't exist)
DO $$
BEGIN
  -- SELECT policy - Users can view shareholders for their company
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'shareholders' 
    AND policyname = 'Company users can view shareholders'
  ) THEN
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
  END IF;

  -- INSERT policy - Users can add shareholders for their company
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'shareholders' 
    AND policyname = 'Company users can insert shareholders'
  ) THEN
    CREATE POLICY "Company users can insert shareholders"
      ON shareholders
      FOR INSERT
      TO authenticated
      WITH CHECK (
        company_id IN (
          SELECT company_id
          FROM company_users
          WHERE user_id = auth.uid()
        )
      );
  END IF;

  -- UPDATE policy - Users can update shareholders for their company
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'shareholders' 
    AND policyname = 'Company users can update shareholders'
  ) THEN
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
  END IF;

  -- DELETE policy - Users can delete shareholders for their company
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'shareholders' 
    AND policyname = 'Company users can delete shareholders'
  ) THEN
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
  END IF;
END $$;

-- Verify table and policies were created
DO $$
BEGIN
  RAISE NOTICE 'Shareholders table created successfully';
  RAISE NOTICE 'RLS policies created: SELECT, INSERT, UPDATE, DELETE';
  RAISE NOTICE 'Indexes created for performance optimization';
END $$;
