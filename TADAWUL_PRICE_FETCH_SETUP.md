# Tadawul Price Fetch Setup Guide

This guide will help you set up the automatic price fetching from Tadawul's website.

## Prerequisites

1. Supabase CLI installed
2. Supabase project linked
3. Environment variables configured

## Step-by-Step Instructions

### Step 1: Deploy the Edge Function

The Edge Function fetches prices from Tadawul's website (bypassing CORS restrictions).

```bash
# Navigate to your project root
cd /Users/interfacesolutions/Desktop/Derayah.esop

# Deploy the fetch-tadawul-price Edge Function
supabase functions deploy fetch-tadawul-price
```

**Expected output:**
```
Deploying function fetch-tadawul-price...
Function fetch-tadawul-price deployed successfully
```

### Step 2: Run Database Migrations

Apply the migrations to set up the market_data table and functions:

```bash
# Apply all pending migrations (including the new ones)
supabase db push

# OR if you're using Supabase Dashboard, run these migrations in order:
# 1. 20251118000003_seed_market_data.sql
# 2. 20251118000004_add_update_market_price_function.sql
# 3. 20251118000005_update_derayah_price.sql
```

**In Supabase Dashboard:**
1. Go to SQL Editor
2. Run each migration file in order:
   - `supabase/migrations/20251118000003_seed_market_data.sql`
   - `supabase/migrations/20251118000004_add_update_market_price_function.sql`
   - `supabase/migrations/20251118000005_update_derayah_price.sql`

### Step 3: Verify Edge Function Deployment

Check that the function is deployed:

```bash
# List all deployed functions
supabase functions list
```

You should see `fetch-tadawul-price` in the list.

### Step 4: Test the Function (Optional)

You can test the Edge Function directly:

```bash
# Test with Derayah symbol (4084)
curl -X POST \
  'https://YOUR_PROJECT_REF.supabase.co/functions/v1/fetch-tadawul-price' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"symbol": "4084", "market": "main"}'
```

Replace:
- `YOUR_PROJECT_REF` with your Supabase project reference
- `YOUR_ANON_KEY` with your Supabase anon key

### Step 5: Test in the Application

1. **Start your development server:**
   ```bash
   npm run dev
   # or
   yarn dev
   ```

2. **Login to the admin portal:**
   - Go to Settings page
   - Select a company (e.g., Derayah Financial - 4084)
   - Click the "Fetch" button next to "Current Share Price"

3. **Expected behavior:**
   - The button shows "Fetching..." with a spinner
   - After a few seconds, the price should populate
   - You should see a success message: "Price fetched successfully: SAR XX.XX"
   - The price should match the closing price from Tadawul

### Step 6: Verify Data in Database

Check that the price was saved:

```sql
-- Check market_data table
SELECT * FROM market_data 
WHERE tadawul_symbol = '4084' 
ORDER BY trading_date DESC 
LIMIT 1;

-- Check company's current_fmv
SELECT company_name_en, tadawul_symbol, current_fmv, fmv_source 
FROM companies 
WHERE tadawul_symbol = '4084';
```

## Troubleshooting

### Issue: Edge Function deployment fails

**Solution:**
```bash
# Make sure you're logged in
supabase login

# Link your project
supabase link --project-ref YOUR_PROJECT_REF

# Try deploying again
supabase functions deploy fetch-tadawul-price
```

### Issue: "Function not found" error

**Solution:**
- Verify the function is deployed: `supabase functions list`
- Check the function name matches exactly: `fetch-tadawul-price`
- Ensure you're using the correct Supabase URL in your `.env` file

### Issue: Price fetching returns error

**Possible causes:**
1. **Tadawul website structure changed** - The HTML parsing may need adjustment
2. **Symbol not found** - Verify the symbol is correct and listed on Tadawul
3. **Network issues** - Check if Tadawul website is accessible

**Solution:**
- Check browser console for detailed error messages
- Try manually entering the price as a workaround
- Check Edge Function logs: `supabase functions logs fetch-tadawul-price`

### Issue: CORS errors

**Solution:**
- Edge Functions handle CORS automatically
- If you see CORS errors, check that the function is deployed correctly
- Verify the `corsHeaders` are set in the Edge Function

## Manual Price Update (Fallback)

If automatic fetching doesn't work, you can manually update prices:

1. Go to Settings page
2. Enter the price manually in "Current Share Price (SAR)" field
3. Click "Save Changes"
4. The price will be saved to both `companies.current_fmv` and `market_data` table

## Next Steps

1. **Set up scheduled updates (Optional):**
   - Create a cron job or scheduled task to update prices every 15 minutes
   - Use Supabase Edge Functions with pg_cron extension
   - Or use external services like GitHub Actions, Vercel Cron, etc.

2. **Monitor price accuracy:**
   - Regularly verify fetched prices match Tadawul website
   - Update the Edge Function parsing logic if Tadawul changes their page structure

3. **Add more symbols:**
   - The system supports all Tadawul-listed companies
   - Add more companies to the dropdown in Settings

## Support

If you encounter issues:
1. Check the browser console for errors
2. Check Edge Function logs: `supabase functions logs fetch-tadawul-price`
3. Verify database migrations were applied successfully
4. Test the Edge Function directly using curl (see Step 4)

