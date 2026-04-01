#!/bin/bash

# Configuration
REMOTE_SERVER="68.183.225.10"
REMOTE_USER="root"
REMOTE_DUMP_PATH="/root/temp"
LOCAL_DUMP_PATH="/home/dev01/Downloads/pig_ops_prod_dumps"
LOCAL_DB_NAME="pig_operations"
LOG_FILE="/home/dev01/projects/jsys/pig_ops_db/sync_log.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to log messages (writes to stderr to avoid mixing with function output)
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" >&2
}

print_status() {
    echo -e "${GREEN}[✓] $1${NC}" >&2
    log_message "SUCCESS: $1"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}" >&2
    log_message "ERROR: $1"
}

print_info() {
    echo -e "${YELLOW}[→] $1${NC}" >&2
    log_message "INFO: $1"
}

# Function to get latest dump file (outputs ONLY the filename to stdout)
get_latest_dump() {
    ssh ${REMOTE_USER}@${REMOTE_SERVER} "ls -t ${REMOTE_DUMP_PATH}/pig_operations_prod_*.sql 2>/dev/null | head -n1"
}

test_mysql_connection() {
    print_info "Testing MySQL connection..."
    if mysql -e "SELECT 1" &>/dev/null; then
        print_status "MySQL connection successful"
    else
        print_error "Cannot connect to MySQL"
        exit 1
    fi
}

check_database_exists() {
    print_info "Checking if database $LOCAL_DB_NAME exists..."
    if mysql -e "USE $LOCAL_DB_NAME" &>/dev/null; then
        print_status "Database $LOCAL_DB_NAME exists"
    else
        print_error "Database $LOCAL_DB_NAME does not exist"
        print_info "Create it first: mysql -e 'CREATE DATABASE $LOCAL_DB_NAME;'"
        exit 1
    fi
}

# Main execution
print_info "Starting database sync from remote server to local..."

# Test MySQL connection
test_mysql_connection

# Check if database exists
check_database_exists

# Check local directory
print_info "Checking local directory: $LOCAL_DUMP_PATH"
if [ ! -d "$LOCAL_DUMP_PATH" ]; then
    print_info "Creating directory: $LOCAL_DUMP_PATH"
    mkdir -p "$LOCAL_DUMP_PATH"
    if [ $? -ne 0 ]; then
        print_error "Failed to create directory"
        exit 1
    fi
fi

if [ ! -w "$LOCAL_DUMP_PATH" ]; then
    print_error "No write permission for: $LOCAL_DUMP_PATH"
    exit 1
fi
print_status "Local directory is writable"

# Get the latest dump file
print_info "Finding latest dump file on remote server..."
LATEST_REMOTE_DUMP=$(get_latest_dump)

if [ -z "$LATEST_REMOTE_DUMP" ]; then
    print_error "No dump file found in ${REMOTE_DUMP_PATH} on remote server"
    exit 1
fi

DUMP_FILENAME=$(basename "$LATEST_REMOTE_DUMP")
LOCAL_FILE="${LOCAL_DUMP_PATH}/${DUMP_FILENAME}"

print_info "Remote file: $LATEST_REMOTE_DUMP"
print_info "Local file: $LOCAL_FILE"

# Copy the file
print_info "Copying file from remote server..."
scp ${REMOTE_USER}@${REMOTE_SERVER}:"${LATEST_REMOTE_DUMP}" "${LOCAL_FILE}"

if [ $? -ne 0 ]; then
    print_error "SCP failed"
    exit 1
fi

print_status "File copied successfully"

# Verify file
if [ ! -f "$LOCAL_FILE" ]; then
    print_error "File not found after copy: $LOCAL_FILE"
    exit 1
fi

FILE_SIZE=$(stat -c%s "$LOCAL_FILE" 2>/dev/null || stat -f%z "$LOCAL_FILE" 2>/dev/null)
if [ "$FILE_SIZE" -eq 0 ]; then
    print_error "File is empty after copy"
    exit 1
fi

print_info "File size: $(du -h "$LOCAL_FILE" | cut -f1)"

# Truncate tables
print_info "Truncating all tables in $LOCAL_DB_NAME..."

# Disable foreign key checks (just in case)
mysql -D $LOCAL_DB_NAME -e "SET FOREIGN_KEY_CHECKS=0;"

# Get and truncate tables
TABLES=$(mysql -D $LOCAL_DB_NAME -e "SHOW TABLES;" -s -N 2>/dev/null)

if [ -z "$TABLES" ]; then
    print_info "No tables found to truncate"
else
    TABLE_COUNT=$(echo "$TABLES" | wc -l)
    print_info "Found $TABLE_COUNT tables"
    
    echo "$TABLES" | while read table; do
        print_info "Truncating: $table"
        mysql -D $LOCAL_DB_NAME -e "TRUNCATE TABLE \`$table\`;"
    done
    print_status "All tables truncated"
fi

# Re-enable foreign key checks
mysql -D $LOCAL_DB_NAME -e "SET FOREIGN_KEY_CHECKS=1;"

# Import data
print_info "Importing data into $LOCAL_DB_NAME..."
print_info "This may take a while..."

mysql $LOCAL_DB_NAME < "$LOCAL_FILE"

if [ $? -eq 0 ]; then
    print_status "Data imported successfully"
else
    print_error "Failed to import data"
    exit 1
fi

# Cleanup old dumps (keep last 5)
print_info "Cleaning up old dump files..."
cd "$LOCAL_DUMP_PATH" || exit 1
ls -t pig_operations_prod_*.sql 2>/dev/null | tail -n +6 | while read old_file; do
    print_info "Removing old dump: $old_file"
    rm "$old_file"
done

# Final summary
print_info "========================================"
print_status "Sync completed successfully!"
print_info "Database: $LOCAL_DB_NAME"
print_info "Imported: $DUMP_FILENAME"
print_info "Size: $(du -h "$LOCAL_FILE" | cut -f1)"
print_info "Time: $(date)"
print_info "========================================"

exit 0


