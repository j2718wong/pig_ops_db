#!/bin/bash
# migrate.sh - Run database migrations
# Usage: ./migrate.sh [dev|local|prod]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default to dev (safe)
ENV=${1:-dev}

# Set database based on environment
case "$ENV" in
    dev)
        DATABASE="pig_ops_dev"
        echo -e "${YELLOW}🌱 Running on DEVELOPMENT database: $DATABASE${NC}"
        ;;
    local)
        DATABASE="pig_operations"
        echo -e "${YELLOW}💻 Running on LOCAL database: $DATABASE${NC}"
        ;;
    prod)
        DATABASE="pig_operations"
        ;;
    *)
        echo "Invalid environment: $ENV"
        echo "Usage: $0 [dev|local|prod]"
        exit 1
        ;;
esac

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Paths
MIGRATIONS_DIR="$SCRIPT_DIR/database/mysql/migrations"
MARKERS_DIR="$HOME/.db_migrations_${ENV}"
MIGRATION_APPLIED_FILE="$HOME/.db_migrations_${ENV}_last_run"

mkdir -p "$MARKERS_DIR"

# Check if there are any pending migrations
PENDING_MIGRATIONS=0
for script in $(ls -1 "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort); do
    script_name=$(basename "$script")
    marker="$MARKERS_DIR/$script_name.done"
    if [ ! -f "$marker" ]; then
        PENDING_MIGRATIONS=$((PENDING_MIGRATIONS + 1))
    fi
done

# If no pending migrations, exit quietly
if [ $PENDING_MIGRATIONS -eq 0 ]; then
    echo "✅ No pending migrations to apply"
    exit 0
fi

# Only show confirmation if there ARE pending migrations
if [ "$ENV" = "prod" ]; then
    echo -e "${RED}⚠️  RUNNING ON PRODUCTION DATABASE!${NC}"
    echo -e "${YELLOW}Found $PENDING_MIGRATIONS pending migration(s)${NC}"
    read -p "Press Enter to continue, Ctrl+C to cancel" 
fi

echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}🐷 SuperPig Database Migrations${NC}"
echo -e "${BLUE}================================${NC}"
echo "Database: $DATABASE"
echo "Started: $(date)"
echo ""

# Run migrations
count=0
for script in $(ls -1 "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort); do
    script_name=$(basename "$script")
    marker="$MARKERS_DIR/$script_name.done"
    
    if [ ! -f "$marker" ]; then
        echo -e "${YELLOW}📦 Applying: $script_name${NC}"
        
        # Run the migration - FIXED: check mysql directly
        if mysql "$DATABASE" < "$script"; then
            touch "$marker"
            echo -e "${GREEN}   ✅ Done${NC}"
            ((count++))
        else
            echo -e "${RED}   ❌ Failed${NC}"
            exit 1
        fi
    else
        echo -e "${BLUE}⏭️  Skipping: $script_name (already applied)${NC}"
    fi
done

# Create timestamp file if any migrations were applied
if [ $count -gt 0 ]; then
    # Ensure directory exists
    mkdir -p "$(dirname "$MIGRATION_APPLIED_FILE")"
    
    if date > "$MIGRATION_APPLIED_FILE" 2>/dev/null; then
        echo "✅ Migration complete! ($count applied)"
        echo "   Timestamp saved to: $MIGRATION_APPLIED_FILE"
    else
        echo "⚠️  Could not save timestamp, but migrations applied"
    fi
else
    echo "✅ No migrations applied"
fi

echo "Completed: $(date)"
