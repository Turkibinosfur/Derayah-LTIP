-- Fix RLS policy on vesting_events to allow company_admin to UPDATE
-- This ensures that vesting event status can be updated to 'transferred' when transfer is initiated

-- Drop existing UPDATE policies
DROP POLICY IF EXISTS "Admins can update vesting events" ON vesting_events;
DROP POLICY IF EXISTS "Company users can update vesting events" ON vesting_events;

-- Create policy that includes company_admin
CREATE POLICY "Company users can update vesting events"
  ON vesting_events FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND is_active = true
      AND role IN ('super_admin', 'hr_admin', 'finance_admin', 'legal_admin', 'company_admin')
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
      AND is_active = true
      AND role IN ('super_admin', 'hr_admin', 'finance_admin', 'legal_admin', 'company_admin')
    )
  );

-- Note: This allows company_admin (like admin@derayah.com) to update vesting events
-- which is needed when transferring shares - the status should be updated to 'transferred'

