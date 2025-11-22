-- Fix RLS policy for vesting_events to allow company users to insert
-- (similar to how grants can be inserted by any company user)

DROP POLICY IF EXISTS "Admins can insert vesting events" ON vesting_events;
DROP POLICY IF EXISTS "Admins can update vesting events" ON vesting_events;

-- Allow any company user to insert vesting events for their company
CREATE POLICY "Company users can insert vesting events"
  ON vesting_events FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
    )
  );

-- Allow any company user to update vesting events for their company
CREATE POLICY "Company users can update vesting events"
  ON vesting_events FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid()
    )
  );

