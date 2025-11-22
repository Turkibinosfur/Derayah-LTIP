/*
  # Create Subscriptions and Buyback Requests Tables
  
  This migration creates:
  1. company_subscriptions - Manage company subscription plans
  2. buyback_requests - Manage employee share buyback requests
  
  Both tables are accessible by super admins for SaaS management.
*/

-- =====================================================
-- SUBSCRIPTIONS TABLE
-- =====================================================
-- Drop existing policies first (if tables exist)
DROP POLICY IF EXISTS "Super admins can view all subscriptions" ON company_subscriptions;
DROP POLICY IF EXISTS "Company admins can view own subscription" ON company_subscriptions;
DROP POLICY IF EXISTS "Super admins can manage subscriptions" ON company_subscriptions;

CREATE TABLE IF NOT EXISTS company_subscriptions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  subscription_plan text NOT NULL CHECK (subscription_plan IN ('basic', 'professional', 'enterprise', 'custom')),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'cancelled', 'expired', 'trial')),
  billing_cycle text NOT NULL DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'quarterly', 'annual')),
  start_date date NOT NULL DEFAULT CURRENT_DATE,
  end_date date,
  renewal_date date,
  price_per_cycle numeric NOT NULL DEFAULT 0,
  currency text NOT NULL DEFAULT 'SAR',
  max_employees integer,
  max_plans integer,
  features jsonb DEFAULT '{}',
  payment_method text,
  payment_status text DEFAULT 'paid' CHECK (payment_status IN ('paid', 'pending', 'failed', 'refunded')),
  last_payment_date date,
  next_payment_date date,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id),
  UNIQUE(company_id)
);

ALTER TABLE company_subscriptions ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- BUYBACK REQUESTS TABLE
-- =====================================================
-- Drop existing policies first (if tables exist)
DROP POLICY IF EXISTS "Super admins can view all buyback requests" ON buyback_requests;
DROP POLICY IF EXISTS "Company admins can view company buyback requests" ON buyback_requests;
DROP POLICY IF EXISTS "Super admins can manage buyback requests" ON buyback_requests;
DROP POLICY IF EXISTS "Company admins can create buyback requests" ON buyback_requests;

CREATE TABLE IF NOT EXISTS buyback_requests (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  request_number text UNIQUE NOT NULL,
  employee_id uuid REFERENCES employees(id),
  grant_id uuid REFERENCES grants(id),
  shares_requested numeric NOT NULL,
  requested_price_per_share numeric,
  request_type text NOT NULL DEFAULT 'voluntary' CHECK (request_type IN ('voluntary', 'mandatory', 'termination')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'processing', 'completed', 'cancelled')),
  request_date date NOT NULL DEFAULT CURRENT_DATE,
  requested_by uuid REFERENCES auth.users(id),
  approved_by uuid REFERENCES auth.users(id),
  approved_at timestamptz,
  rejection_reason text,
  processing_notes text,
  completion_date date,
  actual_price_per_share numeric,
  total_amount numeric,
  payment_status text DEFAULT 'pending' CHECK (payment_status IN ('pending', 'processing', 'paid', 'failed')),
  payment_date date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE buyback_requests ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- INDEXES
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_company_subscriptions_company_id ON company_subscriptions(company_id);
CREATE INDEX IF NOT EXISTS idx_company_subscriptions_status ON company_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_buyback_requests_company_id ON buyback_requests(company_id);
CREATE INDEX IF NOT EXISTS idx_buyback_requests_status ON buyback_requests(status);
CREATE INDEX IF NOT EXISTS idx_buyback_requests_employee_id ON buyback_requests(employee_id);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Subscriptions: Super admins can view all, company admins can view their own
CREATE POLICY "Super admins can view all subscriptions"
  ON company_subscriptions FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_super_admin_memberships m
      WHERE m.user_id = auth.uid()
    )
  );

CREATE POLICY "Company admins can view own subscription"
  ON company_subscriptions FOR SELECT TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND role IN ('company_admin', 'finance_admin')
    )
  );

CREATE POLICY "Super admins can manage subscriptions"
  ON company_subscriptions FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_super_admin_memberships m
      WHERE m.user_id = auth.uid()
    )
  );

-- Buyback requests: Super admins can view all, company admins can view their company's
CREATE POLICY "Super admins can view all buyback requests"
  ON buyback_requests FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_super_admin_memberships m
      WHERE m.user_id = auth.uid()
    )
  );

CREATE POLICY "Company admins can view company buyback requests"
  ON buyback_requests FOR SELECT TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND role IN ('company_admin', 'finance_admin', 'hr_admin')
    )
  );

CREATE POLICY "Super admins can manage buyback requests"
  ON buyback_requests FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_super_admin_memberships m
      WHERE m.user_id = auth.uid()
    )
  );

CREATE POLICY "Company admins can create buyback requests"
  ON buyback_requests FOR INSERT TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND role IN ('company_admin', 'finance_admin', 'hr_admin')
    )
  );

-- =====================================================
-- TRIGGERS
-- =====================================================
CREATE OR REPLACE FUNCTION update_subscription_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS update_company_subscriptions_updated_at ON company_subscriptions;
DROP TRIGGER IF EXISTS update_buyback_requests_updated_at ON buyback_requests;

CREATE TRIGGER update_company_subscriptions_updated_at
  BEFORE UPDATE ON company_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_subscription_updated_at();

CREATE TRIGGER update_buyback_requests_updated_at
  BEFORE UPDATE ON buyback_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_subscription_updated_at();

