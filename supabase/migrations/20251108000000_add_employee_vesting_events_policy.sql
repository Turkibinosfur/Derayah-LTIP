-- Allow employees to view their own vesting events in the employee portal

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'vesting_events'
      AND policyname = 'Employees can view their own vesting events'
  ) THEN
    CREATE POLICY "Employees can view their own vesting events"
      ON public.vesting_events
      FOR SELECT
      TO authenticated
      USING (
        employee_id IN (
          SELECT id
          FROM public.employees
          WHERE user_id = auth.uid()
        )
      );
  END IF;
END;
$$;

