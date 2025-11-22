# Self-Service Company Onboarding - Progress Summary

## Date: November 11, 2025

## Migration File
`supabase/migrations/20251111093000_self_service_company_onboarding.sql`

## What Has Been Implemented

### 1. Onboarding Progress Tracking Table
- **Table**: `company_onboarding_progress`
- **Purpose**: Tracks completion status of onboarding steps for each company
- **Fields**:
  - `company_id` (primary key, references companies)
  - `has_pool` - ESOP pool created
  - `has_plan` - Incentive plan created
  - `has_employee` - Employees added
  - `has_grant` - Grants created
  - `completed_at` - Timestamp when all steps are complete
  - `created_at`, `updated_at` - Audit timestamps

### 2. Row Level Security (RLS)
- RLS enabled on `company_onboarding_progress` table
- Policies implemented:
  - **View**: Company users can view their company's onboarding progress
  - **Update**: Company users can update their company's onboarding progress
- Both policies check `company_users` table for active user-company associations

### 3. RPC Functions

#### `onboard_self_service_company()`
- **Purpose**: Creates a new company and sets up the primary admin user
- **Parameters**:
  - `p_company_name_en` (required)
  - `p_company_name_ar` (optional, defaults to English name)
  - `p_phone` (optional)
  - `p_user_id` (must match authenticated user)
- **Actions**:
  - Creates company record with temporary symbol and CR number
  - Sets verification_status to 'pending'
  - Adds metadata with onboarding_status: 'in_progress' and source: 'self_service'
  - Creates company_users record with 'company_admin' role and full permissions
  - Sets company.admin_user_id
  - Initializes onboarding progress record

#### `complete_company_onboarding_step()`
- **Purpose**: Marks a specific onboarding step as complete
- **Parameters**:
  - `p_step` - One of: 'pool', 'plan', 'employee', 'grant'
- **Actions**:
  - Finds user's primary company (first active company association)
  - Updates the corresponding boolean flag
  - Sets `completed_at` when all steps are complete
  - Returns the updated progress record

### 4. Security
- Both RPC functions use `SECURITY DEFINER` with proper authorization checks
- `onboard_self_service_company` verifies user_id matches authenticated user
- `complete_company_onboarding_step` uses company_users table to find user's company
- Functions granted to `authenticated` role

## Next Steps (To Continue Later)

1. **Frontend Integration**
   - Create onboarding UI/flow for new company registration
   - Integrate with Supabase Auth sign-up
   - Call `onboard_self_service_company` after user registration
   - Build onboarding wizard UI showing progress steps
   - Call `complete_company_onboarding_step` as user completes each step

2. **Testing**
   - Test the migration in development environment
   - Verify RLS policies work correctly
   - Test RPC functions with various scenarios
   - Test edge cases (duplicate companies, missing data, etc.)

3. **Enhancements (Optional)**
   - Add validation for company name uniqueness
   - Add email verification requirement
   - Add onboarding step validation (e.g., verify pool actually exists before marking complete)
   - Add onboarding analytics/tracking
   - Add ability to skip steps or mark steps complete automatically based on actual data

4. **Documentation**
   - Update API documentation
   - Create user guide for self-service onboarding
   - Document the onboarding flow

## Notes
- Migration is ready to be applied
- All SQL syntax appears correct
- RLS policies follow existing patterns in the codebase
- Functions use proper error handling and validation


