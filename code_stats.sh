#!/bin/bash

# Detailed Code Statistics Script - Relative Paths Version
# Now includes Git commit counts for each repository

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get script directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Project base is relative to script location
# Assuming script is in pig_ops_db/ directory
PROJECT_BASE="$SCRIPT_DIR/.."

OUTPUT_FILE="/tmp/code_stats_detailed.txt"

# Function to get commit count for a Git repository
get_commit_count() {
    local repo_path="$1"
    local repo_name="$2"
    
    if [ -d "$repo_path/.git" ]; then
        cd "$repo_path" 2>/dev/null
        local commit_count=$(git rev-list --count HEAD 2>/dev/null)
        local last_commit_date=$(git log -1 --format=%cd --date=short 2>/dev/null)
        local last_commit_hash=$(git log -1 --format=%h 2>/dev/null)
        local branch=$(git branch --show-current 2>/dev/null)
        
        if [ -n "$commit_count" ]; then
            echo "    Git: $commit_count commits, branch: $branch, last: $last_commit_date ($last_commit_hash)"
        else
            echo "    Git: Unable to count commits"
        fi
        cd - > /dev/null 2>&1
    else
        echo "    Git: Not a repository (no .git folder)"
    fi
}

# Function to get detailed Git stats
get_git_stats() {
    local repo_path="$1"
    
    if [ -d "$repo_path/.git" ]; then
        cd "$repo_path" 2>/dev/null
        
        local total_commits=$(git rev-list --count HEAD 2>/dev/null)
        local contributors=$(git log --format='%aN' | sort -u | wc -l 2>/dev/null)
        local first_commit=$(git log --reverse --format=%cd --date=short | head -1 2>/dev/null)
        local last_commit=$(git log -1 --format=%cd --date=short 2>/dev/null)
        local branches=$(git branch -r | wc -l 2>/dev/null)
        local current_branch=$(git branch --show-current 2>/dev/null)
        
        # Count commits per author (top 3)
        local top_authors=$(git shortlog -sn 2>/dev/null | head -3)
        
        echo "    Git Statistics:"
        echo "      Total commits: $total_commits"
        echo "      Contributors: $contributors"
        echo "      Branches (remote): $branches"
        echo "      Current branch: $current_branch"
        echo "      First commit: $first_commit"
        echo "      Last commit: $last_commit"
        echo "      Top contributors:"
        echo "$top_authors" | while read line; do
            echo "        $line"
        done
        
        cd - > /dev/null 2>&1
    else
        echo "    Git: Not a repository"
    fi
}

echo "========================================" | tee "$OUTPUT_FILE"
echo "    DETAILED CODE STATISTICS REPORT" | tee -a "$OUTPUT_FILE"
echo "    Generated: $(date)" | tee -a "$OUTPUT_FILE"
echo "    Project: $PROJECT_BASE" | tee -a "$OUTPUT_FILE"
echo "========================================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 0. GIT REPOSITORY STATUS
echo "0. GIT REPOSITORY STATUS" | tee -a "$OUTPUT_FILE"
echo "========================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# Check each repository
for repo in pig_ops_db pig_ops pig_ops_bkops pig_ops_ui_mob; do
    REPO_DIR="$PROJECT_BASE/$repo"
    if [ -d "$REPO_DIR" ]; then
        echo -e "${GREEN}Repository: $repo${NC}" | tee -a "$OUTPUT_FILE"
        get_git_stats "$REPO_DIR"
        echo "" | tee -a "$OUTPUT_FILE"
    fi
done

# Also check the parent directory if it's a repo
if [ -d "$PROJECT_BASE/.git" ]; then
    echo -e "${GREEN}Repository: jsys (parent)${NC}" | tee -a "$OUTPUT_FILE"
    get_git_stats "$PROJECT_BASE"
    echo "" | tee -a "$OUTPUT_FILE"
fi

echo "" | tee -a "$OUTPUT_FILE"

