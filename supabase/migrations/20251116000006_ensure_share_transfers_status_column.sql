/*
  Ensure share_transfers.status column exists
  
  Problem: The transferVestingEvent function tries to insert a 'status' field into share_transfers,
  but the column doesn't exist in the database, causing "Could not find the 'status' column" error.
  
  Solution: Add the status column if it doesn't exist, with proper constraints and indexes.
*/

-- Add status column to share_transfers table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'share_transfers' 
    AND column_name = 'status'
  ) THEN
    ALTER TABLE share_transfers 
    ADD COLUMN status text DEFAULT 'pending' CHECK (status IN ('pending', 'transferred', 'cancelled'));
    
    RAISE NOTICE '✅ Added status column to share_transfers table';
  ELSE
    RAISE NOTICE 'ℹ️ status column already exists in share_transfers table';
  END IF;
END $$;

-- Update existing records: if processed_at is set, status should be 'transferred'
UPDATE share_transfers 
SET status = 'transferred' 
WHERE processed_at IS NOT NULL 
  AND (status IS NULL OR status = 'pending');

-- Create indexes for status filtering if they don't exist
CREATE INDEX IF NOT EXISTS idx_share_transfers_status ON share_transfers(status);
CREATE INDEX IF NOT EXISTS idx_share_transfers_company_status ON share_transfers(company_id, status);

-- Verify the column was created
SELECT 
  '=== VERIFICATION: share_transfers.status column ===' as info;

SELECT 
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'share_transfers'
  AND column_name = 'status';

-- Show status distribution
SELECT 
  '=== Status Distribution ===' as info;

SELECT 
  status,
  COUNT(*) as count
FROM share_transfers
GROUP BY status
ORDER BY status;

