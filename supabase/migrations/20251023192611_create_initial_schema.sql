/*
  # SAUDI-LTIP-CONNECT Initial Database Schema
  
  ## Overview
  Complete database schema for managing Long-Term Incentive Plans (LTIPs) and Employee Stock Option Plans (ESOPs) 
  for publicly listed companies on Saudi Exchange (Tadawul). Designed to support up to 50,000 employees per company.
  
  ## Tables Created
  
  ### 1. companies - Issuer information
  ### 2. company_users - Role-based access control
  ### 3. employees - Grantee records
  ### 4. incentive_plans - LTIP/ESOP plan definitions
  ### 5. portfolios - Share custody accounts
  ### 6. grants - Individual allocations
  ### 7. vesting_schedules - Detailed vesting timeline
  ### 8. share_transfers - Audit trail of share movements
  ### 9. market_data - Tadawul stock prices
  ### 10. audit_logs - Comprehensive audit trail
  ### 11. documents - Document storage metadata
  ### 12. notifications - In-app notification system
  
  ## Security
  - All tables have Row Level Security (RLS) enabled
  - Policies ensure complete data isolation between companies
*/

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom types
DO $$ BEGIN
  CREATE TYPE company_verification_status AS ENUM ('pending', 'verified', 'rejected');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE company_status AS ENUM ('active', 'suspended', 'inactive');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('super_admin', 'hr_admin', 'finance_admin', 'legal_admin', 'viewer');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE employment_status AS ENUM ('active', 'terminated', 'resigned', 'retired');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE plan_type AS ENUM ('LTIP_RSU', 'LTIP_RSA', 'ESOP');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE vesting_schedule_type AS ENUM ('time_based', 'performance_based', 'hybrid');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE plan_status AS ENUM ('draft', 'active', 'closed', 'suspended');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE approval_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE grant_status AS ENUM ('pending_signature', 'active', 'completed', 'forfeited', 'cancelled');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE vesting_status AS ENUM ('pending', 'vested', 'forfeited');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE portfolio_type AS ENUM ('company_reserved', 'employee_vested');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE transfer_type AS ENUM ('vesting', 'forfeiture', 'exercise', 'cancellation');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE document_type AS ENUM ('contract', 'verification', 'certificate', 'report');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE notification_type AS ENUM ('grant_issued', 'vesting_completed', 'document_ready', 'plan_created', 'contract_signed');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE notification_priority AS ENUM ('low', 'medium', 'high', 'urgent');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- =====================================================
-- 1. COMPANIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS companies (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_name_en text NOT NULL,
  company_name_ar text NOT NULL,
  tadawul_symbol text UNIQUE NOT NULL,
  commercial_registration_number text UNIQUE NOT NULL,
  verification_status company_verification_status DEFAULT 'pending',
  verification_documents jsonb DEFAULT '[]',
  total_reserved_shares numeric DEFAULT 0,
  available_shares numeric DEFAULT 0,
  admin_user_id uuid REFERENCES auth.users(id),
  status company_status DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  metadata jsonb DEFAULT '{}'
);

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 2. COMPANY USERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS company_users (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role user_role NOT NULL,
  permissions jsonb DEFAULT '{}',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  last_login_at timestamptz,
  UNIQUE(company_id, user_id)
);

ALTER TABLE company_users ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 3. EMPLOYEES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS employees (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  employee_number text NOT NULL,
  national_id text NOT NULL,
  email text NOT NULL,
  phone text,
  first_name_en text NOT NULL,
  last_name_en text NOT NULL,
  first_name_ar text,
  last_name_ar text,
  department text,
  job_title text,
  hire_date date,
  employment_status employment_status DEFAULT 'active',
  termination_date date,
  user_id uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(company_id, employee_number)
);

ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 4. INCENTIVE PLANS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS incentive_plans (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  plan_name_en text NOT NULL,
  plan_name_ar text NOT NULL,
  plan_type plan_type NOT NULL,
  plan_code text NOT NULL,
  description_en text,
  description_ar text,
  vesting_schedule_type vesting_schedule_type NOT NULL,
  vesting_config jsonb NOT NULL,
  exercise_price numeric,
  total_shares_allocated numeric DEFAULT 0,
  shares_granted numeric DEFAULT 0,
  shares_available numeric DEFAULT 0,
  start_date date NOT NULL,
  end_date date,
  status plan_status DEFAULT 'draft',
  approval_status approval_status DEFAULT 'pending',
  approved_by uuid REFERENCES company_users(id),
  approved_at timestamptz,
  created_by uuid REFERENCES company_users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(company_id, plan_code)
);