# 1. MySQL Procedures
echo "1. MySQL PROCEDURES" | tee -a "$OUTPUT_FILE"
echo "-------------------" | tee -a "$OUTPUT_FILE"
PROC_DIR="$PROJECT_BASE/pig_ops_db/database/mysql/procedures"
if [ -d "$PROC_DIR" ]; then
    PROC_COUNT=$(find "$PROC_DIR" -type f -name "*.sql" 2>/dev/null | wc -l)
    PROC_LINES=$(find "$PROC_DIR" -type f -name "*.sql" -exec cat {} \; 2>/dev/null | wc -l)
    echo "  Files: $PROC_COUNT" | tee -a "$OUTPUT_FILE"
    echo "  Lines: $PROC_LINES" | tee -a "$OUTPUT_FILE"
    if [ $PROC_COUNT -gt 0 ]; then
        echo "  Average: $((PROC_LINES / PROC_COUNT)) lines/file" | tee -a "$OUTPUT_FILE"
    fi
    echo "" | tee -a "$OUTPUT_FILE"
    
    echo "  Files:" | tee -a "$OUTPUT_FILE"
    find "$PROC_DIR" -type f -name "*.sql" -exec basename {} \; | sort | while read file; do
        lines=$(wc -l < "$PROC_DIR/$file" 2>/dev/null)
        printf "    - %-40s %6s lines\n" "$file" "$lines" | tee -a "$OUTPUT_FILE"
    done
else
    echo "  Directory not found: $PROC_DIR" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 2. Database Migrations
echo "2. DATABASE MIGRATIONS" | tee -a "$OUTPUT_FILE"
echo "----------------------" | tee -a "$OUTPUT_FILE"
MIGRATIONS_DIR="$PROJECT_BASE/pig_ops_db/database/mysql/migrations"
if [ -d "$MIGRATIONS_DIR" ]; then
    # Count files (including symlinks)
    MIGRATIONS_COUNT=$(find "$MIGRATIONS_DIR" -maxdepth 1 -type f -o -type l 2>/dev/null | wc -l)
    
    # Count only regular files (skip symlinks to avoid double-counting with procedures)
    MIGRATIONS_LINES=0
    MIGRATIONS_REGULAR_COUNT=0
    
    while IFS= read -r file; do
        if [ -f "$file" ] && [ ! -L "$file" ]; then
            # Regular file only - count its lines
            lines=$(cat "$file" 2>/dev/null | wc -l)
            MIGRATIONS_LINES=$((MIGRATIONS_LINES + lines))
            MIGRATIONS_REGULAR_COUNT=$((MIGRATIONS_REGULAR_COUNT + 1))
        elif [ -L "$file" ]; then
            # Symlink - do NOT count lines (already counted in procedures)
            # Just note that it exists
            :
        fi
    done < <(find "$MIGRATIONS_DIR" -maxdepth 1 -type f -o -type l | sort)
    
    echo "  Files (total, including symlinks): $MIGRATIONS_COUNT" | tee -a "$OUTPUT_FILE"
    echo "  Regular migration files: $MIGRATIONS_REGULAR_COUNT" | tee -a "$OUTPUT_FILE"
    echo "  Lines (regular files only): $MIGRATIONS_LINES" | tee -a "$OUTPUT_FILE"
    if [ $MIGRATIONS_REGULAR_COUNT -gt 0 ]; then
        echo "  Average: $((MIGRATIONS_LINES / MIGRATIONS_REGULAR_COUNT)) lines/file" | tee -a "$OUTPUT_FILE"
    fi
    echo "" | tee -a "$OUTPUT_FILE"
    
    echo "  Migration Files:" | tee -a "$OUTPUT_FILE"
    find "$MIGRATIONS_DIR" -maxdepth 1 -type f -o -type l | sort | while read file; do
        filename=$(basename "$file")
        if [ -L "$file" ]; then
            # Symlink - show without line count
            target=$(readlink -f "$file" 2>/dev/null)
            if [ -f "$target" ]; then
                echo "    - $filename -> $(basename "$target") (symlink, counted in procedures)" | tee -a "$OUTPUT_FILE"
            else
                echo "    - $filename -> (broken symlink)" | tee -a "$OUTPUT_FILE"
            fi
        else
            # Regular file - show line count
            lines=$(wc -l < "$file" 2>/dev/null)
            printf "    - %-50s %6s lines\n" "$filename" "$lines" | tee -a "$OUTPUT_FILE"
        fi
    done
