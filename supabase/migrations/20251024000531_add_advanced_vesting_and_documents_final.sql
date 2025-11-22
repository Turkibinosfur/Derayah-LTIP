/*
  # Advanced Vesting & Document Management System

  ## 1. New Tables for Advanced Vesting

  ### `vesting_schedules` - Custom vesting schedule templates
  ### `vesting_milestones` - Individual milestones within schedules  
  ### `performance_metrics` - Performance criteria for vesting
  ### `accelerated_vesting_rules` - Rules for accelerated vesting
  ### `grant_modifications` - Audit trail for grant amendments

  ## 2. New Tables for Document Management

  ### `document_templates` - Templates for generating documents
  ### `generated_documents` - Generated documents from templates
  ### `document_signatures` - E-signature tracking
  ### `document_versions` - Version control for documents

  ## 3. Security
  - RLS enabled on all tables
  - Company-scoped access with proper admin role checks
*/

-- Create enums
CREATE TYPE vesting_schedule_type AS ENUM ('time_based', 'performance_based', 'hybrid');
CREATE TYPE milestone_type AS ENUM ('time', 'performance', 'hybrid');
CREATE TYPE vesting_frequency AS ENUM ('monthly', 'quarterly', 'annually');
CREATE TYPE performance_metric_type AS ENUM ('financial', 'operational', 'personal');
CREATE TYPE acceleration_trigger AS ENUM ('termination_without_cause', 'resignation_good_leaver', 'change_of_control', 'ipo', 'acquisition', 'death', 'disability');
CREATE TYPE modification_type AS ENUM ('vesting_schedule_change', 'acceleration', 'quantity_change', 'termination', 'cancellation');
CREATE TYPE document_type_enum AS ENUM ('grant_agreement', 'vesting_schedule', 'exercise_notice', 'amendment', 'termination_notice');
CREATE TYPE document_status AS ENUM ('draft', 'pending_signature', 'signed', 'voided', 'expired');
CREATE TYPE signer_role AS ENUM ('employee', 'company_rep', 'witness');
CREATE TYPE signature_method AS ENUM ('electronic', 'yesser', 'manual');
CREATE TYPE signature_status AS ENUM ('pending', 'signed', 'declined', 'expired');

-- Vesting Schedules
CREATE TABLE vesting_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  schedule_type vesting_schedule_type NOT NULL DEFAULT 'time_based',
  total_duration_months integer NOT NULL DEFAULT 48,
  cliff_months integer DEFAULT 12,
  vesting_frequency vesting_frequency NOT NULL DEFAULT 'monthly',
  is_template boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE vesting_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view vesting schedules for their company"
  ON vesting_schedules FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can insert vesting schedules"
  ON vesting_schedules FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users 
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  );

CREATE POLICY "Admins can update vesting schedules"
  ON vesting_schedules FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users 
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users 
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  );

-- Performance Metrics
CREATE TABLE performance_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  metric_type performance_metric_type NOT NULL DEFAULT 'operational',
  unit_of_measure text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE performance_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view performance metrics for their company"
  ON performance_metrics FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage performance metrics"
  ON performance_metrics FOR ALL
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users 
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users 
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  );

-- Vesting Milestones
CREATE TABLE vesting_milestones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vesting_schedule_id uuid NOT NULL REFERENCES vesting_schedules(id) ON DELETE CASCADE,
  milestone_type milestone_type NOT NULL DEFAULT 'time',
  sequence_order integer NOT NULL,
  vesting_percentage decimal(5,2) NOT NULL,
  months_from_start integer,
  performance_metric_id uuid REFERENCES performance_metrics(id),
  target_value decimal(20,2),
  actual_value decimal(20,2),
  achieved_at timestamptz,
  is_achieved boolean DEFAULT false
);

