#!/bin/bash

# Detailed Code Statistics Script

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

OUTPUT_FILE="/tmp/code_stats_detailed.txt"

echo "========================================" | tee "$OUTPUT_FILE"
echo "    DETAILED CODE STATISTICS REPORT" | tee -a "$OUTPUT_FILE"
echo "    Generated: $(date)" | tee -a "$OUTPUT_FILE"
echo "========================================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 1. SQL Procedures
echo "1. MySQL PROCEDURES" | tee -a "$OUTPUT_FILE"
echo "-------------------" | tee -a "$OUTPUT_FILE"
PROC_DIR="/home/dev01/projects/jsys/pig_ops_db/database/mysql/procedures"
if [ -d "$PROC_DIR" ]; then
    PROC_COUNT=$(find "$PROC_DIR" -type f -name "*.sql" 2>/dev/null | wc -l)
    PROC_LINES=$(find "$PROC_DIR" -type f -name "*.sql" -exec cat {} \; 2>/dev/null | wc -l)
    echo "  Files: $PROC_COUNT" | tee -a "$OUTPUT_FILE"
    echo "  Lines: $PROC_LINES" | tee -a "$OUTPUT_FILE"
    if [ $PROC_COUNT -gt 0 ]; then
        echo "  Average: $((PROC_LINES / PROC_COUNT)) lines/file" | tee -a "$OUTPUT_FILE"
    fi
    echo "" | tee -a "$OUTPUT_FILE"
    
    # List files
    echo "  Files:" | tee -a "$OUTPUT_FILE"
    find "$PROC_DIR" -type f -name "*.sql" -exec basename {} \; | sort | while read file; do
        lines=$(wc -l < "$PROC_DIR/$file" 2>/dev/null)
        printf "    - %-40s %6s lines\n" "$file" "$lines" | tee -a "$OUTPUT_FILE"
    done
else
    echo "  Directory not found!" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 2. Python Files
echo "2. PYTHON FILES" | tee -a "$OUTPUT_FILE"
echo "----------------" | tee -a "$OUTPUT_FILE"
PYTHON_DIR="/home/dev01/projects/jsys/pig_ops/webroot"
if [ -d "$PYTHON_DIR" ]; then
    PYTHON_COUNT=$(find "$PYTHON_DIR" -type f -name "*.py" 2>/dev/null | wc -l)
    PYTHON_LINES=$(find "$PYTHON_DIR" -type f -name "*.py" -exec cat {} \; 2>/dev/null | wc -l)
    echo "  Files: $PYTHON_COUNT" | tee -a "$OUTPUT_FILE"
    echo "  Lines: $PYTHON_LINES" | tee -a "$OUTPUT_FILE"
    if [ $PYTHON_COUNT -gt 0 ]; then
        echo "  Average: $((PYTHON_LINES / PYTHON_COUNT)) lines/file" | tee -a "$OUTPUT_FILE"
    fi
    echo "" | tee -a "$OUTPUT_FILE"
    
    # Top 5 largest Python files
    echo "  Top 5 largest Python files:" | tee -a "$OUTPUT_FILE"
    find "$PYTHON_DIR" -type f -name "*.py" -exec wc -l {} \; 2>/dev/null | sort -rn | head -5 | while read lines file; do
        rel_path=$(echo "$file" | sed "s|$PYTHON_DIR/||")
        printf "    - %-50s %6s lines\n" "$rel_path" "$lines" | tee -a "$OUTPUT_FILE"
    done
else
    echo "  Directory not found!" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 3. HTML Files
echo "3. HTML FILES" | tee -a "$OUTPUT_FILE"
echo "-------------" | tee -a "$OUTPUT_FILE"
HTML_DIR="/home/dev01/projects/jsys/pig_ops/webroot"
if [ -d "$HTML_DIR" ]; then
    HTML_COUNT=$(find "$HTML_DIR" -type f -name "*.html" 2>/dev/null | wc -l)
    HTML_LINES=$(find "$HTML_DIR" -type f -name "*.html" -exec cat {} \; 2>/dev/null | wc -l)
    echo "  Files: $HTML_COUNT" | tee -a "$OUTPUT_FILE"
    echo "  Lines: $HTML_LINES" | tee -a "$OUTPUT_FILE"
    if [ $HTML_COUNT -gt 0 ]; then
        echo "  Average: $((HTML_LINES / HTML_COUNT)) lines/file" | tee -a "$OUTPUT_FILE"
    fi