else
    echo "  Directory not found: $MIGRATIONS_DIR" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 3. Python Files (Backend - pig_ops/webroot)
echo "3. PYTHON FILES (Backend)" | tee -a "$OUTPUT_FILE"
echo "------------------------" | tee -a "$OUTPUT_FILE"
PYTHON_DIR="$PROJECT_BASE/pig_ops/webroot"
if [ -d "$PYTHON_DIR" ]; then
    PYTHON_COUNT=$(find "$PYTHON_DIR" -type f -name "*.py" 2>/dev/null | wc -l)
    PYTHON_LINES=$(find "$PYTHON_DIR" -type f -name "*.py" -exec cat {} \; 2>/dev/null | wc -l)
    echo "  Files: $PYTHON_COUNT" | tee -a "$OUTPUT_FILE"
    echo "  Lines: $PYTHON_LINES" | tee -a "$OUTPUT_FILE"
    if [ $PYTHON_COUNT -gt 0 ]; then
        echo "  Average: $((PYTHON_LINES / PYTHON_COUNT)) lines/file" | tee -a "$OUTPUT_FILE"
    fi
    echo "" | tee -a "$OUTPUT_FILE"
    
    echo "  Top 5 largest Python files:" | tee -a "$OUTPUT_FILE"
    find "$PYTHON_DIR" -type f -name "*.py" -exec wc -l {} \; 2>/dev/null | sort -rn | head -5 | while read lines file; do
        rel_path=$(echo "$file" | sed "s|$PYTHON_DIR/||")
        printf "    - %-50s %6s lines\n" "$rel_path" "$lines" | tee -a "$OUTPUT_FILE"
    done
else
    echo "  Directory not found: $PYTHON_DIR" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 3b. Python Files (Frontend build scripts - pig_ops_ui_mob)
echo "3b. PYTHON FILES (Frontend Build)" | tee -a "$OUTPUT_FILE"
echo "---------------------------------" | tee -a "$OUTPUT_FILE"
PYTHON_UI_DIR="$PROJECT_BASE/pig_ops_ui_mob"
if [ -d "$PYTHON_UI_DIR" ]; then
    PYTHON_UI_COUNT=$(find "$PYTHON_UI_DIR" -type f -name "*.py" 2>/dev/null | wc -l)
    PYTHON_UI_LINES=$(find "$PYTHON_UI_DIR" -type f -name "*.py" -exec cat {} \; 2>/dev/null | wc -l)
    echo "  Files: $PYTHON_UI_COUNT" | tee -a "$OUTPUT_FILE"
    echo "  Lines: $PYTHON_UI_LINES" | tee -a "$OUTPUT_FILE"
    if [ $PYTHON_UI_COUNT -gt 0 ]; then
        echo "  Average: $((PYTHON_UI_LINES / PYTHON_UI_COUNT)) lines/file" | tee -a "$OUTPUT_FILE"
    fi
    echo "" | tee -a "$OUTPUT_FILE"
    
    echo "  All Python build scripts:" | tee -a "$OUTPUT_FILE"
    find "$PYTHON_UI_DIR" -type f -name "*.py" -exec wc -l {} \; 2>/dev/null | sort -rn | while read lines file; do
        rel_path=$(echo "$file" | sed "s|$PYTHON_UI_DIR/||")
        printf "    - %-50s %6s lines\n" "$rel_path" "$lines" | tee -a "$OUTPUT_FILE"
    done
else
    echo "  Directory not found: $PYTHON_UI_DIR" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 3c. Python Files (Background Operations - pig_ops_bkops)
