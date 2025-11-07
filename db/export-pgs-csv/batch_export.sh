#!/bin/bash

################################################################################
# Script: batch_export.sh
# Description: Export multiple PostgreSQL tables to CSV files
################################################################################

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-mydb}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-}"
EXPORT_METHOD="${EXPORT_METHOD:-psql}"
OUTPUT_DIR="${OUTPUT_DIR:-./exports}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to export a single table
export_table() {
    local table=$1
    local output_file="$OUTPUT_DIR/${table}_$(date +%Y%m%d_%H%M%S).csv"
    
    print_info "Exporting table: $table"
    
    if ./pg_dump_to_csv.sh \
        -h "$DB_HOST" \
        -p "$DB_PORT" \
        -d "$DB_NAME" \
        -u "$DB_USER" \
        -w "$DB_PASSWORD" \
        -t "$table" \
        -o "$output_file" \
        -m "$EXPORT_METHOD" > /dev/null 2>&1; then
        
        local rows=$(( $(wc -l < "$output_file") - 1 ))
        print_success "✓ $table exported: $rows rows -> $output_file"
        return 0
    else
        print_error "✗ Failed to export $table"
        return 1
    fi
}

# Function to get all tables from database
get_all_tables() {
    export PGPASSWORD="$DB_PASSWORD"
    
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
        ORDER BY tablename;
    " | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$'
}

# Usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] [TABLE1 TABLE2 ...]

Export multiple PostgreSQL tables to CSV files.

Options:
    -h, --host HOST          Database host (default: localhost)
    -p, --port PORT          Database port (default: 5432)
    -d, --database DATABASE  Database name (required)
    -u, --user USER          Database user (default: postgres)
    -w, --password PASSWORD  Database password
    -o, --output-dir DIR     Output directory (default: ./exports)
    -m, --method METHOD      Export method: 'dump' or 'psql' (default: psql)
    -a, --all                Export all tables in the database
    --help                   Display this help message

Examples:
    # Export specific tables
    $0 -d mydb users products orders
    
    # Export all tables
    $0 -d mydb --all
    
    # Export to specific directory
    $0 -d mydb -o /backup/exports users products
    
    # Using environment variables
    export DB_NAME=mydb
    export OUTPUT_DIR=/backup
    $0 users products orders

EOF
}

# Parse command line arguments
EXPORT_ALL=false
TABLES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--host)
            DB_HOST="$2"
            shift 2
            ;;
        -p|--port)
            DB_PORT="$2"
            shift 2
            ;;
        -d|--database)
            DB_NAME="$2"
            shift 2
            ;;
        -u|--user)
            DB_USER="$2"
            shift 2
            ;;
        -w|--password)
            DB_PASSWORD="$2"
            shift 2
            ;;
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -m|--method)
            EXPORT_METHOD="$2"
            shift 2
            ;;
        -a|--all)
            EXPORT_ALL=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            TABLES+=("$1")
            shift
            ;;
    esac
done

# Main execution
main() {
    print_info "=== PostgreSQL Batch Export to CSV ==="
    print_info "Database: $DB_NAME @ $DB_HOST:$DB_PORT"
    print_info "Output Directory: $OUTPUT_DIR"
    print_info "Export Method: $EXPORT_METHOD"
    echo ""
    
    # Get tables to export
    local tables_to_export=()
    
    if [ "$EXPORT_ALL" = true ]; then
        print_info "Fetching all tables from database..."
        mapfile -t tables_to_export < <(get_all_tables)
        
        if [ ${#tables_to_export[@]} -eq 0 ]; then
            print_error "No tables found in database"
            exit 1
        fi
        
        print_info "Found ${#tables_to_export[@]} tables to export"
    elif [ ${#TABLES[@]} -gt 0 ]; then
        tables_to_export=("${TABLES[@]}")
        print_info "Exporting ${#tables_to_export[@]} specified tables"
    else
        print_error "No tables specified. Use --all or provide table names."
        usage
        exit 1
    fi
    
    echo ""
    print_info "Starting export..."
    echo ""
    
    # Export each table
    local success_count=0
    local fail_count=0
    local start_time=$(date +%s)
    
    for table in "${tables_to_export[@]}"; do
        if export_table "$table"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    print_info "=== Export Summary ==="
    print_info "Total tables: ${#tables_to_export[@]}"
    print_success "Successful: $success_count"
    if [ $fail_count -gt 0 ]; then
        print_error "Failed: $fail_count"
    fi
    print_info "Duration: ${duration}s"
    print_info "Output directory: $OUTPUT_DIR"
    echo ""
    
    # List exported files
    print_info "Exported files:"
    ls -lh "$OUTPUT_DIR" | tail -n +2 | awk '{print "  " $9 " (" $5 ")"}'
    
    if [ $fail_count -eq 0 ]; then
        echo ""
        print_success "All exports completed successfully! ✓"
        exit 0
    else
        exit 1
    fi
}

# Run main function
main