ALTER TABLE vesting_milestones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view milestones"
  ON vesting_milestones FOR SELECT
  TO authenticated
  USING (
    vesting_schedule_id IN (
      SELECT vs.id FROM vesting_schedules vs
      JOIN company_users cu ON cu.company_id = vs.company_id
      WHERE cu.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage milestones"
  ON vesting_milestones FOR ALL
  TO authenticated
  USING (
    vesting_schedule_id IN (
      SELECT vs.id FROM vesting_schedules vs
      JOIN company_users cu ON cu.company_id = vs.company_id
      WHERE cu.user_id = auth.uid() 
      AND cu.role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  )
  WITH CHECK (
    vesting_schedule_id IN (
      SELECT vs.id FROM vesting_schedules vs
      JOIN company_users cu ON cu.company_id = vs.company_id
      WHERE cu.user_id = auth.uid() 
      AND cu.role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  );

-- Accelerated Vesting Rules
CREATE TABLE accelerated_vesting_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  rule_name text NOT NULL,
  trigger_event acceleration_trigger NOT NULL,
  acceleration_percentage decimal(5,2) NOT NULL,
  applies_to_plan_id uuid REFERENCES incentive_plans(id),
  conditions jsonb DEFAULT '{}',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE accelerated_vesting_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view accelerated vesting rules"
  ON accelerated_vesting_rules FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage accelerated vesting rules"
  ON accelerated_vesting_rules FOR ALL
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users 
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin', 'legal_admin')
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users 
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin', 'legal_admin')
    )
  );

-- Grant Modifications
CREATE TABLE grant_modifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  grant_id uuid NOT NULL REFERENCES grants(id) ON DELETE CASCADE,
  modified_by uuid NOT NULL REFERENCES auth.users(id),
  modification_type modification_type NOT NULL,
  previous_values jsonb DEFAULT '{}',
  new_values jsonb DEFAULT '{}',
  reason text,
  approved_by uuid REFERENCES auth.users(id),
  approved_at timestamptz,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE grant_modifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view grant modifications"
  ON grant_modifications FOR SELECT
  TO authenticated
  USING (
    grant_id IN (
      SELECT g.id FROM grants g
      JOIN employees e ON e.id = g.employee_id
      JOIN company_users cu ON cu.company_id = e.company_id
      WHERE cu.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can create grant modifications"
  ON grant_modifications FOR INSERT
  TO authenticated
  WITH CHECK (
    grant_id IN (
      SELECT g.id FROM grants g
      JOIN employees e ON e.id = g.employee_id
      JOIN company_users cu ON cu.company_id = e.company_id
      WHERE cu.user_id = auth.uid() 
      AND cu.role IN ('super_admin', 'hr_admin', 'finance_admin')
    )
  );

-- Document Templates
CREATE TABLE document_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  template_name text NOT NULL,
  document_type document_type_enum NOT NULL,
  language text DEFAULT 'en',
  template_content text NOT NULL,
  merge_fields jsonb DEFAULT '[]',
  is_active boolean DEFAULT true,
  version integer DEFAULT 1,
  created_by uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE document_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view document templates"
  ON document_templates FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage document templates"
  ON document_templates FOR ALL
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users 
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin', 'legal_admin')
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users 
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin', 'legal_admin')
    )
  );

-- Generated Documents
CREATE TABLE generated_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  grant_id uuid REFERENCES grants(id) ON DELETE CASCADE,
  template_id uuid REFERENCES document_templates(id),
  document_type text NOT NULL,
  document_name text NOT NULL,
  document_content text,
  storage_url text,
  file_size bigint,
  mime_type text DEFAULT 'application/pdf',
  status document_status DEFAULT 'draft',
  generated_at timestamptz DEFAULT now(),
  version integer DEFAULT 1
);

ALTER TABLE generated_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view all company documents"
  ON generated_documents FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users 
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin', 'legal_admin', 'finance_admin')
    )
  );

CREATE POLICY "Employees can view their own documents"
  ON generated_documents FOR SELECT
  TO authenticated
  USING (
    employee_id IN (
      SELECT id FROM employees WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage documents"
  ON generated_documents FOR ALL
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users 
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin', 'legal_admin')
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users 
      WHERE user_id = auth.uid() 
      AND role IN ('super_admin', 'hr_admin', 'legal_admin')
    )
  );