echo "3c. PYTHON FILES (Background Ops - bkops)" | tee -a "$OUTPUT_FILE"
echo "------------------------------------------" | tee -a "$OUTPUT_FILE"
PYTHON_BKOPS_DIR="$PROJECT_BASE/pig_ops_bkops"
if [ -d "$PYTHON_BKOPS_DIR" ]; then
    PYTHON_BKOPS_COUNT=$(find "$PYTHON_BKOPS_DIR" -type f -name "*.py" 2>/dev/null | wc -l)
    PYTHON_BKOPS_LINES=$(find "$PYTHON_BKOPS_DIR" -type f -name "*.py" -exec cat {} \; 2>/dev/null | wc -l)
    echo "  Files: $PYTHON_BKOPS_COUNT" | tee -a "$OUTPUT_FILE"
    echo "  Lines: $PYTHON_BKOPS_LINES" | tee -a "$OUTPUT_FILE"
    if [ $PYTHON_BKOPS_COUNT -gt 0 ]; then
        echo "  Average: $((PYTHON_BKOPS_LINES / PYTHON_BKOPS_COUNT)) lines/file" | tee -a "$OUTPUT_FILE"
    fi
    echo "" | tee -a "$OUTPUT_FILE"
    
    echo "  All bkops Python files:" | tee -a "$OUTPUT_FILE"
    find "$PYTHON_BKOPS_DIR" -type f -name "*.py" -exec wc -l {} \; 2>/dev/null | sort -rn | while read lines file; do
        rel_path=$(echo "$file" | sed "s|$PYTHON_BKOPS_DIR/||")
        printf "    - %-50s %6s lines\n" "$rel_path" "$lines" | tee -a "$OUTPUT_FILE"
    done
else
    echo "  Directory not found: $PYTHON_BKOPS_DIR" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 4. HTML Files
echo "4. HTML FILES" | tee -a "$OUTPUT_FILE"
echo "-------------" | tee -a "$OUTPUT_FILE"
HTML_DIR="$PROJECT_BASE/pig_ops/webroot"
if [ -d "$HTML_DIR" ]; then
    HTML_COUNT=$(find "$HTML_DIR" -type f -name "*.html" 2>/dev/null | wc -l)
    HTML_LINES=$(find "$HTML_DIR" -type f -name "*.html" -exec cat {} \; 2>/dev/null | wc -l)
    echo "  Files: $HTML_COUNT" | tee -a "$OUTPUT_FILE"
    echo "  Lines: $HTML_LINES" | tee -a "$OUTPUT_FILE"
    if [ $HTML_COUNT -gt 0 ]; then
        echo "  Average: $((HTML_LINES / HTML_COUNT)) lines/file" | tee -a "$OUTPUT_FILE"
    fi
else
    echo "  Directory not found: $HTML_DIR" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 5. JSON Files
echo "5. JSON FILES" | tee -a "$OUTPUT_FILE"
echo "-------------" | tee -a "$OUTPUT_FILE"
JSON_DIR="$PROJECT_BASE/pig_ops/webroot"
if [ -d "$JSON_DIR" ]; then
    JSON_COUNT=$(find "$JSON_DIR" -type f -name "*.json" 2>/dev/null | wc -l)
    JSON_LINES=$(find "$JSON_DIR" -type f -name "*.json" -exec cat {} \; 2>/dev/null | wc -l)
    echo "  Files: $JSON_COUNT" | tee -a "$OUTPUT_FILE"
    echo "  Lines: $JSON_LINES" | tee -a "$OUTPUT_FILE"
    if [ $JSON_COUNT -gt 0 ]; then
        echo "  Average: $((JSON_LINES / JSON_COUNT)) lines/file" | tee -a "$OUTPUT_FILE"
    fi
else
    echo "  Directory not found: $JSON_DIR" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 6. JavaScript Files (excluding library and jquery)
