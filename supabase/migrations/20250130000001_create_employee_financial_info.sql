/*
  Create Employee Financial Information Table
  
  This migration creates a separate table for storing sensitive financial and banking information
  for employees. This is necessary for Saudi stock market operations including:
  
  1. Share Transfers: Investment/custody account details for transferring shares
  2. Cash Transfers: IBAN and bank account details for transferring cash proceeds
  3. ESOP Exercise: Broker account information for exercising stock options
  
  Security Features:
  - Separate table for better data isolation
  - Sensitive fields should be encrypted at application level
  - Comprehensive RLS policies for company data isolation
  - Audit trail with verification tracking
  
  Fields:
  - Banking Information: IBAN, bank name, branch code, account holder name (Arabic)
  - Investment Account: Custody account number (Nostro), broker/custodian details
  - Tadawul Integration: Investor number for Tadawul registration
  - Verification: Account verification status and tracking
*/

-- Create enum for account status
DO $$ BEGIN
  CREATE TYPE financial_account_status AS ENUM ('pending', 'verified', 'rejected', 'expired');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Create employee_financial_info table
CREATE TABLE IF NOT EXISTS employee_financial_info (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id uuid REFERENCES employees(id) ON DELETE CASCADE UNIQUE NOT NULL,
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  
  -- Banking Information (for cash transfers)
  iban text, -- International Bank Account Number (SAXX XXXX XXXX XXXX XXXX XXXX)
  bank_name text,
  bank_branch_code text,
  account_holder_name_ar text, -- Account holder name in Arabic for bank records
  
  -- Investment/Custody Account Information (for share transfers)
  investment_account_number text, -- Nostro/Custody account number (sensitive - should be encrypted)
  broker_custodian_name text, -- Name of authorized broker/custodian (NCB Capital, Al Rajhi Capital, etc.)
  broker_account_number text, -- Broker account number (sensitive - should be encrypted)
  tadawul_investor_number text, -- Investor number registered with Tadawul
  
  -- Account Verification and Status
  account_status financial_account_status DEFAULT 'pending',
  account_verification_date date,
  verified_by uuid REFERENCES company_users(id),
  verified_at timestamptz,
  verification_notes text, -- Notes from verification process
  
  -- Metadata
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES company_users(id),
  
  -- Ensure one financial info record per employee
  CONSTRAINT unique_employee_financial_info UNIQUE (employee_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_employee_financial_info_employee_id ON employee_financial_info(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_financial_info_company_id ON employee_financial_info(company_id);
CREATE INDEX IF NOT EXISTS idx_employee_financial_info_account_status ON employee_financial_info(account_status);
CREATE INDEX IF NOT EXISTS idx_employee_financial_info_broker_custodian ON employee_financial_info(broker_custodian_name) WHERE broker_custodian_name IS NOT NULL;

-- Enable RLS
ALTER TABLE employee_financial_info ENABLE ROW LEVEL SECURITY;

-- RLS Policies for company data isolation

-- SELECT Policy: Employees can view their own financial info, company admins can view their company's employees
CREATE POLICY "Employees can view own financial info" ON employee_financial_info
  FOR SELECT USING (
    -- Employee can see their own financial info
    employee_id IN (
      SELECT id FROM employees WHERE user_id = auth.uid()
    )
    OR
    -- Company admins can see financial info for employees in their company
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  );

-- INSERT Policy: Only company admins can create financial info records
CREATE POLICY "Company admins can create financial info" ON employee_financial_info
  FOR INSERT WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
    AND employee_id IN (
      SELECT id FROM employees WHERE company_id = employee_financial_info.company_id
    )
  );

-- UPDATE Policy: Company admins can update financial info, employees can update their own pending records
CREATE POLICY "Users can update financial info" ON employee_financial_info
  FOR UPDATE USING (
    -- Company admins can update any financial info in their company
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
    OR
    -- Employees can update their own financial info if status is pending
    (
      employee_id IN (
        SELECT id FROM employees WHERE user_id = auth.uid()
      )
      AND account_status = 'pending'
    )
  );

-- DELETE Policy: Only super admins can delete financial info (for compliance/audit reasons)
CREATE POLICY "Super admins can delete financial info" ON employee_financial_info
  FOR DELETE USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND role = 'super_admin'
    )
  );

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_employee_financial_info_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_employee_financial_info_timestamp
  BEFORE UPDATE ON employee_financial_info
  FOR EACH ROW
  EXECUTE FUNCTION update_employee_financial_info_updated_at();

-- Create function to set company_id from employee_id on insert
CREATE OR REPLACE FUNCTION set_employee_financial_info_company_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.company_id IS NULL THEN
    SELECT company_id INTO NEW.company_id
    FROM employees
    WHERE id = NEW.employee_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically set company_id
CREATE TRIGGER set_employee_financial_info_company_id_trigger
  BEFORE INSERT OR UPDATE ON employee_financial_info
  FOR EACH ROW
  EXECUTE FUNCTION set_employee_financial_info_company_id();

-- Add helpful comments
COMMENT ON TABLE employee_financial_info IS 'Stores sensitive banking and investment account information for employees required for Saudi stock market operations';
COMMENT ON COLUMN employee_financial_info.iban IS 'International Bank Account Number (IBAN) in format SAXX XXXX XXXX XXXX XXXX XXXX - Required for cash transfers';
COMMENT ON COLUMN employee_financial_info.investment_account_number IS 'Nostro/Custody account number at authorized broker/custodian - Required for share transfers (SENSITIVE - should be encrypted)';
COMMENT ON COLUMN employee_financial_info.broker_custodian_name IS 'Name of authorized broker/custodian (e.g., NCB Capital, Al Rajhi Capital, Jadwa Investment)';
COMMENT ON COLUMN employee_financial_info.tadawul_investor_number IS 'Investor number registered with Tadawul (if applicable)';
COMMENT ON COLUMN employee_financial_info.account_status IS 'Verification status of the financial account information';

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON employee_financial_info TO authenticated;

-- Note: Sensitive fields (iban, investment_account_number, broker_account_number) should be encrypted
-- at the application level before insertion. Consider using:
-- - Supabase Vault for encryption
-- - Application-level encryption before database insertion
-- - Field-level encryption keys managed securely

