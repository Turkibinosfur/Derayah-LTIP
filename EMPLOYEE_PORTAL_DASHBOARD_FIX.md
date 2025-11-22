# Employee Portal Dashboard Issue Fix

## Problem
The employee portal dashboard for `wajehah.com@gmail.com` is not showing the expected cards:
- Total Shares Granted card
- Vested Shares card  
- Unvested Shares card
- Your Grants
- Portfolio Value
- Quick Stats
- Performance History

## Root Cause Analysis

After examining the codebase, I found the issue:

1. **Same Person, Not Linked**: Khalid Al-Zahrani and `wajehah.com@gmail.com` are the same person
2. **Missing Auth Link**: Khalid's employee record is not linked to an authentication user
3. **No Login Credentials**: The employee record exists but has no auth user for login
4. **Existing Grant Data**: Khalid has complete grant data but can't access it due to missing auth link

## How the Dashboard Works

The `EmployeeDashboard.tsx` component works as follows:

1. **Authentication Check**: Gets the current authenticated user
2. **Employee Lookup**: Finds the employee record using `user_id`
3. **Data Loading**: Loads grants with status 'active' or 'pending_signature'
4. **Card Rendering**: Only shows cards if `grantData` exists

```typescript
// Key logic from EmployeeDashboard.tsx
const { data: employee } = await supabase
  .from('employees')
  .select('id, company_id')
  .eq('user_id', user.id)
  .maybeSingle();

if (!employee) return; // No employee record = no dashboard

const grantsRes = await supabase
  .from('grants')
  .select('id, total_shares, vested_shares, remaining_unvested_shares, status, grant_number')
  .eq('employee_id', employee.id)
  .in('status', ['active', 'pending_signature']);

if (!grantsRes.data || grantsRes.data.length === 0) {
  // Shows "No Active Grants" message instead of cards
  return <NoActiveGrantsComponent />;
}
```

## Solution

I've created a migration file `20250125000043_link_khalid_to_wajehah_auth.sql` that will:

1. **Create Auth User**: Create a Supabase auth user for `wajehah.com@gmail.com`
2. **Link Employee to Auth**: Connect Khalid's employee record to the auth user
3. **Enable Portal Access**: Ensure portal access is enabled for login
4. **Preserve All Data**: Keep all existing grants, portfolio, documents, and notifications
5. **Fix Authentication**: This solves the core issue of missing auth link

## Migration Details

The migration will properly link Khalid Al-Zahrani (same person as wajehah.com@gmail.com) to authentication:

- **Auth User**: New Supabase auth user for wajehah.com@gmail.com
- **Employee Link**: Connect Khalid's employee record to the auth user
- **Email**: wajehah.com@gmail.com (Khalid's login email)
- **Password**: Wajehah2025!
- **Portal Access**: Enable portal access for login
- **Existing Grant**: Uses actual current grant data (whatever is in the database) - **PRESERVED**
- **Existing Portfolio**: Uses actual current portfolio data - **PRESERVED**
- **Existing Vesting**: Uses actual current vesting schedule - **PRESERVED**
- **Existing Documents**: All contract documents - **PRESERVED**
- **Existing Notifications**: All notifications - **PRESERVED**

## How to Apply the Fix

1. **Run the Migration**:
   ```bash
   npx supabase db push
   ```

2. **Test Login**:
   - Email: `wajehah.com@gmail.com`
   - Password: `Wajehah2025!`

3. **Verify Dashboard**: The dashboard should now show all cards with data

## Expected Dashboard Cards After Fix

Once the migration is applied, the dashboard will show:

1. **Total Shares Granted**: [Actual current shares from database] (Khalid's existing grant)
2. **Vested Shares**: [Actual vested shares from database]
3. **Unvested Shares**: [Actual unvested shares from database]
4. **Your Grants**: List of grants with details (actual grant numbers from database)
5. **Portfolio Value**: Current market value
6. **Quick Stats**: Vested/Unvested breakdown
7. **Performance History**: Chart showing performance

**Note**: The exact numbers will depend on what's actually in the database. The migration will preserve and display whatever current data exists for Khalid.

## Alternative Quick Fix

If you can't run migrations, you can manually add the data through the Supabase dashboard:

1. **Create Auth User**:
   - Go to Authentication > Users
   - Add user with email: `wajehah.com@gmail.com`
   - Set password: `Wajehah2025!`

2. **Create Employee Record**:
   - Go to Table Editor > employees
   - Add record with the auth user ID
   - Set portal_access_enabled = true

3. **Create Grant**:
   - Go to Table Editor > grants
   - Add grant with 250,000 shares
   - Set status = 'active'

4. **Create Portfolio**:
   - Go to Table Editor > portfolios
   - Add portfolio with 250,000 shares

## Verification Steps

After applying the fix:

1. **Login Test**: Verify login works with the credentials
2. **Dashboard Check**: Confirm all cards are visible
3. **Data Accuracy**: Verify numbers match the grant data
4. **Navigation**: Test other portal features (documents, notifications)

## Files Modified

- `supabase/migrations/20250125000043_link_khalid_to_wajehah_auth.sql` (new)
- `EMPLOYEE_PORTAL_DASHBOARD_FIX.md` (this file)

## Related Components

The dashboard uses these components:
- `src/pages/EmployeeDashboard.tsx` - Main dashboard
- `src/components/PortfolioValuation.tsx` - Portfolio value card
- `src/components/PerformanceChart.tsx` - Performance chart
- `src/contexts/AuthContext.tsx` - Authentication context

## Next Steps

1. Apply the migration to set up the user data
2. Test the login and dashboard functionality
3. Verify all cards are displaying correctly
4. Test other portal features to ensure complete functionality