echo "6. JAVASCRIPT FILES (excluding library & jquery)" | tee -a "$OUTPUT_FILE"
echo "-------------------------------------------------" | tee -a "$OUTPUT_FILE"
JS_DIR="$PROJECT_BASE/pig_ops_ui_mob/src/static/js"
if [ -d "$JS_DIR" ]; then
    JS_COUNT=$(find "$JS_DIR" -type f -name "*.js" ! -path "*/library/*" ! -path "*/jquery/*" 2>/dev/null | wc -l)
    JS_LINES=$(find "$JS_DIR" -type f -name "*.js" ! -path "*/library/*" ! -path "*/jquery/*" -exec cat {} \; 2>/dev/null | wc -l)
    echo "  Files: $JS_COUNT" | tee -a "$OUTPUT_FILE"
    echo "  Lines: $JS_LINES" | tee -a "$OUTPUT_FILE"
    if [ $JS_COUNT -gt 0 ]; then
        echo "  Average: $((JS_LINES / JS_COUNT)) lines/file" | tee -a "$OUTPUT_FILE"
    fi
    echo "" | tee -a "$OUTPUT_FILE"
    
    echo "  All JavaScript files:" | tee -a "$OUTPUT_FILE"
    find "$JS_DIR" -type f -name "*.js" ! -path "*/library/*" ! -path "*/jquery/*" -exec wc -l {} \; 2>/dev/null | sort -rn | while read lines file; do
        rel_path=$(echo "$file" | sed "s|$JS_DIR/||")
        printf "    - %-40s %6s lines\n" "$rel_path" "$lines" | tee -a "$OUTPUT_FILE"
    done
else
    echo "  Directory not found: $JS_DIR" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 7. CSS File
echo "7. CSS FILE (main.css)" | tee -a "$OUTPUT_FILE"
echo "----------------------" | tee -a "$OUTPUT_FILE"
CSS_FILE="$PROJECT_BASE/pig_ops_ui_mob/src/static/css/main.css"
if [ -f "$CSS_FILE" ]; then
    CSS_LINES=$(wc -l < "$CSS_FILE")
    echo "  File: main.css" | tee -a "$OUTPUT_FILE"
    echo "  Lines: $CSS_LINES" | tee -a "$OUTPUT_FILE"
else
    echo "  File not found: $CSS_FILE" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 8. Shell Scripts (All repositories)
echo "8. SHELL SCRIPTS" | tee -a "$OUTPUT_FILE"
echo "----------------" | tee -a "$OUTPUT_FILE"

# Count shell scripts from all repositories
SH_COUNT=0
SH_LINES=0

# Check pig_ops for shell scripts
if [ -d "$PROJECT_BASE/pig_ops" ]; then
    SH_COUNT=$((SH_COUNT + $(find "$PROJECT_BASE/pig_ops" -type f -name "*.sh" 2>/dev/null | wc -l)))
    SH_LINES=$((SH_LINES + $(find "$PROJECT_BASE/pig_ops" -type f -name "*.sh" -exec cat {} \; 2>/dev/null | wc -l)))
fi

# Check pig_ops_bkops for shell scripts (including scripts directory)
if [ -d "$PROJECT_BASE/pig_ops_bkops" ]; then
    SH_COUNT=$((SH_COUNT + $(find "$PROJECT_BASE/pig_ops_bkops" -type f -name "*.sh" 2>/dev/null | wc -l)))
    SH_LINES=$((SH_LINES + $(find "$PROJECT_BASE/pig_ops_bkops" -type f -name "*.sh" -exec cat {} \; 2>/dev/null | wc -l)))
fi

# Check pig_ops_db for shell scripts (migrations, etc.)
if [ -d "$PROJECT_BASE/pig_ops_db" ]; then
    SH_COUNT=$((SH_COUNT + $(find "$PROJECT_BASE/pig_ops_db" -type f -name "*.sh" 2>/dev/null | wc -l)))
    SH_LINES=$((SH_LINES + $(find "$PROJECT_BASE/pig_ops_db" -type f -name "*.sh" -exec cat {} \; 2>/dev/null | wc -l)))
fi

# Check pig_ops_ui_mob for shell scripts (build scripts, etc.)
if [ -d "$PROJECT_BASE/pig_ops_ui_mob" ]; then
    SH_COUNT=$((SH_COUNT + $(find "$PROJECT_BASE/pig_ops_ui_mob" -type f -name "*.sh" 2>/dev/null | wc -l)))
    SH_LINES=$((SH_LINES + $(find "$PROJECT_BASE/pig_ops_ui_mob" -type f -name "*.sh" -exec cat {} \; 2>/dev/null | wc -l)))
fi