ALTER TABLE incentive_plans ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. PORTFOLIOS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS portfolios (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  portfolio_type portfolio_type NOT NULL,
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  employee_id uuid REFERENCES employees(id) ON DELETE CASCADE,
  total_shares numeric DEFAULT 0,
  available_shares numeric DEFAULT 0,
  locked_shares numeric DEFAULT 0,
  portfolio_number text UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE portfolios ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 6. GRANTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS grants (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  grant_number text UNIQUE NOT NULL,
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  plan_id uuid REFERENCES incentive_plans(id) ON DELETE CASCADE NOT NULL,
  employee_id uuid REFERENCES employees(id) ON DELETE CASCADE NOT NULL,
  grant_date date DEFAULT CURRENT_DATE,
  total_shares numeric NOT NULL,
  vested_shares numeric DEFAULT 0,
  exercised_shares numeric DEFAULT 0,
  forfeited_shares numeric DEFAULT 0,
  remaining_unvested_shares numeric,
  vesting_start_date date NOT NULL,
  vesting_end_date date NOT NULL,
  contract_document_url text,
  contract_signed_at timestamptz,
  employee_acceptance_at timestamptz,
  status grant_status DEFAULT 'pending_signature',
  cancellation_reason text,
  created_by uuid REFERENCES company_users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE grants ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 7. VESTING SCHEDULES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS vesting_schedules (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  grant_id uuid REFERENCES grants(id) ON DELETE CASCADE NOT NULL,
  sequence_number integer NOT NULL,
  vesting_date date NOT NULL,
  shares_to_vest numeric NOT NULL,
  performance_condition_met boolean DEFAULT true,
  performance_metrics jsonb,
  actual_vest_date date,
  status vesting_status DEFAULT 'pending',
  processed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  UNIQUE(grant_id, sequence_number)
);

ALTER TABLE vesting_schedules ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 8. SHARE TRANSFERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS share_transfers (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  transfer_number text UNIQUE NOT NULL,
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  grant_id uuid REFERENCES grants(id),
  employee_id uuid REFERENCES employees(id),
  from_portfolio_id uuid REFERENCES portfolios(id),
  to_portfolio_id uuid REFERENCES portfolios(id),
  shares_transferred numeric NOT NULL,
  transfer_type transfer_type NOT NULL,
  transfer_date date DEFAULT CURRENT_DATE,
  market_price_at_transfer numeric,
  processed_at timestamptz DEFAULT now(),
  processed_by_system boolean DEFAULT false,
  notes text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE share_transfers ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 9. MARKET DATA TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS market_data (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  tadawul_symbol text NOT NULL,
  trading_date date NOT NULL,
  opening_price numeric,
  closing_price numeric NOT NULL,
  high_price numeric,
  low_price numeric,
  volume bigint,
  last_updated timestamptz DEFAULT now(),
  source text,
  UNIQUE(tadawul_symbol, trading_date)
);

ALTER TABLE market_data ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 10. AUDIT LOGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id),
  entity_type text NOT NULL,
  entity_id uuid,
  action text NOT NULL,
  old_values jsonb,
  new_values jsonb,
  ip_address inet,
  user_agent text,
  timestamp timestamptz DEFAULT now(),
  metadata jsonb DEFAULT '{}'
);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 11. DOCUMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS documents (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  document_type document_type NOT NULL,
  related_entity_type text,
  related_entity_id uuid,
  file_name text NOT NULL,
  file_size bigint,
  storage_path text NOT NULL,
  mime_type text,
  language text DEFAULT 'en',
  is_signed boolean DEFAULT false,
  signature_data jsonb,
  uploaded_by uuid REFERENCES auth.users(id),
  uploaded_at timestamptz DEFAULT now(),
  expires_at timestamptz
);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 12. NOTIFICATIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  recipient_user_id uuid REFERENCES auth.users(id) NOT NULL,
  notification_type notification_type NOT NULL,
  title_en text NOT NULL,
  title_ar text,
  message_en text NOT NULL,
  message_ar text,
  priority notification_priority DEFAULT 'medium',
  read_at timestamptz,
  delivery_channels text[] DEFAULT ARRAY['in_app'],
  delivery_status jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Companies policies
CREATE POLICY "Company admins can view own company"
  ON companies FOR SELECT TO authenticated
  USING (
    admin_user_id = auth.uid()
    OR id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid())
  );

CREATE POLICY "Company admins can update own company"
  ON companies FOR UPDATE TO authenticated
  USING (
    id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() AND role IN ('super_admin', 'finance_admin')
    )
  );

-- Company users policies
CREATE POLICY "Users can view own company associations"
  ON company_users FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Super admins can manage company users"
  ON company_users FOR ALL TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() AND role = 'super_admin'
    )
  );

-- Employees policies
CREATE POLICY "Employees can view own data"
  ON employees FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  );

CREATE POLICY "HR admins can manage employees"
  ON employees FOR ALL TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() AND role IN ('super_admin', 'hr_admin')
    )
  );

-- Plans policies
CREATE POLICY "Company users can view own plans"
  ON incentive_plans FOR SELECT TO authenticated
  USING (company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid()));

CREATE POLICY "Admins can manage plans"
  ON incentive_plans FOR ALL TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  );

