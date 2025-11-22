# Cap Table RLS Policy Fix

## Problem
When trying to add new shareholders in the cap table management, you encountered this error:
```
Failed to add shareholder: new row violates row-level security policy for table "shareholders"
```

## Root Cause
The `shareholders` table and related cap table tables were missing from the database schema, causing RLS policy violations when trying to access them.

## Solution
Created comprehensive migrations to fix the missing tables and RLS policies:

### 1. Fixed Shareholders RLS Policies (`20250125000002_fix_shareholders_rls_policies.sql`)
- Added missing SELECT, UPDATE, DELETE policies for shareholders table
- Ensures users can only access shareholders for their own company

### 2. Created Shareholders Table (`20250125000003_create_shareholders_table.sql`)
- Complete shareholders table structure with all required fields
- Comprehensive RLS policies for all operations (SELECT, INSERT, UPDATE, DELETE)
- Performance indexes for optimal query performance
- Proper data validation with CHECK constraints

### 3. Created Cap Table Related Tables (`20250125000004_create_cap_table_tables.sql`)
- `funding_rounds`: Track investment rounds and valuations
- `dilution_scenarios`: Model dilution scenarios for planning
- `cap_table_snapshots`: Historical cap table data for tracking changes
- Complete RLS policies for all tables ensuring company data isolation

## Tables Created

### Shareholders Table
```sql
shareholders
├── id (uuid, PK)
├── company_id (uuid, FK -> companies)
├── name (text)
├── shareholder_type (enum: founder, investor, employee, advisor, other)
├── shares_owned (numeric)
├── ownership_percentage (numeric)
├── share_class (text)
├── investment_amount (numeric)
├── liquidation_preference (numeric)
├── preference_multiple (numeric)
├── is_active (boolean)
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

### Funding Rounds Table
```sql
funding_rounds
├── id (uuid, PK)
├── company_id (uuid, FK -> companies)
├── round_name (text)
├── round_type (enum: seed, series_a, series_b, series_c, series_d, pre_ipo, ipo, other)
├── amount_raised (numeric)
├── valuation_pre_money (numeric)
├── valuation_post_money (numeric)
├── share_price (numeric)
├── shares_issued (numeric)
├── closing_date (date)
├── notes (text)
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

### Dilution Scenarios Table
```sql
dilution_scenarios
├── id (uuid, PK)
├── company_id (uuid, FK -> companies)
├── scenario_name (text)
├── scenario_description (text)
├── scenario_config (jsonb)
├── results (jsonb)
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

### Cap Table Snapshots Table
```sql
cap_table_snapshots
├── id (uuid, PK)
├── company_id (uuid, FK -> companies)
├── snapshot_date (date)
├── snapshot_data (jsonb)
├── total_shares (numeric)
└── created_at (timestamptz)
```

## Security Features

### Row Level Security (RLS)
- **Company Isolation**: Users can only access data for their own company
- **Authentication Required**: All operations require valid authentication
- **Complete Coverage**: All CRUD operations (SELECT, INSERT, UPDATE, DELETE) are protected
- **Data Integrity**: Proper foreign key constraints and data validation

### Performance Optimization
- **Strategic Indexes**: Optimized for common query patterns
- **Company-based Indexing**: Fast lookups by company_id
- **Active Record Filtering**: Efficient filtering for active records

## How to Apply the Fix

1. **Run the Migrations**: Apply the three new migration files in order:
   ```bash
   # Migration 1: Fix existing RLS policies
   20250125000002_fix_shareholders_rls_policies.sql
   
   # Migration 2: Create shareholders table
   20250125000003_create_shareholders_table.sql
   
   # Migration 3: Create cap table related tables
   20250125000004_create_cap_table_tables.sql
   ```

2. **Verify the Fix**: After running migrations, you should be able to:
   - Add new shareholders without RLS errors
   - View existing shareholders
   - Manage funding rounds
   - Create dilution scenarios
   - Track cap table snapshots

## Expected Results
- ✅ **No More RLS Errors**: Shareholder management will work properly
- ✅ **Complete Cap Table System**: Full functionality for cap table management
- ✅ **Data Security**: Company data remains properly isolated
- ✅ **Performance**: Optimized queries with proper indexing

The cap table management system should now work completely without any RLS policy violations.