fi
echo "" | tee -a "$OUTPUT_FILE"

# 4. JSON Files
echo "4. JSON FILES" | tee -a "$OUTPUT_FILE"
echo "-------------" | tee -a "$OUTPUT_FILE"
JSON_DIR="/home/dev01/projects/jsys/pig_ops/webroot"
if [ -d "$JSON_DIR" ]; then
    JSON_COUNT=$(find "$JSON_DIR" -type f -name "*.json" 2>/dev/null | wc -l)
    JSON_LINES=$(find "$JSON_DIR" -type f -name "*.json" -exec cat {} \; 2>/dev/null | wc -l)
    echo "  Files: $JSON_COUNT" | tee -a "$OUTPUT_FILE"
    echo "  Lines: $JSON_LINES" | tee -a "$OUTPUT_FILE"
    if [ $JSON_COUNT -gt 0 ]; then
        echo "  Average: $((JSON_LINES / JSON_COUNT)) lines/file" | tee -a "$OUTPUT_FILE"
    fi
fi
echo "" | tee -a "$OUTPUT_FILE"

# 5. JavaScript Files (excluding library and jquery)
echo "5. JAVASCRIPT FILES (excluding library & jquery)" | tee -a "$OUTPUT_FILE"
echo "-------------------------------------------------" | tee -a "$OUTPUT_FILE"
JS_DIR="/home/dev01/projects/jsys/pig_ops_ui_mob/src/static/js"
if [ -d "$JS_DIR" ]; then
    JS_COUNT=$(find "$JS_DIR" -type f -name "*.js" ! -path "*/library/*" ! -path "*/jquery/*" 2>/dev/null | wc -l)
    JS_LINES=$(find "$JS_DIR" -type f -name "*.js" ! -path "*/library/*" ! -path "*/jquery/*" -exec cat {} \; 2>/dev/null | wc -l)
    echo "  Files: $JS_COUNT" | tee -a "$OUTPUT_FILE"
    echo "  Lines: $JS_LINES" | tee -a "$OUTPUT_FILE"
    if [ $JS_COUNT -gt 0 ]; then
        echo "  Average: $((JS_LINES / JS_COUNT)) lines/file" | tee -a "$OUTPUT_FILE"
    fi
    echo "" | tee -a "$OUTPUT_FILE"
    
    # List all JS files with line counts
    echo "  All JavaScript files:" | tee -a "$OUTPUT_FILE"
    find "$JS_DIR" -type f -name "*.js" ! -path "*/library/*" ! -path "*/jquery/*" -exec wc -l {} \; 2>/dev/null | sort -rn | while read lines file; do
        rel_path=$(echo "$file" | sed "s|$JS_DIR/||")
        printf "    - %-40s %6s lines\n" "$rel_path" "$lines" | tee -a "$OUTPUT_FILE"
    done
else
    echo "  Directory not found!" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 6. CSS File
echo "6. CSS FILE (main.css)" | tee -a "$OUTPUT_FILE"
echo "----------------------" | tee -a "$OUTPUT_FILE"
CSS_FILE="/home/dev01/projects/jsys/pig_ops_ui_mob/src/static/css/main.css"
if [ -f "$CSS_FILE" ]; then
    CSS_LINES=$(wc -l < "$CSS_FILE")
    echo "  File: main.css" | tee -a "$OUTPUT_FILE"
    echo "  Lines: $CSS_LINES" | tee -a "$OUTPUT_FILE"
else
    echo "  File not found!" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 7. Shell Scripts
