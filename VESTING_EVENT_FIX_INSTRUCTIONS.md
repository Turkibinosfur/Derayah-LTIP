# Fix for Vesting Event VE-011024-GR20-000

## Problem
When clicking "Vest" on a PERFORMANCE type vesting event, nothing changes - the event remains in "DUE" status.

## Root Causes
1. **Missing `remaining_unvested_shares` update**: The `process_vesting_event` function wasn't updating this field
2. **Performance condition check**: PERFORMANCE events require `performance_condition_met = true` if the grant has linked performance metrics
3. **Error handling**: Errors from the RPC function weren't being properly displayed

## Solution Steps

### Step 1: Apply the Migration
Apply the migration file to update the `process_vesting_event` function:

```bash
# If using Supabase CLI
supabase migration up

# Or manually run the SQL in:
# supabase/migrations/20251113000001_fix_process_vesting_event_function.sql
```

### Step 2: Fix the Specific Event (if needed)
If the event doesn't have linked performance metrics, you can manually set `performance_condition_met = true`:

```sql
-- Find the event ID first
SELECT id, status, event_type, performance_condition_met, grant_id
FROM vesting_events
WHERE grant_id = (
  SELECT id FROM grants WHERE grant_number = 'GR-20251102-000015'
)
AND sequence_number = 0;

-- If no linked performance metrics, set performance_condition_met = true
UPDATE vesting_events
SET 
  performance_condition_met = true,
  performance_notes = 'Performance condition confirmed',
  updated_at = now()
WHERE id = '<event_id_from_above>'
AND NOT EXISTS (
  SELECT 1 
  FROM grant_performance_metrics gpm 
  WHERE gpm.grant_id = vesting_events.grant_id
);
```

### Step 3: Test the Fix
1. Refresh the Vesting Events page
2. Click "Vest" on the event
3. You should either:
   - See a performance confirmation modal (if metrics are linked)
   - Or the event should vest successfully (if no metrics are linked)

## What Was Fixed

### 1. Database Function (`process_vesting_event`)
- ✅ Now updates `remaining_unvested_shares` when vesting
- ✅ Added error handling with row count checks
- ✅ Better error messages for performance condition failures

### 2. Frontend Error Handling
- ✅ Now properly checks RPC response for success/failure
- ✅ Displays actual error messages from the database function

## Expected Behavior After Fix

1. **For PERFORMANCE events WITH linked metrics**:
   - Clicking "Vest" should show a performance confirmation modal
   - After confirming metrics, the event will vest
   - Status changes to "VESTED"
   - Action button changes to "Transfer"

2. **For PERFORMANCE events WITHOUT linked metrics**:
   - Clicking "Vest" should immediately vest the event
   - Status changes to "VESTED"
   - Action button changes to "Transfer"

3. **After vesting**:
   - Grant's `vested_shares` increases
   - Grant's `remaining_unvested_shares` decreases
   - Event status is "VESTED"
   - Page refreshes to show updated status

## Troubleshooting

If the issue persists after applying the migration:

1. **Check browser console** for any error messages
2. **Check the database** to see if the event status actually changed:
   ```sql
   SELECT id, status, performance_condition_met, processed_at
   FROM vesting_events
   WHERE grant_id = (SELECT id FROM grants WHERE grant_number = 'GR-20251102-000015')
   AND sequence_number = 0;
   ```

3. **Verify the migration was applied**:
   ```sql
   SELECT routine_name, routine_definition
   FROM information_schema.routines
   WHERE routine_name = 'process_vesting_event';
   ```
   Look for `remaining_unvested_shares` in the function definition.

4. **Check if performance metrics are linked**:
   ```sql
   SELECT gpm.*
   FROM grant_performance_metrics gpm
   JOIN grants g ON g.id = gpm.grant_id
   WHERE g.grant_number = 'GR-20251102-000015';
   ```

