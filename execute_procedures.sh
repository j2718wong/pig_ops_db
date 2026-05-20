#!/bin/bash
# execute_procedures.sh
# Execute all stored procedure files recursively from the procedures directory
# Usage: ./execute_procedures.sh [dev|local]

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROCEDURES_DIR="$SCRIPT_DIR/database/mysql/procedures"

# Database configuration
DB_DEV="pig_ops_dev"
DB_LOCAL="pig_operations"

# Default database
DB_TARGET=""
ENVIRONMENT=""

# Function to show usage
show_usage() {
    echo "Usage: $0 [dev|local]"
    echo ""
    echo "Examples:"
    echo "  $0 dev      # Execute on pig_ops_dev database"
    echo "  $0 local    # Execute on pig_operations database"
    echo ""
    exit 1
}

# Parse argument
if [ $# -ne 1 ]; then
    show_usage
fi

case "$1" in
    dev)
        DB_TARGET="$DB_DEV"
        ENVIRONMENT="DEV"
        ;;
    local)
        DB_TARGET="$DB_LOCAL"
        ENVIRONMENT="LOCAL"
        ;;
    *)
        echo -e "${RED}Error: Invalid argument '$1'${NC}"
        show_usage
        ;;
esac

# Check if procedures directory exists
if [ ! -d "$PROCEDURES_DIR" ]; then
    echo -e "${RED}Error: Procedures directory not found at $PROCEDURES_DIR${NC}"
    exit 1
fi

# Check if mysql client is available
if ! command -v mysql &> /dev/null; then
    echo -e "${RED}Error: mysql client not found${NC}"
    exit 1
fi

# Check if .my.cnf exists for password-less login
if [ ! -f "$HOME/.my.cnf" ]; then
    echo -e "${YELLOW}Warning: .my.cnf not found. You may be prompted for password.${NC}"
fi

echo "=========================================="
echo "Execute Stored Procedures"
echo "=========================================="
echo "Environment: $ENVIRONMENT"
echo "Database: $DB_TARGET"
echo "Procedures directory: $PROCEDURES_DIR"
echo "=========================================="
echo ""

# Counter for tracking
TOTAL_FILES=0
TOTAL_ERRORS=0
FAILED_FILES=()

# Function to execute a single SQL file
execute_sql_file() {
    local file="$1"
    
    # Get relative path using sed
    rel_path=$(echo "$file" | sed "s|$PROCEDURES_DIR/||" | sed 's|//|/|g')
    
    echo -n "Processing: $rel_path ... "
    
    # Execute the SQL file
    if mysql -D "$DB_TARGET" < "$file" 2>&1; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        return 1
    fi
}

# Function to recursively process directories
process_directory() {
    local dir="$1"
    local dir_name=$(basename "$dir")
    
    # Process all .sql files in current directory
    for file in "$dir"/*.sql; do
        if [ -f "$file" ]; then
            TOTAL_FILES=$((TOTAL_FILES + 1))
            if ! execute_sql_file "$file"; then
                TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
                FAILED_FILES+=("$file")
                # Exit on first error
                echo ""
                echo -e "${RED}========================================${NC}"
                echo -e "${RED}ERROR: Stopping execution${NC}"
                echo -e "${RED}Failed file: $file${NC}"
                echo -e "${RED}========================================${NC}"
                return 1
            fi
        fi
    done
    
    # Process subdirectories recursively
    for subdir in "$dir"/*/; do
        if [ -d "$subdir" ]; then
            process_directory "$subdir"
            # Check if error occurred in subdirectory
            if [ $? -ne 0 ]; then
                return 1
            fi
        fi
    done
    
    return 0
}

# Start processing from procedures directory
echo "Starting execution..."
echo ""

process_directory "$PROCEDURES_DIR"
EXIT_CODE=$?

echo ""
echo "=========================================="
echo "EXECUTION COMPLETE"
echo "=========================================="
echo "Total files processed: $TOTAL_FILES"
echo "Errors: $TOTAL_ERRORS"

if [ $TOTAL_ERRORS -gt 0 ]; then
    echo ""
    echo -e "${RED}Failed files:${NC}"
    for failed in "${FAILED_FILES[@]}"; do
        echo "  - $failed"
    done
    echo ""
    echo -e "${RED}❌ Execution FAILED${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}✅ All procedures executed successfully${NC}"
    exit 0
fi
