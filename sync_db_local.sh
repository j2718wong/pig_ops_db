#!/bin/bash

# Configuration
REMOTE_SERVER="68.183.225.10"
REMOTE_USER="root"
REMOTE_DUMP_DIR="/root/temp"
REMOTE_DB_NAME="pig_operations" 
LOCAL_DUMP_PATH="/home/dev01/Downloads/pig_ops_prod_dumps"
LOCAL_DB_NAME="pig_operations"
LOG_FILE="/home/dev01/projects/jsys/pig_ops_db/sync_log.log"

# Dump file naming
DATE=$(date +%Y%m%d_%H%M%S)
REMOTE_DUMP_FILE="${REMOTE_DUMP_DIR}/pig_operations_prod_${DATE}.sql"

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

# Test MySQL connection on remote
test_remote_mysql() {
    print_info "Testing remote MySQL connection..."
    ssh ${REMOTE_USER}@${REMOTE_SERVER} "mysql -e 'SELECT 1'" &>/dev/null
    if [ $? -eq 0 ]; then
        print_status "Remote MySQL connection successful"
        return 0
    else
        print_error "Cannot connect to remote MySQL"
        print_info "Check if MySQL is running and credentials are configured on remote"
        exit 1
    fi
}

# Create dump on remote server
create_remote_dump() {
    print_info "Creating database dump on remote server..."
    print_info "Remote database: $REMOTE_DB_NAME"
    print_info "Remote dump file: $REMOTE_DUMP_FILE"
    
    # Create dump on remote server
    ssh ${REMOTE_USER}@${REMOTE_SERVER} "mysqldump --no-create-info --extended-insert --complete-insert $REMOTE_DB_NAME > $REMOTE_DUMP_FILE"
    
    if [ $? -eq 0 ]; then
        # Check file size on remote
        REMOTE_SIZE=$(ssh ${REMOTE_USER}@${REMOTE_SERVER} "stat -c%s $REMOTE_DUMP_FILE 2>/dev/null || stat -f%z $REMOTE_DUMP_FILE 2>/dev/null")
        if [ "$REMOTE_SIZE" -gt 0 ]; then
            print_status "Remote dump created successfully (Size: $(echo $REMOTE_SIZE | awk '{print int($1/1024)}')KB)"
            return 0
        else
            print_error "Remote dump file is empty"
            exit 1
        fi
    else
        print_error "Failed to create remote dump"
        exit 1
    fi
}

# Alternative: Use compressed dump (saves bandwidth)
create_remote_dump_compressed() {
    print_info "Creating compressed database dump on remote server..."
    ssh ${REMOTE_USER}@${REMOTE_SERVER} "mysqldump --no-create-info --extended-insert --complete-insert $REMOTE_DB_NAME | gzip > ${REMOTE_DUMP_FILE}.gz"
    
    if [ $? -eq 0 ]; then
        print_status "Remote compressed dump created: ${REMOTE_DUMP_FILE}.gz"
        REMOTE_DUMP_FILE="${REMOTE_DUMP_FILE}.gz"  # Update to use compressed file
        return 0
    else
        print_error "Failed to create remote compressed dump"
        exit 1
    fi
}

# Test local MySQL connection
test_local_mysql() {
    print_info "Testing local MySQL connection..."
    if mysql -e "SELECT 1" &>/dev/null; then
        print_status "Local MySQL connection successful"
    else
        print_error "Cannot connect to local MySQL"
        exit 1
    fi
}

# Check if local database exists
check_local_database() {
    print_info "Checking if database $LOCAL_DB_NAME exists..."
    if mysql -e "USE $LOCAL_DB_NAME" &>/dev/null; then
        print_status "Database $LOCAL_DB_NAME exists"
    else
        print_error "Database $LOCAL_DB_NAME does not exist"
        print_info "Create it first: mysql -e 'CREATE DATABASE $LOCAL_DB_NAME;'"
        exit 1
    fi
}

# Clean up old remote dumps (keep last 5)
cleanup_remote_dumps() {
    print_info "Cleaning up old remote dumps (keeping last 5)..."
    ssh ${REMOTE_USER}@${REMOTE_SERVER} "cd ${REMOTE_DUMP_DIR} && ls -t pig_operations_prod_*.sql* 2>/dev/null | tail -n +6 | xargs -r rm"
    print_status "Remote cleanup completed"
}

