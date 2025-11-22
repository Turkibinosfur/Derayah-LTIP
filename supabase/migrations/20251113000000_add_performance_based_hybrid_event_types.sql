-- Add missing enum values to vesting_event_type
-- These values are needed to support performance-based and hybrid vesting events

-- Add 'performance_based' to vesting_event_type enum
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'performance_based' 
    AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'vesting_event_type')
  ) THEN
    ALTER TYPE vesting_event_type ADD VALUE 'performance_based';
  END IF;
END $$;

-- Add 'hybrid' to vesting_event_type enum
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'hybrid' 
    AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'vesting_event_type')
  ) THEN
    ALTER TYPE vesting_event_type ADD VALUE 'hybrid';
  END IF;
END $$;

-- Verify the enum now includes all required values
-- Expected values: 'cliff', 'time_based', 'performance', 'acceleration', 'performance_based', 'hybrid'
COMMENT ON TYPE vesting_event_type IS 'Vesting event types: cliff, time_based, performance, acceleration, performance_based, hybrid';



