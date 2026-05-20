#!/bin/bash
# migrate.sh - Run database migrations
# Usage: ./migrate.sh [dev|local|prod]

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
START_MIGRATION_FILE="$SCRIPT_DIR/start_migration.txt"

mkdir -p "$MARKERS_DIR"

# Read start migration number if file exists
START_MIGRATION=0
if [ -f "$START_MIGRATION_FILE" ]; then
    START_MIGRATION=$(cat "$START_MIGRATION_FILE" | tr -d '[:space:]')
    if [[ "$START_MIGRATION" =~ ^[0-9]+$ ]]; then
        echo -e "${YELLOW}⚠️  Start migration detected: $START_MIGRATION${NC}"
        echo -e "${YELLOW}   Will skip all migrations up to number $START_MIGRATION${NC}"
        echo ""
    else
        echo -e "${RED}Error: start_migration.txt contains invalid number: $START_MIGRATION${NC}"
        exit 1
    fi
fi

# Function to extract migration number from filename
get_migration_number() {
    local filename="$1"
    # Extract number from filename like 001_xxx.sql or 145_xxx.sql
    local num=$(echo "$filename" | grep -o '^[0-9]*')
    echo "$num"
}

# Check if there are any pending migrations
PENDING_MIGRATIONS=0
for script in $(ls -1 "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort); do
    script_name=$(basename "$script")
    marker="$MARKERS_DIR/$script_name.done"
    
    # Skip if marker exists
    if [ -f "$marker" ]; then
        continue
    fi
    
    # Skip if migration number is <= START_MIGRATION
    if [ $START_MIGRATION -gt 0 ]; then
        migration_num=$(get_migration_number "$script_name")
        if [ -n "$migration_num" ] && [ "$migration_num" -le "$START_MIGRATION" ]; then
            continue
        fi
    fi
    
    PENDING_MIGRATIONS=$((PENDING_MIGRATIONS + 1))
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
if [ $START_MIGRATION -gt 0 ]; then
    echo "Start from migration: $START_MIGRATION + 1"
fi
echo "Started: $(date)"
echo ""

# Run migrations
count=0
for script in $(ls -1 "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort); do
    script_name=$(basename "$script")
    marker="$MARKERS_DIR/$script_name.done"
    
    # Skip if already applied
    if [ -f "$marker" ]; then
        echo -e "${BLUE}⏭️  Skipping: $script_name (already applied)${NC}"
        continue
    fi
    
    # Skip if migration number is <= START_MIGRATION
    if [ $START_MIGRATION -gt 0 ]; then
        migration_num=$(get_migration_number "$script_name")
        if [ -n "$migration_num" ] && [ "$migration_num" -le "$START_MIGRATION" ]; then
            echo -e "${YELLOW}⏭️  Skipping: $script_name (migration number $migration_num <= $START_MIGRATION)${NC}"
            # Also create marker to mark as "skipped" so we don't process again
            touch "$marker"
            continue
        fi
    fi
    
    echo -e "${YELLOW}📦 Applying: $script_name${NC}"
    
    # Run the migration
    mysql -u root "$DATABASE" < "$script" 2>&1
    MYSQL_EXIT=$?

    if [ $MYSQL_EXIT -eq 0 ]; then
        touch "$marker"
        echo -e "${GREEN}   ✅ Done${NC}"
        ((count++))
    else
        echo -e "${RED}   ❌ Failed with exit code: $MYSQL_EXIT${NC}"
        echo -e "${RED}   Stopping migration at $script_name${NC}"
        exit $MYSQL_EXIT
    fi
done

# Create timestamp file if any migrations were applied
if [ $count -gt 0 ]; then
    TIMESTAMP_DIR="$(dirname "$MIGRATION_APPLIED_FILE")"
    mkdir -p "$TIMESTAMP_DIR"
    
    if date > "$MIGRATION_APPLIED_FILE" 2>&1; then
        echo "✅ Migration complete! ($count applied)"
        echo "   Timestamp saved to: $MIGRATION_APPLIED_FILE"
    else
        echo "⚠️  Warning: Could not save timestamp file"
        echo "   (Migrations were applied successfully)"
    fi
else
    echo "✅ No migrations applied"
fi

echo "Completed: $(date)"
