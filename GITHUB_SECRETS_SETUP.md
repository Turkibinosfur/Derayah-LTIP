# GitHub Secrets Setup for Supabase Environment Variables

## Problem
The GitHub Pages deployment is failing because the Supabase environment variables are missing during the build process.

## Solution: Add GitHub Secrets

### Step 1: Add Secrets to GitHub Repository

1. Go to your repository: https://github.com/Turkibinosfur/Derayah-LTIP
2. Click on **Settings** (top menu)
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add the following secrets:

   **Secret 1:**
   - Name: `VITE_SUPABASE_URL`
   - Value: `https://dvkijneltotbineqrmkv.supabase.co`
   - Click **Add secret**

   **Secret 2:**
   - Name: `VITE_SUPABASE_ANON_KEY`
   - Value: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2a2lqbmVsdG90YmluZXFybWt2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEzMjgyMjksImV4cCI6MjA3NjkwNDIyOX0.c67L8E7pqFX3826_EOSAkpEy23liLw0Zv76TpcBOW9k`
   - Click **Add secret**

### Step 2: Trigger a New Deployment

After adding the secrets, you need to trigger a new deployment:

**Option A: Push a commit**
```bash
git add .github/workflows/deploy.yml
git commit -m "Add Supabase environment variables to GitHub Actions"
git push origin main
```

**Option B: Manually trigger workflow**
1. Go to: https://github.com/Turkibinosfur/Derayah-LTIP/actions
2. Click on "Deploy to GitHub Pages" workflow
3. Click "Run workflow" button
4. Select the branch (main) and click "Run workflow"

### Step 3: Verify Deployment

1. Wait 2-5 minutes for the deployment to complete
2. Check the Actions tab to see if the build succeeded
3. Visit: https://turkibinosfur.github.io/Derayah-LTIP/login
4. The app should now load without the "Missing Supabase environment variables" error

## Alternative: Hardcode Values (Not Recommended)

If you prefer not to use secrets (though the anon key is safe to expose), you can modify the workflow file directly. However, **using secrets is the recommended approach** for better security and easier updates.

## Troubleshooting

### Issue: "Secret not found" error
- Make sure you added the secrets with the exact names: `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`
- Check that you're adding them in the correct repository
- Verify the secrets are added under **Secrets and variables** → **Actions** (not **Dependabot**)

### Issue: Build still fails
- Check the Actions tab for detailed error messages
- Verify the secret values are correct (no extra spaces or line breaks)
- Make sure you've pushed the updated workflow file

### Issue: App still shows blank page
- Clear your browser cache
- Try incognito/private mode
- Wait a few minutes for the deployment to propagate
- Check browser console for any new errors

