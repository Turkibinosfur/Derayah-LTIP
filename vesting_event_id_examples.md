# Vesting Event ID Format Examples

## Date-Based Unique ID Format

### New Format: VE-YYMMDD-UNIQ-SEQ

The vesting event ID combines the vesting date, a unique identifier, and sequence number to create truly unique identifiers.

### Format Breakdown
- **VE**: Vesting Event prefix
- **YYMMDD**: Vesting date (Year-Month-Day)
- **UNIQ**: 4-character unique identifier from Grant ID
- **SEQ**: 3-digit sequence number

### Examples

#### Christmas Day 2024 Events (Different Grants)
- `VE-241225-A1B2-001` → December 25, 2024, Grant A1B2..., Event #1
- `VE-241225-C3D4-001` → December 25, 2024, Grant C3D4..., Event #1
- `VE-241225-A1B2-002` → December 25, 2024, Grant A1B2..., Event #2

#### New Year 2025 Events (Different Employees)
- `VE-250101-E5F6-001` → January 1, 2025, Grant E5F6..., Event #1
- `VE-250101-G7H8-001` → January 1, 2025, Grant G7H8..., Event #1

#### March Quarter End 2025 (Same Employee, Different Grants)
- `VE-250331-I9J0-001` → March 31, 2025, Grant I9J0..., Event #1
- `VE-250331-K1L2-001` → March 31, 2025, Grant K1L2..., Event #1

## Display Format

**Main ID**: `VE-241225-A1B2-001` (date + unique + sequence)
**Date Info**: `25/12/2024` (human-readable date)
**Technical UUID**: `a1b2c3d4...` (for system reference)

## Benefits

✅ **Truly Unique**: Grant ID ensures no duplicates even on same date
✅ **Meaningful**: Instantly shows when the event vests
✅ **Sequential**: Clear ordering within each grant
✅ **Traceable**: Can identify which grant the event belongs to
✅ **Sortable**: Natural chronological sorting
✅ **Professional**: Clean, business-friendly format
✅ **Searchable**: Easy to find events by date range or grant

## Example Table Display

| Event ID | Employee | Plan | Type | Date |
|----------|----------|------|------|------|
| **VE-241225-A1B2-001**<br/>25/12/2024 | John Smith | LTIP | Cliff | 25/12/2024 |
| **VE-241225-C3D4-001**<br/>25/12/2024 | Jane Doe | LTIP | Cliff | 25/12/2024 |
| **VE-250331-A1B2-002**<br/>31/03/2025 | John Smith | LTIP | Vesting | 31/03/2025 |
| **VE-250630-E5F6-001**<br/>30/06/2025 | Mike Johnson | ESOP | Vesting | 30/06/2025 |

## Real-World Usage

- **Support**: "Please check event VE-241225-A1B2-001"
- **Reports**: "All Q1 events: VE-250101-* to VE-250331-*"  
- **Grant Tracking**: "Grant A1B2 events: VE-241225-A1B2-001, VE-250331-A1B2-002"
- **Scheduling**: "VE-250630-E5F6-001 is due next month"

## Uniqueness Guarantee

Even if multiple employees have vesting events on the same date, each will have a unique ID:
- Employee A, Grant A1B2: `VE-241225-A1B2-001`
- Employee B, Grant C3D4: `VE-241225-C3D4-001`
- Employee C, Grant E5F6: `VE-241225-E5F6-001`

**No duplicates possible!** ✅