echo "  Files: $SH_COUNT" | tee -a "$OUTPUT_FILE"
echo "  Lines: $SH_LINES" | tee -a "$OUTPUT_FILE"
if [ $SH_COUNT -gt 0 ]; then
    echo "  Average: $((SH_LINES / SH_COUNT)) lines/file" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

echo "  All shell scripts:" | tee -a "$OUTPUT_FILE"
find "$PROJECT_BASE" -type f -name "*.sh" -exec wc -l {} \; 2>/dev/null | sort -rn | while read lines file; do
    # Get relative path from PROJECT_BASE
    rel_path=$(echo "$file" | sed "s|$PROJECT_BASE/||")
    printf "    - %-60s %6s lines\n" "$rel_path" "$lines" | tee -a "$OUTPUT_FILE"
done

echo "" | tee -a "$OUTPUT_FILE"

# 9. GIT COMMIT SUMMARY
echo "9. GIT COMMIT SUMMARY" | tee -a "$OUTPUT_FILE"
echo "====================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

printf "%-20s %12s %12s %12s\n" "Repository" "Commits" "Contributors" "Last Commit" | tee -a "$OUTPUT_FILE"
printf "%-20s %12s %12s %12s\n" "----------" "-------" "-----------" "-----------" | tee -a "$OUTPUT_FILE"

for repo in pig_ops_db pig_ops pig_ops_bkops pig_ops_ui_mob; do
    REPO_DIR="$PROJECT_BASE/$repo"
    if [ -d "$REPO_DIR/.git" ]; then
        cd "$REPO_DIR"
        commits=$(git rev-list --count HEAD 2>/dev/null)
        contributors=$(git log --format='%aN' | sort -u | wc -l 2>/dev/null)
        last_commit=$(git log -1 --format=%cd --date=short 2>/dev/null)
        printf "%-20s %12s %12s %12s\n" "$repo" "$commits" "$contributors" "$last_commit" | tee -a "$OUTPUT_FILE"
        cd - > /dev/null 2>&1
    else
        printf "%-20s %12s %12s %12s\n" "$repo" "N/A" "N/A" "N/A" | tee -a "$OUTPUT_FILE"
    fi
done

# Check parent repo
if [ -d "$PROJECT_BASE/.git" ]; then
    cd "$PROJECT_BASE"
    commits=$(git rev-list --count HEAD 2>/dev/null)
    contributors=$(git log --format='%aN' | sort -u | wc -l 2>/dev/null)
    last_commit=$(git log -1 --format=%cd --date=short 2>/dev/null)
    printf "%-20s %12s %12s %12s\n" "jsys (parent)" "$commits" "$contributors" "$last_commit" | tee -a "$OUTPUT_FILE"
    cd - > /dev/null 2>&1
fi

echo "" | tee -a "$OUTPUT_FILE"

# GRAND TOTALS
echo "========================================" | tee -a "$OUTPUT_FILE"
echo "          GRAND TOTALS" | tee -a "$OUTPUT_FILE"
echo "========================================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# Count symlinks in migrations directory for DB Update Procedures
MIGRATIONS_SYMLINK_COUNT=0
if [ -d "$MIGRATIONS_DIR" ]; then
    MIGRATIONS_SYMLINK_COUNT=$(find "$MIGRATIONS_DIR" -maxdepth 1 -type l 2>/dev/null | wc -l)
fi

TOTAL_FILES=$((PROC_COUNT + MIGRATIONS_REGULAR_COUNT + PYTHON_COUNT + PYTHON_UI_COUNT + PYTHON_BKOPS_COUNT + HTML_COUNT + JSON_COUNT + JS_COUNT + SH_COUNT + 1))
TOTAL_LINES=$((PROC_LINES + MIGRATIONS_LINES + PYTHON_LINES + PYTHON_UI_LINES + PYTHON_BKOPS_LINES + HTML_LINES + JSON_LINES + JS_LINES + SH_LINES + CSS_LINES))

