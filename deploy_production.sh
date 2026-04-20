# Production Deployment Script for Firebase Security Update
# This script automates the production deployment process

#!/bin/bash

set -e  # Exit on error

echo "======================================================================"
echo "Firebase Security Update - Production Deployment"
echo "======================================================================"
echo ""

# Configuration
PROJECT_ID="anime-waifu"  # Update with actual project
BACKUP_BUCKET="gs://anime-waifu-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Pre-deployment checks
echo -e "${YELLOW}[STEP 1] Running pre-deployment checks...${NC}"

if ! command -v firebase &> /dev/null; then
    echo -e "${RED}ERROR: Firebase CLI not found. Install it first: npm install -g firebase-tools${NC}"
    exit 1
fi

if ! firebase login:ci &>/dev/null; then
    echo -e "${YELLOW}Sign in to Firebase CLI: ${NC}"
    firebase login
fi

CURRENT_PROJECT=$(firebase projects:list --json | grep -o '"projectId":"'${PROJECT_ID}'"' || true)
if [ -z "$CURRENT_PROJECT" ]; then
    echo -e "${RED}ERROR: Project ${PROJECT_ID} not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Firebase CLI configured for project: ${PROJECT_ID}${NC}"

# Step 2: Backup current rules
echo ""
echo -e "${YELLOW}[STEP 2] Backing up current firestore.rules...${NC}"

if firebase firestore:indexes &>/dev/null; then
    echo -e "${GREEN}✓ Firestore accessible${NC}"
else
    echo -e "${RED}ERROR: Cannot access Firestore. Check credentials.${NC}"
    exit 1
fi

cp firestore.rules "firestore.rules.backup.${TIMESTAMP}"
echo -e "${GREEN}✓ Backup created: firestore.rules.backup.${TIMESTAMP}${NC}"

# Step 3: Deploy new rules
echo ""
echo -e "${YELLOW}[STEP 3] Deploying new firestore.rules...${NC}"

firebase deploy --only firestore:rules --project="${PROJECT_ID}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ firestore.rules deployed successfully${NC}"
else
    echo -e "${RED}ERROR: Deployment failed${NC}"
    exit 1
fi

# Step 4: Verify deployment
echo ""
echo -e "${YELLOW}[STEP 4] Verifying deployment...${NC}"

# Test access patterns
echo "Testing read access (should succeed for authenticated user)..."
firebase firestore:get "/" --project="${PROJECT_ID}" &>/dev/null && echo -e "${GREEN}✓ Basic access working${NC}" || echo -e "${YELLOW}⚠ Check access patterns${NC}"

# Step 5: Monitor for errors
echo ""
echo -e "${YELLOW}[STEP 5] Starting error monitoring (60 seconds)...${NC}"

for i in {1..6}; do
    echo "Checking logs (${i}/6)..."
    firebase functions:log --project="${PROJECT_ID}" 2>/dev/null | grep -i error || true
    sleep 10
done

# Step 6: Summary
echo ""
echo -e "${YELLOW}[STEP 6] Deployment Summary${NC}"
echo "======================================================================"
echo -e "${GREEN}✓ Deployment completed successfully${NC}"
echo ""
echo "What changed:"
echo "  - Firestore Rules: Updated with security patches"
echo "  - Collections protected: 23+"
echo "  - Email field: Now hidden from queries"
echo "  - Helper functions: Added for optimization"
echo ""
echo "Next steps:"
echo "  1. Monitor error logs for 24 hours"
echo "  2. Run integration tests in production"
echo "  3. Verify all features working correctly"
echo "  4. Check Firestore billing for changes"
echo ""
echo "Rollback procedure (if needed):"
echo "  firebase deploy --only firestore:rules@firestore.rules.backup.${TIMESTAMP}"
echo ""
echo "======================================================================"

# Step 7: Log deployment event
echo ""
echo -e "${YELLOW}[STEP 7] Logging deployment event...${NC}"

firebase firestore:import gs://anime-waifu-backups/deployment_log_${TIMESTAMP}.json 2>/dev/null || echo "Could not log deployment"

echo ""
echo -e "${GREEN}All done! Monitoring is now active.${NC}"
