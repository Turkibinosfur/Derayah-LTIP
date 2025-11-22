-- Add performance indexes to optimize query performance
-- This migration addresses N+1 query problems by adding composite indexes
-- for common query patterns used in the portal

-- Index for loading grants with vesting events by employee and status
-- Used in EmployeeVesting page
CREATE INDEX IF NOT EXISTS idx_grants_employee_status_date 
  ON grants(employee_id, status, grant_date) 
  WHERE status IN ('active', 'pending_signature');

-- Index for loading vesting events by grant with sequence ordering
-- Used when loading vesting events for grants
CREATE INDEX IF NOT EXISTS idx_vesting_events_grant_sequence 
  ON vesting_events(grant_id, sequence_number);

-- Index for loading grants by plan (used in Grants page)
-- Optimizes the batch query for plan grants calculation
CREATE INDEX IF NOT EXISTS idx_grants_plan_status 
  ON grants(plan_id, status);

-- Composite index for company_id + status filtering in vesting events
-- Used in getAllVestingEvents and VestingEvents page
CREATE INDEX IF NOT EXISTS idx_vesting_events_company_status_date 
  ON vesting_events(company_id, status, vesting_date);

-- Index for company_users to speed up RLS policy checks
-- Many RLS policies use: company_id IN (SELECT company_id FROM company_users WHERE user_id = auth.uid())
CREATE INDEX IF NOT EXISTS idx_company_users_user_company 
  ON company_users(user_id, company_id);

-- Index for grants company_id lookups (if not already exists)
-- Used in various queries filtering by company
CREATE INDEX IF NOT EXISTS idx_grants_company_status 
  ON grants(company_id, status);

-- Index for vesting_events company_id + employee_id lookups
-- Used in employee-specific vesting event queries
CREATE INDEX IF NOT EXISTS idx_vesting_events_company_employee 
  ON vesting_events(company_id, employee_id);

-- Index for incentive_plans company lookups
CREATE INDEX IF NOT EXISTS idx_incentive_plans_company_status 
  ON incentive_plans(company_id, status);

COMMENT ON INDEX idx_grants_employee_status_date IS 'Optimizes EmployeeVesting page queries - loads grants by employee with status filter';
COMMENT ON INDEX idx_vesting_events_grant_sequence IS 'Optimizes vesting events loading by grant with sequence ordering';
COMMENT ON INDEX idx_grants_plan_status IS 'Optimizes Grants page - batch loading grants by plan';
COMMENT ON INDEX idx_vesting_events_company_status_date IS 'Optimizes VestingEvents page - filters by company, status, and date';
COMMENT ON INDEX idx_company_users_user_company IS 'Speeds up RLS policy checks for company_users table';
COMMENT ON INDEX idx_grants_company_status IS 'Optimizes company-wide grant queries';
COMMENT ON INDEX idx_vesting_events_company_employee IS 'Optimizes employee-specific vesting event queries';
COMMENT ON INDEX idx_incentive_plans_company_status IS 'Optimizes plan queries by company and status';

