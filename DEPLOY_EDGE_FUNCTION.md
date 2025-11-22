# Deploy Edge Function - Quick Guide

## Step 1: Install Supabase CLI

Open Terminal (Cursor's terminal or macOS Terminal) and run:

```bash
# Install using Homebrew (recommended)
brew install supabase/tap/supabase

# OR install using npm
npm install -g supabase
```

## Step 2: Login to Supabase

```bash
supabase login
```

This will open a browser window for you to authenticate.

## Step 3: Link Your Project

```bash
# Link to your existing Supabase project
supabase link --project-ref YOUR_PROJECT_REF
```

To find your project ref:
1. Go to your Supabase Dashboard
2. Go to Settings → General
3. Copy the "Reference ID" (it looks like: `abcdefghijklmnop`)

## Step 4: Deploy the Function

```bash
cd /Users/interfacesolutions/Desktop/Derayah.esop
supabase functions deploy fetch-tadawul-price
```

## Step 5: Verify Deployment

```bash
supabase functions list
```

You should see `fetch-tadawul-price` in the list.

## Alternative: Deploy via Supabase Dashboard

If CLI doesn't work, you can deploy via Dashboard:
1. Go to Supabase Dashboard → Edge Functions
2. Click "Create a new function"
3. Name it: `fetch-tadawul-price`
4. Copy the code from `supabase/functions/fetch-tadawul-price/index.ts`
5. Paste and deploy