-- Document Signatures
CREATE TABLE document_signatures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id uuid NOT NULL REFERENCES generated_documents(id) ON DELETE CASCADE,
  signer_id uuid REFERENCES auth.users(id),
  signer_role signer_role NOT NULL,
  signer_name text NOT NULL,
  signer_email text NOT NULL,
  signature_method signature_method NOT NULL DEFAULT 'electronic',
  signature_data text,
  ip_address text,
  signed_at timestamptz,
  yesser_transaction_id text,
  status signature_status DEFAULT 'pending',
  requested_at timestamptz DEFAULT now()
);

ALTER TABLE document_signatures ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view signatures for company documents"
  ON document_signatures FOR SELECT
  TO authenticated
  USING (
    document_id IN (
      SELECT gd.id FROM generated_documents gd
      JOIN company_users cu ON cu.company_id = gd.company_id
      WHERE cu.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can sign their own documents"
  ON document_signatures FOR UPDATE
  TO authenticated
  USING (signer_id = auth.uid())
  WITH CHECK (signer_id = auth.uid());

CREATE POLICY "Admins can manage signatures"
  ON document_signatures FOR ALL
  TO authenticated
  USING (
    document_id IN (
      SELECT gd.id FROM generated_documents gd
      JOIN company_users cu ON cu.company_id = gd.company_id
      WHERE cu.user_id = auth.uid() 
      AND cu.role IN ('super_admin', 'hr_admin', 'legal_admin')
    )
  )
  WITH CHECK (
    document_id IN (
      SELECT gd.id FROM generated_documents gd
      JOIN company_users cu ON cu.company_id = gd.company_id
      WHERE cu.user_id = auth.uid() 
      AND cu.role IN ('super_admin', 'hr_admin', 'legal_admin')
    )
  );

-- Document Versions
CREATE TABLE document_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id uuid NOT NULL REFERENCES generated_documents(id) ON DELETE CASCADE,
  version_number integer NOT NULL,
  content_hash text NOT NULL,
  changed_by uuid NOT NULL REFERENCES auth.users(id),
  change_summary text,
  previous_content text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE document_versions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view document versions"
  ON document_versions FOR SELECT
  TO authenticated
  USING (
    document_id IN (
      SELECT gd.id FROM generated_documents gd
      JOIN company_users cu ON cu.company_id = gd.company_id
      WHERE cu.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can create document versions"
  ON document_versions FOR INSERT
  TO authenticated
  WITH CHECK (
    document_id IN (
      SELECT gd.id FROM generated_documents gd
      JOIN company_users cu ON cu.company_id = gd.company_id
      WHERE cu.user_id = auth.uid() 
      AND cu.role IN ('super_admin', 'hr_admin', 'legal_admin')
    )
  );

-- Add columns to grants table for advanced vesting
ALTER TABLE grants ADD COLUMN IF NOT EXISTS vesting_schedule_id uuid REFERENCES vesting_schedules(id);
ALTER TABLE grants ADD COLUMN IF NOT EXISTS custom_vesting_data jsonb DEFAULT '{}';

-- Create indexes for performance
CREATE INDEX idx_vesting_schedules_company ON vesting_schedules(company_id);
CREATE INDEX idx_vesting_milestones_schedule ON vesting_milestones(vesting_schedule_id);
CREATE INDEX idx_performance_metrics_company ON performance_metrics(company_id);
CREATE INDEX idx_accelerated_rules_company ON accelerated_vesting_rules(company_id);
CREATE INDEX idx_grant_modifications_grant ON grant_modifications(grant_id);
CREATE INDEX idx_document_templates_company ON document_templates(company_id);
CREATE INDEX idx_generated_documents_company ON generated_documents(company_id);
CREATE INDEX idx_generated_documents_employee ON generated_documents(employee_id);
CREATE INDEX idx_document_signatures_document ON document_signatures(document_id);
CREATE INDEX idx_document_versions_document ON document_versions(document_id);
