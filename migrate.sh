#!/bin/bash
# migrate.sh - Run database migrations
# Usage: ./migrate.sh [dev|local|prod]
# Default: dev (safe for development)

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
        echo -e "${RED}⚠️  RUNNING ON PRODUCTION DATABASE!${NC}"
        read -p "Press Enter to continue, Ctrl+C to cancel" 
        ;;
    *)
        echo "Invalid environment: $ENV"
        echo "Usage: $0 [dev|local|prod]"
        echo "  dev   - Development database (default)"
        echo "  local - Local production database"
        echo "  prod  - DigitalOcean production (requires confirmation)"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}🐷 SuperPig Database Migrations${NC}"
echo -e "${BLUE}================================${NC}"
echo "Database: $DATABASE"
echo "Started: $(date)"
echo ""

# Migration paths
MIGRATIONS_DIR="/root/projects/jsys/pig_ops_db/database/mysql/migrations"
MARKERS_DIR="/root/projects/jsys/.db_migrations_${ENV}"

mkdir -p "$MARKERS_DIR"

# Run migrations in order
count=0
for script in $(ls -1 "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort); do
    script_name=$(basename "$script")
    marker="$MARKERS_DIR/$script_name.done"
    
    if [ ! -f "$marker" ]; then
        echo -e "${YELLOW}📦 Applying: $script_name${NC}"
        
        # Run the migration
        mysql -u root "$DATABASE" < "$script"
        
        if [ $? -eq 0 ]; then
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

echo ""
echo -e "${GREEN}✅ Migration complete! ($count applied)${NC}"
echo "Completed: $(date)"
