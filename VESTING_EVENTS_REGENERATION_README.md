# Vesting Events Regeneration Guide

## Summary of Fixes Applied

We've fixed two critical issues with vesting event generation:

1. **Performance/Hybrid Templates**: Now generate proper milestone dates instead of all events on the same date
2. **Event Type**: Now correctly uses `event_type` from database instead of hardcoded logic

## What Was Fixed

### 1. Generate Default Milestones (`src/pages/VestingSchedules.tsx`)
- **Before**: Performance/hybrid templates created a single milestone with `months_from_start: null`, causing all vesting events to have the same date
- **After**: All templates now generate milestones with proper dates based on cliff_months, total_duration_months, and vesting_frequency

### 2. Event Type Logic (`src/components/InteractiveVestingTimeline.tsx`)
- **Before**: Hardcoded event type based on sequence number
- **After**: Reads `event_type` from database record with fallback for old data

### 3. Added Regeneration Functions (`src/lib/vestingUtils.ts`)
- `regenerateVestingEventsForGrant(grantId)`: Regenerate events for a specific grant
- `regenerateAllVestingEvents(companyId?)`: Regenerate events for all grants

## Regenerating Existing Vesting Events

**Important**: Existing grants with incorrect vesting events won't be automatically fixed. You need to regenerate them.

### Option 1: Regenerate All Grants (Recommended)

Run this SQL script in your Supabase SQL Editor:

```sql
-- File: regenerate_all_vesting_events.sql
```

This will:
- Find all grants with vesting schedule templates
- Delete existing vesting_events for those grants
- Recreate them with correct dates and event types

### Option 2: Regenerate Specific Grant

For the grant you mentioned (GR-20251101-000011):

```sql
-- File: regenerate_grant_GR-20251101-000011.sql
```

Or manually:

```sql
DO $$
DECLARE
  v_grant_id uuid := (SELECT id FROM grants WHERE grant_number = 'GR-20251101-000011');
BEGIN
  DELETE FROM vesting_events WHERE grant_id = v_grant_id;
  -- The system will auto-generate new events on next access
END $$;
```

### Option 3: Using JavaScript Functions

After the frontend is updated, you can use these in the browser console:

```javascript
// Regenerate for one grant
await regenerateVestingEventsForGrant('grant-id-here');

// Regenerate all grants
await regenerateAllVestingEvents();

// Regenerate for one company
await regenerateAllVestingEvents('company-id-here');
```

## Steps to Apply the Fix

1. ✅ **Fix 1 Applied**: VestingSchedules.tsx now generates proper milestones for all template types
2. ✅ **Fix 2 Applied**: InteractiveVestingTimeline.tsx now uses event_type from database
3. ✅ **Regeneration Functions Added**: vestingUtils.ts has helper functions
4. ⚠️ **YOU NEED TO**: Run regeneration SQL scripts to fix existing grants

## Testing

After regenerating vesting events, verify:

1. **Dates are correct**: Events should be spread over time (not all on same date)
2. **Event types are correct**: Should show proper types (cliff, time_based, performance) instead of all "performance"
3. **Shares sum correctly**: Total shares in events should match grant total_shares
4. **Sequence is correct**: Events should be in proper order

## Example: Before vs After

### Before (Incorrect)
- Event 1: 2023-10-01, 16 shares, PERFORMANCE
- Event 2: 2023-10-01, 16 shares, PERFORMANCE  
- Event 3: 2023-10-01, 18 shares, PERFORMANCE

### After (Correct)
- Event 1: 2024-01-01, 16 shares, CLIFF
- Event 2: 2024-04-01, 16 shares, TIME_BASED
- Event 3: 2024-07-01, 18 shares, TIME_BASED

## Questions?

If you encounter issues:
1. Check that the template has proper milestones
2. Verify the grant has a `vesting_schedule_template_id` linked
3. Check console for error messages
4. Ensure the SQL scripts ran successfully