-- Portfolios policies
CREATE POLICY "Users can view relevant portfolios"
  ON portfolios FOR SELECT TO authenticated
  USING (
    employee_id IN (SELECT id FROM employees WHERE user_id = auth.uid())
    OR company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() AND role IN ('super_admin', 'finance_admin')
    )
  );

-- Grants policies
CREATE POLICY "Users can view relevant grants"
  ON grants FOR SELECT TO authenticated
  USING (
    employee_id IN (SELECT id FROM employees WHERE user_id = auth.uid())
    OR company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  );

CREATE POLICY "Admins can manage grants"
  ON grants FOR ALL TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() AND role IN ('super_admin', 'hr_admin')
    )
  );

-- Vesting schedules policies
CREATE POLICY "Users can view relevant vesting schedules"
  ON vesting_schedules FOR SELECT TO authenticated
  USING (
    grant_id IN (
      SELECT g.id FROM grants g
      JOIN employees e ON g.employee_id = e.id
      WHERE e.user_id = auth.uid()
    )
    OR grant_id IN (
      SELECT g.id FROM grants g
      WHERE g.company_id IN (
        SELECT company_id FROM company_users
        WHERE user_id = auth.uid() AND role IN ('super_admin', 'hr_admin', 'finance_admin')
      )
    )
  );

-- Share transfers policies
CREATE POLICY "Users can view relevant transfers"
  ON share_transfers FOR SELECT TO authenticated
  USING (
    employee_id IN (SELECT id FROM employees WHERE user_id = auth.uid())
    OR company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid())
  );

-- Market data policies
CREATE POLICY "Authenticated users can view market data"
  ON market_data FOR SELECT TO authenticated
  USING (true);

-- Audit logs policies
CREATE POLICY "Company admins can view own audit logs"
  ON audit_logs FOR SELECT TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() AND role IN ('super_admin', 'finance_admin', 'legal_admin')
    )
  );

-- Documents policies
CREATE POLICY "Users can view relevant documents"
  ON documents FOR SELECT TO authenticated
  USING (
    company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid())
    OR related_entity_id IN (SELECT id FROM employees WHERE user_id = auth.uid())
  );

-- Notifications policies
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT TO authenticated
  USING (recipient_user_id = auth.uid());

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE TO authenticated
  USING (recipient_user_id = auth.uid());

-- =====================================================
-- INDEXES
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_employees_company_active ON employees(company_id) WHERE employment_status = 'active';
CREATE INDEX IF NOT EXISTS idx_employees_user ON employees(user_id);
CREATE INDEX IF NOT EXISTS idx_company_users_company ON company_users(company_id);
CREATE INDEX IF NOT EXISTS idx_company_users_user ON company_users(user_id);
CREATE INDEX IF NOT EXISTS idx_grants_employee ON grants(employee_id) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_grants_company ON grants(company_id);
CREATE INDEX IF NOT EXISTS idx_vesting_schedules_date ON vesting_schedules(vesting_date) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_vesting_schedules_grant ON vesting_schedules(grant_id);
CREATE INDEX IF NOT EXISTS idx_transfers_company_date ON share_transfers(company_id, transfer_date DESC);
CREATE INDEX IF NOT EXISTS idx_market_data_symbol_date ON market_data(tadawul_symbol, trading_date DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_company_timestamp ON audit_logs(company_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_unread ON notifications(recipient_user_id) WHERE read_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_portfolios_employee ON portfolios(employee_id);
CREATE INDEX IF NOT EXISTS idx_portfolios_company ON portfolios(company_id);

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
DO $$ BEGIN
  CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON employees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TRIGGER update_incentive_plans_updated_at BEFORE UPDATE ON incentive_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TRIGGER update_grants_updated_at BEFORE UPDATE ON grants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TRIGGER update_portfolios_updated_at BEFORE UPDATE ON portfolios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Grant number generation
CREATE SEQUENCE IF NOT EXISTS grant_number_seq;

CREATE OR REPLACE FUNCTION generate_grant_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.grant_number := 'GR-' || 
    TO_CHAR(NEW.created_at, 'YYYYMMDD') || '-' || 
    LPAD(nextval('grant_number_seq')::text, 6, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
  CREATE TRIGGER generate_grant_number_trigger
    BEFORE INSERT ON grants
    FOR EACH ROW
    WHEN (NEW.grant_number IS NULL)
    EXECUTE FUNCTION generate_grant_number();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Initialize grant shares
CREATE OR REPLACE FUNCTION initialize_grant_shares()
RETURNS TRIGGER AS $$
BEGIN
  NEW.remaining_unvested_shares := NEW.total_shares;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
  CREATE TRIGGER initialize_grant_shares_trigger
    BEFORE INSERT ON grants
    FOR EACH ROW
    WHEN (NEW.remaining_unvested_shares IS NULL)
    EXECUTE FUNCTION initialize_grant_shares();
EXCEPTION WHEN duplicate_object THEN null;
END $$;