# Step-by-Step Instructions to Fix Vesting Events

## Overview
You need to apply the database migration and then regenerate vesting events for grant GR-20251101-000010 to fix the missing 2 shares.

---

## ✅ STEP 1: Apply Database Migration

### Option A: Using Supabase Dashboard (Easiest)

1. **Open Supabase Dashboard**
   - Go to https://app.supabase.com
   - Select your project

2. **Open SQL Editor**
   - Click "SQL Editor" in the left sidebar

3. **Run the Migration**
   - Click "New query"
   - Copy and paste the entire contents of:
     ```
     supabase/migrations/20250130000002_fix_vesting_trigger_for_templates.sql
     ```
   - Click "RUN" button
   - You should see: "Success. No rows returned"

### Option B: Using Supabase CLI (If you have it)

```bash
cd /Users/interfacesolutions/Desktop/Derayah.esop
supabase db push
```

---

## ✅ STEP 2: Regenerate Vesting Events

You have 3 options to regenerate the vesting events:

### Option A: Using UI (Easiest) ⭐ Recommended

1. **Open Company Portal**
   - Login to your company portal
   - Navigate to **"Vesting Events"** page

2. **Regenerate Events**
   - Click the **"Generate Events"** button at the top
   - The system will detect grant GR-20251101-000010 needs regeneration
   - Confirm the generation
   - Wait for completion

3. **Verify Results**
   - Filter by grant GR-20251101-000010
   - Check that total shares = 50 (not 48)

### Option B: Using SQL Script

1. **Open Supabase SQL Editor**
   - Go to SQL Editor

2. **Run the Utility Script**
   - Copy and paste the entire contents of:
     ```
     regenerate_vesting_events_utility.sql
     ```
   - Click "RUN"
   - This will DELETE existing events and show instructions

3. **Then Use UI**
   - Go to Vesting Events page
   - Click "Generate Events" button
   - Confirm regeneration

### Option C: Manual SQL Delete + UI Regeneration

If the scripts don't work, do it manually:

1. **Delete Existing Events**
   ```sql
   DELETE FROM vesting_events 
   WHERE grant_id = (
     SELECT id FROM grants WHERE grant_number = 'GR-20251101-000010'
   );
   ```

2. **Verify Deletion**
   ```sql
   SELECT COUNT(*) FROM vesting_events 
   WHERE grant_id = (
     SELECT id FROM grants WHERE grant_number = 'GR-20251101-000010'
   );
   -- Should return 0
   ```

3. **Regenerate via UI**
   - Go to Vesting Events page
   - Click "Generate Events" button

---

## ✅ STEP 3: Verify the Fix

### Verify in Supabase SQL Editor:

```sql
-- Check grant total vs event total
SELECT 
  g.grant_number,
  g.total_shares as grant_total,
  COALESCE(SUM(ve.shares_to_vest), 0) as events_total,
  (g.total_shares - COALESCE(SUM(ve.shares_to_vest), 0)) as difference
FROM grants g
LEFT JOIN vesting_events ve ON ve.grant_id = g.id
WHERE g.grant_number = 'GR-20251101-000010'
GROUP BY g.id, g.grant_number, g.total_shares;
```

**Expected Result:**
```
grant_number: GR-20251101-000010
grant_total: 50
events_total: 50
difference: 0 ✅
```

### Verify in UI:

1. Go to **Company Portal → Grants**
2. Find grant **GR-20251101-000010**
3. Click **"View"** or expand details
4. Check vesting timeline/events
5. Total should be **50 shares** ✅

---

## 🎯 Quick Summary

**What you need to do:**
1. ✅ Run migration SQL script
2. ✅ Regenerate vesting events (via UI or SQL)
3. ✅ Verify totals match

**Time required:** 5-10 minutes

**Risk level:** Low - we're just regenerating events with correct calculations

---

## ❓ Troubleshooting

### If "Generate Events" button doesn't work:
- Make sure you ran the migration first (STEP 1)
- Check browser console for errors
- Try using SQL delete method (Option C) instead

### If you see database errors:
- Check you're in the correct Supabase project
- Verify the migration ran successfully
- Make sure you have the latest code pulled from repository

### If shares still don't add up:
- Check the grant has a `vesting_schedule_template_id`
- Verify template has milestones defined
- Check browser console for JavaScript errors

---

## 📁 Files You Need

All files are already in your repository:

1. ✅ `supabase/migrations/20250130000002_fix_vesting_trigger_for_templates.sql` - Migration
2. ✅ `regenerate_vesting_events_utility.sql` - Utility script (optional)
3. ✅ Code fixes already in place in `src/lib/vestingUtils.ts` and `src/pages/VestingSchedules.tsx`

---

## ✅ Success Criteria

After completing all steps, you should see:

- ✅ Grant GR-20251101-000010 has **50 shares** in vesting events
- ✅ No missing fractional shares
- ✅ Last vesting event has remainder shares if applicable
- ✅ All vesting events display correctly in UI

---

## 📞 Need Help?

If you encounter issues:
1. Check the error message carefully
2. Look at browser console (F12) for JavaScript errors
3. Check Supabase logs for database errors
4. Verify all migration steps completed successfully

