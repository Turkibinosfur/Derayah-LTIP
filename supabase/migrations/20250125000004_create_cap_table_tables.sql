/*
  Create Cap Table Related Tables
  
  Problem: The cap table management system references tables (funding_rounds, dilution_scenarios) 
  that don't exist, causing errors when trying to manage cap table data.
  
  Solution: Create all missing cap table related tables with proper structure and RLS policies.
  
  Tables Created: funding_rounds (Track investment rounds), dilution_scenarios (Model dilution scenarios), cap_table_snapshots (Historical cap table data)
*/

-- Create funding_rounds table
CREATE TABLE IF NOT EXISTS funding_rounds (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  round_name text NOT NULL,
  round_type text NOT NULL CHECK (round_type IN ('seed', 'series_a', 'series_b', 'series_c', 'series_d', 'pre_ipo', 'ipo', 'other')),
  amount_raised numeric NOT NULL DEFAULT 0,
  valuation_pre_money numeric NOT NULL DEFAULT 0,
  valuation_post_money numeric NOT NULL DEFAULT 0,
  share_price numeric NOT NULL DEFAULT 0,
  shares_issued numeric DEFAULT 0,
  closing_date date NOT NULL,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create dilution_scenarios table
CREATE TABLE IF NOT EXISTS dilution_scenarios (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  scenario_name text NOT NULL,
  scenario_description text,
  scenario_config jsonb NOT NULL DEFAULT '{}',
  results jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create cap_table_snapshots table for historical data
CREATE TABLE IF NOT EXISTS cap_table_snapshots (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  snapshot_date date NOT NULL,
  snapshot_data jsonb NOT NULL DEFAULT '{}',
  total_shares numeric NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE funding_rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE dilution_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE cap_table_snapshots ENABLE ROW LEVEL SECURITY;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_funding_rounds_company_id ON funding_rounds(company_id);
CREATE INDEX IF NOT EXISTS idx_funding_rounds_date ON funding_rounds(closing_date);
CREATE INDEX IF NOT EXISTS idx_dilution_scenarios_company_id ON dilution_scenarios(company_id);
CREATE INDEX IF NOT EXISTS idx_cap_table_snapshots_company_id ON cap_table_snapshots(company_id);
CREATE INDEX IF NOT EXISTS idx_cap_table_snapshots_date ON cap_table_snapshots(snapshot_date);

-- RLS Policies for funding_rounds (only create if they don't exist)
DO $$
BEGIN
  -- Check if policies already exist before creating them
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'funding_rounds' 
    AND policyname = 'Company users can view funding rounds'
  ) THEN
    CREATE POLICY "Company users can view funding rounds"
      ON funding_rounds FOR SELECT TO authenticated
      USING (company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'funding_rounds' 
    AND policyname = 'Company users can insert funding rounds'
  ) THEN
    CREATE POLICY "Company users can insert funding rounds"
      ON funding_rounds FOR INSERT TO authenticated
      WITH CHECK (company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'funding_rounds' 
    AND policyname = 'Company users can update funding rounds'
  ) THEN
    CREATE POLICY "Company users can update funding rounds"
      ON funding_rounds FOR UPDATE TO authenticated
      USING (company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid()))
      WITH CHECK (company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'funding_rounds' 
    AND policyname = 'Company users can delete funding rounds'
  ) THEN
    CREATE POLICY "Company users can delete funding rounds"
      ON funding_rounds FOR DELETE TO authenticated
      USING (company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid()));
  END IF;
END $$;

-- RLS Policies for dilution_scenarios (only create if they don't exist)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'dilution_scenarios' 
    AND policyname = 'Company users can view dilution scenarios'
  ) THEN
    CREATE POLICY "Company users can view dilution scenarios"
      ON dilution_scenarios FOR SELECT TO authenticated
      USING (company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'dilution_scenarios' 
    AND policyname = 'Company users can insert dilution scenarios'
  ) THEN
    CREATE POLICY "Company users can insert dilution scenarios"
      ON dilution_scenarios FOR INSERT TO authenticated
      WITH CHECK (company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'dilution_scenarios' 
    AND policyname = 'Company users can update dilution scenarios'
  ) THEN
    CREATE POLICY "Company users can update dilution scenarios"
      ON dilution_scenarios FOR UPDATE TO authenticated
      USING (company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid()))
      WITH CHECK (company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'dilution_scenarios' 
    AND policyname = 'Company users can delete dilution scenarios'
  ) THEN
    CREATE POLICY "Company users can delete dilution scenarios"
      ON dilution_scenarios FOR DELETE TO authenticated
      USING (company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid()));
  END IF;
END $$;

-- RLS Policies for cap_table_snapshots (only create if they don't exist)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'cap_table_snapshots' 
    AND policyname = 'Company users can view cap table snapshots'
  ) THEN
    CREATE POLICY "Company users can view cap table snapshots"
      ON cap_table_snapshots FOR SELECT TO authenticated
      USING (company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'cap_table_snapshots' 
    AND policyname = 'Company users can insert cap table snapshots'
  ) THEN
    CREATE POLICY "Company users can insert cap table snapshots"
      ON cap_table_snapshots FOR INSERT TO authenticated
      WITH CHECK (company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'cap_table_snapshots' 
    AND policyname = 'Company users can update cap table snapshots'
  ) THEN
    CREATE POLICY "Company users can update cap table snapshots"
      ON cap_table_snapshots FOR UPDATE TO authenticated
      USING (company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid()))
      WITH CHECK (company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'cap_table_snapshots' 
    AND policyname = 'Company users can delete cap table snapshots'
  ) THEN
    CREATE POLICY "Company users can delete cap table snapshots"
      ON cap_table_snapshots FOR DELETE TO authenticated
      USING (company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid()));
  END IF;
END $$;

-- Verify tables and policies were created
DO $$
BEGIN
  RAISE NOTICE 'Cap table related tables created successfully:';
  RAISE NOTICE '  - funding_rounds';
  RAISE NOTICE '  - dilution_scenarios';
  RAISE NOTICE '  - cap_table_snapshots';
  RAISE NOTICE 'All RLS policies created for company data isolation';
END $$;
