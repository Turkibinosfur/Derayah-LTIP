#!/bin/bash

# Deployment script for GitHub Pages
# This script commits changes, builds the project, and prepares for deployment

set -e  # Exit on error

echo "🚀 Starting deployment process..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not a git repository"
    exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${BLUE}Current branch: ${CURRENT_BRANCH}${NC}"

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️  Uncommitted changes detected${NC}"
    echo "Files with changes:"
    git status --short
    
    read -p "Do you want to commit these changes? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}📝 Staging all changes...${NC}"
        git add .
        
        read -p "Enter commit message (or press Enter for default): " COMMIT_MSG
        if [ -z "$COMMIT_MSG" ]; then
            COMMIT_MSG="Deploy latest changes to GitHub Pages - $(date +'%Y-%m-%d %H:%M:%S')"
        fi
        
        echo -e "${BLUE}💾 Committing changes...${NC}"
        git commit -m "$COMMIT_MSG"
    else
        echo "❌ Deployment cancelled. Please commit or stash your changes first."
        exit 1
    fi
else
    echo -e "${GREEN}✅ No uncommitted changes${NC}"
fi

# Ask if user wants to push to GitHub
read -p "Do you want to push to GitHub? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}📤 Pushing to GitHub...${NC}"
    git push origin "$CURRENT_BRANCH"
    echo -e "${GREEN}✅ Pushed to GitHub successfully${NC}"
    echo -e "${BLUE}🔄 GitHub Actions will automatically build and deploy${NC}"
    echo -e "${YELLOW}⏳ Please wait for the deployment to complete at:${NC}"
    echo -e "${BLUE}   https://github.com/tbsbo/Derayah-LTIP/actions${NC}"
else
    echo -e "${YELLOW}⚠️  Skipping push. You can push manually later with:${NC}"
    echo -e "${BLUE}   git push origin $CURRENT_BRANCH${NC}"
fi

# Ask if user wants to build locally
read -p "Do you want to build the project locally? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🔨 Building project...${NC}"
    npm run build
    echo -e "${GREEN}✅ Build completed successfully${NC}"
    echo -e "${BLUE}📦 Build output is in the 'dist' folder${NC}"
fi

echo -e "${GREEN}✨ Deployment process completed!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. If you pushed to GitHub, check the Actions tab for deployment status"
echo "2. Once deployed, your site will be available at:"
echo "   https://tbsbo.github.io/Derayah-LTIP/login"
echo "3. Test the deployment to ensure everything works correctly"