echo -e "${CYAN}Total Files:${NC} $TOTAL_FILES" | tee -a "$OUTPUT_FILE"
echo -e "${CYAN}Total Lines:${NC} $TOTAL_LINES" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# Summary by type
echo "Summary by Type:" | tee -a "$OUTPUT_FILE"
echo "---------------" | tee -a "$OUTPUT_FILE"
printf "%-24s %10s %12s %12s\n" "Type" "Files" "Lines" "Avg/File" | tee -a "$OUTPUT_FILE"
printf "%-24s %10s %12s %12s\n" "-----" "-----" "-----" "--------" | tee -a "$OUTPUT_FILE"
printf "%-24s %10d %12d %12d\n" "MySQL Procedures" "$PROC_COUNT" "$PROC_LINES" "$((PROC_LINES / PROC_COUNT))" 2>/dev/null | tee -a "$OUTPUT_FILE"
printf "%-24s %10d %12d %12d\n" "DB Migrations" "$MIGRATIONS_REGULAR_COUNT" "$MIGRATIONS_LINES" "$((MIGRATIONS_LINES / MIGRATIONS_REGULAR_COUNT))" 2>/dev/null | tee -a "$OUTPUT_FILE"
printf "%-24s %10d %12s %12s\n" "DB Update Procedures" "$MIGRATIONS_SYMLINK_COUNT" "(symlinks)" "(see MySQL Procedures)" | tee -a "$OUTPUT_FILE"
printf "%-24s %10d %12d %12d\n" "Python (Backend)" "$PYTHON_COUNT" "$PYTHON_LINES" "$((PYTHON_LINES / PYTHON_COUNT))" 2>/dev/null | tee -a "$OUTPUT_FILE"
printf "%-24s %10d %12d %12d\n" "Python (Frontend Build)" "$PYTHON_UI_COUNT" "$PYTHON_UI_LINES" "$((PYTHON_UI_LINES / PYTHON_UI_COUNT))" 2>/dev/null | tee -a "$OUTPUT_FILE"
printf "%-24s %10d %12d %12d\n" "Python (Background Ops)" "$PYTHON_BKOPS_COUNT" "$PYTHON_BKOPS_LINES" "$((PYTHON_BKOPS_LINES / PYTHON_BKOPS_COUNT))" 2>/dev/null | tee -a "$OUTPUT_FILE"
printf "%-24s %10d %12d %12d\n" "HTML Files" "$HTML_COUNT" "$HTML_LINES" "$((HTML_LINES / HTML_COUNT))" 2>/dev/null | tee -a "$OUTPUT_FILE"
printf "%-24s %10d %12d %12d\n" "JSON Files" "$JSON_COUNT" "$JSON_LINES" "$((JSON_LINES / JSON_COUNT))" 2>/dev/null | tee -a "$OUTPUT_FILE"
printf "%-24s %10d %12d %12d\n" "JavaScript Files" "$JS_COUNT" "$JS_LINES" "$((JS_LINES / JS_COUNT))" 2>/dev/null | tee -a "$OUTPUT_FILE"
printf "%-24s %10d %12d %12s\n" "CSS (main.css)" "1" "$CSS_LINES" "$CSS_LINES" | tee -a "$OUTPUT_FILE"
printf "%-24s %10d %12d %12d\n" "Shell Scripts" "$SH_COUNT" "$SH_LINES" "$((SH_LINES / SH_COUNT))" 2>/dev/null | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# Total Git Commits Across All Repos
echo "Git Statistics Summary:" | tee -a "$OUTPUT_FILE"
echo "-----------------------" | tee -a "$OUTPUT_FILE"
TOTAL_COMMITS=0
for repo in pig_ops_db pig_ops pig_ops_bkops pig_ops_ui_mob; do
    REPO_DIR="$PROJECT_BASE/$repo"
    if [ -d "$REPO_DIR/.git" ]; then
        cd "$REPO_DIR"
        commits=$(git rev-list --count HEAD 2>/dev/null)
        TOTAL_COMMITS=$((TOTAL_COMMITS + commits))
        echo "  $repo: $commits commits" | tee -a "$OUTPUT_FILE"
        cd - > /dev/null 2>&1
    fi
done
echo "  -----------------" | tee -a "$OUTPUT_FILE"
echo "  TOTAL: $TOTAL_COMMITS commits across all repositories" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

cat "$OUTPUT_FILE"
