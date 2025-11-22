# Vesting Events Fix Summary

## Problems Fixed

### 1. Identical Vesting Dates
**Problem**: All vesting events for a grant had the same date.

**Root Cause**: Templates created without milestones, causing all vesting events to use the same base date.

**Solution**: 
- Auto-generate milestones when creating vesting schedules
- Auto-generate milestones if template has none when creating grants
- Milestones now have proper `months_from_start` values

### 2. Incorrect Event Types
**Problem**: All vesting events showed "time_based" regardless of the plan's vesting schedule type.

**Root Cause**: Auto-generated milestones always used `milestone_type: 'time'` regardless of the template's `schedule_type`.

**Solution**: 
- Use template's `schedule_type` to determine `milestone_type`
- Map schedule types correctly: `time_based` → `time`, `performance_based` → `performance`, `hybrid` → `hybrid`

### 3. Grant Vesting Start Date Validation
**Problem**: Grants could be created with vesting start dates before the plan's start date.

**Root Cause**: No validation on the vesting start date input.

**Solution**: 
- Added `min` attribute to vesting start date input using plan's start date
- Added error message if date is before plan start date

## Files Modified

### 1. `src/lib/vestingUtils.ts`
- Added auto-generation of milestones when template has none
- Use `template.schedule_type` to determine `milestoneType` for generated milestones
- Map milestone types: `time_based` → `time`, `performance_based` → `performance`, `hybrid` → `hybrid`

### 2. `src/pages/VestingSchedules.tsx`
- Auto-generate milestones when creating schedules (if none provided)
- Use `schedule_type` to determine `milestoneType` in both `generateDefaultMilestones` and `handleCreateSchedule`

### 3. `src/pages/Grants.tsx`
- Added `start_date` to Plan interface
- Added `start_date` to plans query
- Added `min` attribute to vesting start date input
- Added validation error message for invalid dates

## How It Works Now

### For New Vesting Schedules:
1. User creates a schedule with duration, cliff, frequency, and type
2. If no milestones provided, system auto-generates them based on settings
3. Milestones use the schedule type to determine milestone_type
4. Milestones saved to database

### For New Grants:
1. User selects a plan with a linked template
2. If template has no milestones, system generates them from template settings
3. Generated milestones use template's schedule_type
4. Vesting events created from milestones with proper dates
5. Event types derived from milestone types

### Event Type Mapping:
- **Template `schedule_type`: `time_based`** → Milestone `milestone_type`: `time` → Event `event_type`: `time_based`
- **Template `schedule_type`: `performance_based`** → Milestone `milestone_type`: `performance` → Event `event_type`: `performance`
- **Template `schedule_type`: `hybrid`** → Milestone `milestone_type`: `hybrid` → Event `event_type`: `hybrid`

## For Existing Grants

For grants created before these fixes with bad dates or event types:
1. Run `quick_check_latest_grant.sql` to diagnose the issue
2. Run `fix_and_regenerate_grant_[GRANT_NUMBER].sql` to fix that specific grant
3. Or create a generic fix script for all grants

## Testing Recommendations

1. **Create a new vesting schedule** with each type (time_based, performance_based, hybrid)
   - Verify milestones are auto-generated
   - Verify milestone types match schedule type
   
2. **Create a new grant** from a plan with each schedule type
   - Verify vesting dates are properly staggered
   - Verify event types match the schedule type
   
3. **Try to create a grant** with vesting start date before plan start
   - Verify the date picker prevents selecting invalid dates
   - Verify error message appears

4. **Check existing grants** that had issues
   - Run the fix SQL scripts
   - Verify dates and event types are corrected