echo "7. SHELL SCRIPTS" | tee -a "$OUTPUT_FILE"
echo "----------------" | tee -a "$OUTPUT_FILE"
SH_DIR="/home/dev01/projects/jsys"
if [ -d "$SH_DIR" ]; then
    SH_COUNT=$(find "$SH_DIR" -type f -name "*.sh" 2>/dev/null | wc -l)
    SH_LINES=$(find "$SH_DIR" -type f -name "*.sh" -exec cat {} \; 2>/dev/null | wc -l)
    echo "  Files: $SH_COUNT" | tee -a "$OUTPUT_FILE"
    echo "  Lines: $SH_LINES" | tee -a "$OUTPUT_FILE"
    if [ $SH_COUNT -gt 0 ]; then
        echo "  Average: $((SH_LINES / SH_COUNT)) lines/file" | tee -a "$OUTPUT_FILE"
    fi
    echo "" | tee -a "$OUTPUT_FILE"
    
    # List all shell scripts
    echo "  All shell scripts:" | tee -a "$OUTPUT_FILE"
    find "$SH_DIR" -type f -name "*.sh" -exec wc -l {} \; 2>/dev/null | sort -rn | while read lines file; do
        rel_path=$(echo "$file" | sed "s|$SH_DIR/||")
        printf "    - %-60s %6s lines\n" "$rel_path" "$lines" | tee -a "$OUTPUT_FILE"
    done
else
    echo "  Directory not found!" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# GRAND TOTALS
echo "========================================" | tee -a "$OUTPUT_FILE"
echo "          GRAND TOTALS" | tee -a "$OUTPUT_FILE"
echo "========================================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

TOTAL_FILES=$((PROC_COUNT + PYTHON_COUNT + HTML_COUNT + JSON_COUNT + JS_COUNT + SH_COUNT + 1))
TOTAL_LINES=$((PROC_LINES + PYTHON_LINES + HTML_LINES + JSON_LINES + JS_LINES + SH_LINES + CSS_LINES))

echo -e "${CYAN}Total Files:${NC} $TOTAL_FILES" | tee -a "$OUTPUT_FILE"
echo -e "${CYAN}Total Lines:${NC} $TOTAL_LINES" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# Summary by type
echo "Summary by Type:" | tee -a "$OUTPUT_FILE"
echo "---------------" | tee -a "$OUTPUT_FILE"
printf "%-35s %10s %12s %12s\n" "Type" "Files" "Lines" "Avg/File" | tee -a "$OUTPUT_FILE"
printf "%-35s %10s %12s %12s\n" "-----" "-----" "-----" "--------" | tee -a "$OUTPUT_FILE"
printf "%-35s %10d %12d %12d\n" "MySQL Procedures" "$PROC_COUNT" "$PROC_LINES" "$((PROC_LINES / PROC_COUNT))" 2>/dev/null | tee -a "$OUTPUT_FILE"
printf "%-35s %10d %12d %12d\n" "Python Files" "$PYTHON_COUNT" "$PYTHON_LINES" "$((PYTHON_LINES / PYTHON_COUNT))" 2>/dev/null | tee -a "$OUTPUT_FILE"
printf "%-35s %10d %12d %12d\n" "HTML Files" "$HTML_COUNT" "$HTML_LINES" "$((HTML_LINES / HTML_COUNT))" 2>/dev/null | tee -a "$OUTPUT_FILE"
printf "%-35s %10d %12d %12d\n" "JSON Files" "$JSON_COUNT" "$JSON_LINES" "$((JSON_LINES / JSON_COUNT))" 2>/dev/null | tee -a "$OUTPUT_FILE"
printf "%-35s %10d %12d %12d\n" "JavaScript Files" "$JS_COUNT" "$JS_LINES" "$((JS_LINES / JS_COUNT))" 2>/dev/null | tee -a "$OUTPUT_FILE"
printf "%-35s %10d %12d %12s\n" "CSS (main.css)" "1" "$CSS_LINES" "$CSS_LINES" | tee -a "$OUTPUT_FILE"
printf "%-35s %10d %12d %12d\n" "Shell Scripts" "$SH_COUNT" "$SH_LINES" "$((SH_LINES / SH_COUNT))" 2>/dev/null | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

echo "========================================" | tee -a "$OUTPUT_FILE"
echo "Report saved to: $OUTPUT_FILE" | tee -a "$OUTPUT_FILE"
echo "========================================" | tee -a "$OUTPUT_FILE"

# Also display the report
cat "$OUTPUT_FILE"
