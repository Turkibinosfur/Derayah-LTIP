# Quick Fix for Grant GR-20251101-000011

## The Problem
The vesting events haven't changed because the template likely doesn't have proper milestones created yet.

## Step-by-Step Fix

### Step 1: Check What's Linked
Run this SQL to see what template is linked:

```sql
-- File: debug_grant_template.sql
```

This will show if the template has any milestones.

### Step 2: Regenerate (Choose One)

**Option A: If template has NO milestones**
Run: `fix_and_regenerate_grant_GR-20251101-000011.sql`
- This creates the milestones first, then regenerates events

**Option B: If template HAS milestones**  
Run: `regenerate_grant_GR-20251101-000011.sql`

**Option C: Simplest approach**
Run: `simple_delete_and_regenerate.sql`
Then refresh the grant details page in the UI

### Step 3: Verify
After running the script, refresh the grant details page and check:
- ✅ Dates are different (not all 2023-10-01)
- ✅ Event types are correct (not all "PERFORMANCE")
- ✅ Shares sum to 50 total

## Most Likely Issue

Your template was created BEFORE we fixed the milestone generation code, so it probably has no milestones (or has just one with null months_from_start).

**Run `fix_and_regenerate_grant_GR-20251101-000011.sql` - it will handle everything!**

