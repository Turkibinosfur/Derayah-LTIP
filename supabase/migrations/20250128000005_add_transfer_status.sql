/*
  Add Transfer Status to share_transfers table
  
  Problem: We need to track transfer requests with status "pending" and "transferred"
  
  Solution: Add a status field to share_transfers table to track transfer request status
*/

-- Add status column to share_transfers table
ALTER TABLE share_transfers 
ADD COLUMN IF NOT EXISTS status text DEFAULT 'pending' CHECK (status IN ('pending', 'transferred', 'cancelled'));

-- Update existing records: if processed_at is set, status should be 'transferred'
UPDATE share_transfers 
SET status = 'transferred' 
WHERE processed_at IS NOT NULL AND status = 'pending';

-- Create index for status filtering
CREATE INDEX IF NOT EXISTS idx_share_transfers_status ON share_transfers(status);
CREATE INDEX IF NOT EXISTS idx_share_transfers_company_status ON share_transfers(company_id, status);




