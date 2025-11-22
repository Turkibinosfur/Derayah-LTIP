/*
  # Add Derayah Financial Sample Data (Final)

  ## Schema Changes
    - Add is_active, liquidation_preference, preference_multiple columns to shareholders
    - Add shares_issued and notes columns to funding_rounds

  ## Sample Data
    - Derayah Financial cap table with 6 shareholders
    - 3 funding rounds history
    - 3 dilution scenarios for modeling

  ## Security
    - Data is company-specific and isolated by RLS policies
*/

-- Add missing columns to shareholders table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'shareholders' AND column_name = 'is_active'
  ) THEN
    ALTER TABLE shareholders ADD COLUMN is_active boolean DEFAULT true;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'shareholders' AND column_name = 'liquidation_preference'
  ) THEN
    ALTER TABLE shareholders ADD COLUMN liquidation_preference numeric DEFAULT 0;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'shareholders' AND column_name = 'preference_multiple'
  ) THEN
    ALTER TABLE shareholders ADD COLUMN preference_multiple numeric DEFAULT 1.0;
  END IF;
END $$;

-- Add missing columns to funding_rounds table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'funding_rounds' AND column_name = 'shares_issued'
  ) THEN
    ALTER TABLE funding_rounds ADD COLUMN shares_issued numeric DEFAULT 0;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'funding_rounds' AND column_name = 'notes'
  ) THEN
    ALTER TABLE funding_rounds ADD COLUMN notes text;
  END IF;
END $$;

-- Insert Derayah Financial sample data
DO $$
DECLARE
  v_company_id uuid;
BEGIN
  -- Get the first company ID
  SELECT id INTO v_company_id FROM companies LIMIT 1;
  
  IF v_company_id IS NOT NULL THEN
    
    -- Clear existing data
    DELETE FROM dilution_scenarios WHERE company_id = v_company_id;
    DELETE FROM funding_rounds WHERE company_id = v_company_id;
    DELETE FROM shareholders WHERE company_id = v_company_id;
    
    -- Insert Founders (75% combined)
    INSERT INTO shareholders (company_id, name, shareholder_type, shares_owned, ownership_percentage, share_class, investment_amount, is_active)
    VALUES 
      (v_company_id, 'Abdullah Al-Derayah', 'founder', 3500000, 35.00, 'Common', 0, true),
      (v_company_id, 'Mohammed Al-Subaie', 'founder', 2500000, 25.00, 'Common', 0, true),
      (v_company_id, 'Fahad Al-Rashid', 'founder', 1500000, 15.00, 'Common', 0, true);

    -- Insert Institutional Investors (18% combined)
    INSERT INTO shareholders (company_id, name, shareholder_type, shares_owned, ownership_percentage, share_class, investment_amount, liquidation_preference, preference_multiple, is_active)
    VALUES 
      (v_company_id, 'Saudi Venture Capital', 'investor', 1000000, 10.00, 'Series A Preferred', 50000000, 50000000, 1.0, true),
      (v_company_id, 'GCC Growth Fund', 'investor', 800000, 8.00, 'Series A Preferred', 40000000, 40000000, 1.0, true);

    -- Insert Employee Pool (7%)
    INSERT INTO shareholders (company_id, name, shareholder_type, shares_owned, ownership_percentage, share_class, investment_amount, is_active)
    VALUES 
      (v_company_id, 'Employee Stock Option Pool', 'employee', 700000, 7.00, 'Common', 0, true);

    -- Insert Funding Rounds
    INSERT INTO funding_rounds (company_id, round_name, round_type, amount_raised, valuation_pre_money, valuation_post_money, share_price, shares_issued, closing_date, notes)
    VALUES 
      (v_company_id, 'Seed Round', 'seed', 20000000, 80000000, 100000000, 10.00, 2000000, '2022-03-15', 'Initial seed funding from angel investors'),
      (v_company_id, 'Series A', 'series_a', 90000000, 410000000, 500000000, 50.00, 1800000, '2023-06-20', 'Led by Saudi Venture Capital and GCC Growth Fund'),
      (v_company_id, 'Bridge Round', 'other', 25000000, 500000000, 525000000, 62.50, 400000, '2024-01-10', 'Bridge financing before Series B');

    -- Insert Dilution Scenarios
    INSERT INTO dilution_scenarios (company_id, scenario_name, scenario_description, scenario_config, results, created_at)
    VALUES 
      (v_company_id, 
       'Series B Round - SAR 150M', 
       'Investment: SAR 150,000,000, New shares: 2,000,000, Valuation: SAR 750,000,000',
       '{"new_investment": 150000000, "new_shares": 2000000, "valuation": 750000000, "share_class": "Series B Preferred"}'::jsonb,
       '{"new_total_shares": 12000000, "shareholders": [{"name": "Abdullah Al-Derayah", "current_shares": 3500000, "current_ownership": 35.00, "new_ownership": 29.17, "dilution": "-5.83"}]}'::jsonb,
       NOW() - INTERVAL '15 days'
      ),
      (v_company_id,
       'IPO Scenario - SAR 2B Valuation',
       'Investment: SAR 300,000,000, New shares: 1,500,000, Valuation: SAR 2,000,000,000',
       '{"new_investment": 300000000, "new_shares": 1500000, "valuation": 2000000000, "share_class": "Common"}'::jsonb,
       '{"new_total_shares": 11500000, "shareholders": [{"name": "Abdullah Al-Derayah", "current_shares": 3500000, "current_ownership": 35.00, "new_ownership": 30.43, "dilution": "-4.57"}]}'::jsonb,
       NOW() - INTERVAL '7 days'
      );

    RAISE NOTICE 'Successfully inserted Derayah Financial sample data';
    RAISE NOTICE 'Shareholders: %', (SELECT COUNT(*) FROM shareholders WHERE company_id = v_company_id);
    RAISE NOTICE 'Funding rounds: %', (SELECT COUNT(*) FROM funding_rounds WHERE company_id = v_company_id);
    RAISE NOTICE 'Dilution scenarios: %', (SELECT COUNT(*) FROM dilution_scenarios WHERE company_id = v_company_id);

  ELSE
    RAISE NOTICE 'No company found. Please create a company first.';
  END IF;
END $$;