# Main execution
print_info "========================================"
print_info "Starting database sync from remote server"
print_info "========================================"

# Test connections
test_remote_mysql
test_local_mysql
check_local_database

# Check local dump directory
print_info "Checking local directory: $LOCAL_DUMP_PATH"
if [ ! -d "$LOCAL_DUMP_PATH" ]; then
    print_info "Creating directory: $LOCAL_DUMP_PATH"
    mkdir -p "$LOCAL_DUMP_PATH"
fi

if [ ! -w "$LOCAL_DUMP_PATH" ]; then
    print_error "No write permission for: $LOCAL_DUMP_PATH"
    exit 1
fi
print_status "Local directory is writable"

# Create dump on remote
create_remote_dump
# Uncomment the line below if you want compressed dump (saves bandwidth)
# create_remote_dump_compressed

# Copy the dump file
DUMP_FILENAME=$(basename "$REMOTE_DUMP_FILE")
LOCAL_FILE="${LOCAL_DUMP_PATH}/${DUMP_FILENAME}"

print_info "Copying dump file from remote server..."
scp ${REMOTE_USER}@${REMOTE_SERVER}:"${REMOTE_DUMP_FILE}" "${LOCAL_FILE}"

if [ $? -ne 0 ]; then
    print_error "SCP failed"
    exit 1
fi

print_status "File copied successfully"
print_info "Local file: $LOCAL_FILE"
print_info "File size: $(du -h "$LOCAL_FILE" | cut -f1)"

# Truncate local tables
print_info "Truncating all tables in $LOCAL_DB_NAME..."

mysql -D $LOCAL_DB_NAME -e "SET FOREIGN_KEY_CHECKS=0;"

TABLES=$(mysql -D $LOCAL_DB_NAME -e "SHOW TABLES;" -s -N 2>/dev/null)

if [ -z "$TABLES" ]; then
    print_info "No tables found to truncate"
else
    TABLE_COUNT=$(echo "$TABLES" | wc -l)
    print_info "Found $TABLE_COUNT tables to truncate"
    
    echo "$TABLES" | while read table; do
        print_info "Truncating: $table"
        mysql -D $LOCAL_DB_NAME -e "TRUNCATE TABLE \`$table\`;"
    done
    print_status "All tables truncated"
fi

mysql -D $LOCAL_DB_NAME -e "SET FOREIGN_KEY_CHECKS=1;"

# Import data
print_info "Importing data into $LOCAL_DB_NAME..."
print_info "This may take a while..."

# Handle compressed files
if [[ "$LOCAL_FILE" == *.gz ]]; then
    gunzip -c "$LOCAL_FILE" | mysql $LOCAL_DB_NAME
else
    mysql $LOCAL_DB_NAME < "$LOCAL_FILE"
fi

if [ $? -eq 0 ]; then
    print_status "Data imported successfully"
else
    print_error "Failed to import data"
    exit 1
fi

# Clean up old remote dumps
cleanup_remote_dumps

# Clean up local old dumps (keep last 5)
print_info "Cleaning up old local dumps..."
cd "$LOCAL_DUMP_PATH" || exit 1
ls -t pig_operations_prod_*.sql* 2>/dev/null | tail -n +6 | while read old_file; do
    print_info "Removing old local dump: $old_file"
    rm "$old_file"
done

# Optional: Remove the remote dump file after copying (if you want to save space)
# print_info "Removing remote dump file..."
# ssh ${REMOTE_USER}@${REMOTE_SERVER} "rm ${REMOTE_DUMP_FILE}"

# Final summary
print_info "========================================"
print_status "Sync completed successfully!"
print_info "Remote database: $REMOTE_DB_NAME"
print_info "Local database: $LOCAL_DB_NAME"
print_info "Imported file: $DUMP_FILENAME"
print_info "Size: $(du -h "$LOCAL_FILE" | cut -f1)"
print_info "Time: $(date)"
print_info "========================================"

exit 0
