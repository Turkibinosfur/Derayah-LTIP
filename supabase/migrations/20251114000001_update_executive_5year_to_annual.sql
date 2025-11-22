-- Update Executive 5-Year Vesting schedule to use annual frequency
-- This ensures 5 vesting events (1 cliff + 4 annual periods) instead of 17 (1 cliff + 16 quarterly)

DO $$
DECLARE
  v_company_id uuid;
  v_executive_schedule_id uuid;
BEGIN
  -- Get Derayah company ID
  SELECT id INTO v_company_id
  FROM companies
  WHERE company_name_en = 'Derayah Financial';
  
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Derayah Financial company not found';
  END IF;

  -- Find the Executive 5-Year Vesting schedule
  SELECT id INTO v_executive_schedule_id
  FROM vesting_schedules
  WHERE company_id = v_company_id
  AND name = 'Executive 5-Year Vesting'
  AND is_template = true
  LIMIT 1;

  IF v_executive_schedule_id IS NOT NULL THEN
    -- Update the schedule to use annual frequency
    UPDATE vesting_schedules
    SET 
      vesting_frequency = 'annually',
      description = 'Executive vesting schedule: 5 years total, 1-year cliff, annual vesting thereafter',
      updated_at = now()
    WHERE id = v_executive_schedule_id;

    RAISE NOTICE 'Updated Executive 5-Year Vesting schedule (ID: %) to use annual frequency', v_executive_schedule_id;

    -- Delete existing milestones if any (they will be regenerated with annual frequency)
    DELETE FROM vesting_milestones
    WHERE vesting_schedule_id = v_executive_schedule_id;

    RAISE NOTICE 'Deleted existing milestones for Executive 5-Year Vesting schedule (will be regenerated with annual frequency)';
  ELSE
    RAISE NOTICE 'Executive 5-Year Vesting schedule not found, skipping update';
  END IF;
END $$;


