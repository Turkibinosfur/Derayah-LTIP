# GitHub Pages Deployment Setup Guide

## Current Status
- ✅ GitHub Actions workflow created (`.github/workflows/deploy.yml`)
- ✅ `.nojekyll` file added (prevents Jekyll processing)
- ✅ `vite.config.ts` configured with base path `/Derayah-LTIP/`
- ✅ Deployment fixes committed and pushed

## Steps to Enable GitHub Pages

### 1. Enable GitHub Pages in Repository Settings

1. Go to: https://github.com/TBSBO/Derayah-LTIP/settings/pages
2. Under "Source", select: **"GitHub Actions"**
3. Click **"Save"**

### 2. Check Workflow Status

1. Go to: https://github.com/TBSBO/Derayah-LTIP/actions
2. Look for "Deploy to GitHub Pages" workflow
3. If it's running, wait for it to complete (usually 2-5 minutes)
4. If it failed, click on it to see error details

### 3. Verify Deployment

Once deployment completes:
- Visit: https://tbsbo.github.io/Derayah-LTIP/login
- The site should be live

### 4. If Deployment Failed

Common issues and fixes:

**Issue: "Workflow not found"**
- Make sure the `.github/workflows/deploy.yml` file is committed and pushed

**Issue: "Pages build failed"**
- Check the Actions tab for error messages
- Common causes:
  - Build errors (check npm install/build logs)
  - Missing dependencies
  - TypeScript errors

**Issue: "404 Not Found"**
- Wait 5-10 minutes after deployment completes
- Clear browser cache
- Try incognito/private mode

**Issue: "Workflow not triggering"**
- Check that the workflow file is in the correct location: `.github/workflows/deploy.yml`
- Verify the branch name matches (main or master)

### 5. Manual Deployment (Alternative)

If GitHub Actions isn't working, you can deploy manually:

```bash
# Build the project
npm run build

# This creates a 'dist' folder
# Then deploy the dist folder contents to gh-pages branch
```

## Troubleshooting

### Repository Path Issue

If you see a message about the repository moving:
```bash
# Update remote URL
git remote set-url origin https://github.com/TBSBO/Derayah-LTIP.git
git push origin main
```

### Force Re-deployment

To trigger a new deployment:
1. Go to: https://github.com/TBSBO/Derayah-LTIP/actions
2. Click "Deploy to GitHub Pages" workflow
3. Click "Run workflow" button (if available)
4. Or make a small change and push again

## Current Fixes Deployed

- ✅ Fixed company admin navigation (operator dashboard only for platform super admins)
- ✅ Added language switcher to employee portal
- ✅ Updated Customer Journey page
- ✅ Added comprehensive translations

