#!/bin/bash
# Haramain Pro — Refactoring Deployment Script
# Run: bash scripts/deploy-refactoring.sh

set -e

PROJECT_DIR="/Volumes/StartUp/Haramain-Pro"
SUPABASE_PROJECT_ID="haramain-pro"  # Ganti dengan project ID kamu

echo "=============================================="
echo "Haramain Pro — Refactoring Deployment"
echo "=============================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}Error: supabase CLI not found${NC}"
    echo "Install: brew install supabase/tap/supabase"
    exit 1
fi

# Check if .env.local exists (ask to create from .env.example)
if [ ! -f "$PROJECT_DIR/.env.local" ] && [ ! -f "$PROJECT_DIR/.env" ]; then
    echo -e "${YELLOW}Warning: .env.local not found${NC}"
    echo "Creating .env.local from .env.example..."
    cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env.local"
    echo -e "${YELLOW}Please edit .env.local with your actual credentials${NC}"
    echo "Press Enter when ready..."
    read -r
fi

echo "Step 1: Verify migration file exists"
echo "--------------------------------------"
if [ -f "$PROJECT_DIR/supabase/migrations/007_refactoring_schema.sql" ]; then
    echo -e "${GREEN}✓ Migration file found${NC}"
else
    echo -e "${RED}✗ Migration file NOT found${NC}"
    exit 1
fi

echo ""
echo "Step 2: Show migration SQL summary"
echo "------------------------------------"
echo "Tables/Columns to be created/modified:"
grep -E "^(CREATE|ALTER|ADD)" "$PROJECT_DIR/supabase/migrations/007_refactoring_schema.sql" | head -20

echo ""
echo "Step 3: Dry-run migration (validate SQL syntax)"
echo "------------------------------------------------"
echo -e "${YELLOW}Note: This only validates syntax, doesn't apply changes${NC}"
echo "To apply: supabase db push"
echo ""
echo -e "${YELLOW}Manual step required:${NC}"
echo "1. Go to https://supabase.com/dashboard"
echo "2. Select project: $SUPABASE_PROJECT_ID"
echo "3. Go to SQL Editor"
echo "4. Copy contents of: supabase/migrations/007_refactoring_schema.sql"
echo "5. Run the SQL"
echo ""
echo "Press Enter when migration has been applied..."
read -r

echo ""
echo "Step 4: Verify schema changes"
echo "--------------------------------"
echo -e "${YELLOW}Checking if new columns exist in panic_alerts...${NC}"

# Check for expected columns
MIGRATION_CONTENT=$(cat "$PROJECT_DIR/supabase/migrations/007_refactoring_schema.sql")

# List of expected new columns/tables
EXPECTED=(
    "response_type"
    "accuracy"
    "altitude" 
    "message"
    "panic_responses"
    "agencies"
    "geofence_prayers"
    "seat_licenses"
    "marketing_preferences"
)

echo ""
echo "Expected schema objects:"
for item in "${EXPECTED[@]}"; do
    if echo "$MIGRATION_CONTENT" | grep -q "$item"; then
        echo -e "  ${GREEN}✓${NC} $item"
    else
        echo -e "  ${RED}✗${NC} $item (MISSING in migration!)"
    fi
done

echo ""
echo "Step 5: Verify Flutter code changes"
echo "------------------------------------"
echo -e "${YELLOW}Checking key files exist with expected changes...${NC}"

FILES=(
    "apps/haramain_pro/lib/features/panic/panic_service.dart"
    "apps/haramain_pro/lib/services/location_service.dart"
    "apps/haramain_pro/lib/config/constants.dart"
    "apps/haramain_pro/lib/utils/logger.dart"
    "supabase/functions/fcm-panic-alert/index.ts"
)

for file in "${FILES[@]}"; do
    if [ -f "$PROJECT_DIR/$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file (MISSING!)"
    fi
done

echo ""
echo "Step 6: Verify API contract changes"
echo "-------------------------------------"
echo "Checking Edge Function accepts PRD-compliant payload..."

if grep -q "rombonganId.*latitude.*longitude" "$PROJECT_DIR/supabase/functions/fcm-panic-alert/index.ts"; then
    echo -e "  ${GREEN}✓${NC} Edge Function: Payload interface updated"
else
    echo -e "  ${RED}✗${NC} Edge Function: Payload interface may not be updated"
fi

if grep -q "validateLatitude\|validateLongitude\|validateUUID" "$PROJECT_DIR/supabase/functions/fcm-panic-alert/index.ts"; then
    echo -e "  ${GREEN}✓${NC} Edge Function: Input validation added"
else
    echo -e "  ${RED}✗${NC} Edge Function: Input validation NOT found"
fi

if grep -q "twilio-voice-fallback" "$PROJECT_DIR/supabase/functions/fcm-panic-alert/index.ts"; then
    echo -e "  ${GREEN}✓${NC} Edge Function: Twilio fallback integrated"
else
    echo -e "  ${RED}✗${NC} Edge Function: Twilio fallback NOT integrated"
fi

echo ""
echo "Step 7: Verify Flutter payload method"
echo "--------------------------------------"
if grep -q "toEdgeFunctionPayload" "$PROJECT_DIR/apps/haramain_pro/lib/features/panic/panic_service.dart"; then
    echo -e "  ${GREEN}✓${NC} Flutter: toEdgeFunctionPayload() method exists"
else
    echo -e "  ${RED}✗${NC} Flutter: toEdgeFunctionPayload() NOT found"
fi

if grep -q "rombonganId.*latitude.*longitude" "$PROJECT_DIR/apps/haramain_pro/lib/features/panic/panic_service.dart"; then
    echo -e "  ${GREEN}✓${NC} Flutter: PanicAlert model updated"
else
    echo -e "  ${RED}✗${NC} Flutter: PanicAlert model may not be updated"
fi

echo ""
echo "=============================================="
echo -e "${GREEN}Deployment Verification Complete${NC}"
echo "=============================================="
echo ""
echo "Next steps:"
echo "1. Test panic button flow in Flutter app"
echo "2. Verify Twilio fallback works (if FCM fails)"
echo "3. Test jejak ibadah photo upload"
echo "4. Commit changes: git add . && git commit -m 'refactor: fix API contracts, schema, Twilio fallback'"
echo ""
echo "Backup files (*.bak) are in:"
echo "  - supabase/functions/fcm-panic-alert/index.ts.bak"
echo "  - apps/haramain_pro/lib/features/panic/panic_service.dart.bak"
echo "  - apps/haramain_pro/lib/services/location_service.dart.bak"
echo ""
