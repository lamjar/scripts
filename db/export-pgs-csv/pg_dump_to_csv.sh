#!/bin/bash

################################################################################
# Script: pg_dump_to_csv.sh
# Description: Execute pg_dump and convert output to CSV with headers
#              WITHOUT using the COPY command
################################################################################

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-mydb}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-}"
TABLE_NAME="${TABLE_NAME:-mytable}"
OUTPUT_FILE="${OUTPUT_FILE:-output.csv}"
COLUMNS="${COLUMNS:-}"  # Comma-separated list of columns, or empty for all columns
INTERACTIVE="${INTERACTIVE:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if PostgreSQL tools are installed
check_dependencies() {
    if ! command -v psql &> /dev/null; then
        print_error "psql is not installed. Please install PostgreSQL client tools."
        exit 1
    fi
}

# Function to test database connection
test_connection() {
    print_info "Testing database connection..."
    
    export PGPASSWORD="$DB_PASSWORD"
    
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &> /dev/null; then
        print_info "Connection successful!"
        return 0
    else
        print_error "Cannot connect to database"
        return 1
    fi
}

# Function to get all column names from table
get_all_column_names() {
    export PGPASSWORD="$DB_PASSWORD"
    
    local columns=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT string_agg(column_name, ',')
        FROM information_schema.columns
        WHERE table_name = '$TABLE_NAME'
        ORDER BY ordinal_position;
    " | tr -d ' ' | tr -d '\n')
    
    echo "$columns"
}

# Function to get column names (selected or all)
get_column_names() {
    if [ -n "$COLUMNS" ]; then
        # Use user-specified columns
        echo "$COLUMNS"
    else
        # Get all columns
        get_all_column_names
    fi
}

# Function to list available columns
list_available_columns() {
    export PGPASSWORD="$DB_PASSWORD"
    
    print_info "Available columns in table '$TABLE_NAME':"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT 
            ordinal_position as \"#\",
            column_name as \"Column Name\",
            data_type as \"Type\",
            CASE WHEN is_nullable = 'YES' THEN 'NULL' ELSE 'NOT NULL' END as \"Nullable\"
        FROM information_schema.columns
        WHERE table_name = '$TABLE_NAME'
        ORDER BY ordinal_position;
    "
}

# Function for interactive column selection
interactive_column_selection() {
    print_info "Interactive column selection for table '$TABLE_NAME'"
    echo ""
    
    # Get all columns
    local all_cols=$(get_all_column_names)
    IFS=',' read -ra COLS_ARRAY <<< "$all_cols"
    
    # Display available columns
    print_info "Available columns:"
    local i=1
    for col in "${COLS_ARRAY[@]}"; do
        echo "  $i) $col"
        ((i++))
    done
    echo "  a) All columns"
    echo ""
    
    # Ask user to select
    read -p "Select columns (comma-separated numbers, 'a' for all, or column names): " selection
    
    if [ "$selection" = "a" ] || [ "$selection" = "A" ]; then
        COLUMNS="$all_cols"
        print_info "Selected all columns"
    elif [[ "$selection" =~ ^[0-9,]+$ ]]; then
        # User entered numbers
        IFS=',' read -ra SELECTED_NUMS <<< "$selection"
        local selected_cols=()
        for num in "${SELECTED_NUMS[@]}"; do
            num=$(echo "$num" | tr -d ' ')
            if [ "$num" -ge 1 ] && [ "$num" -le "${#COLS_ARRAY[@]}" ]; then
                selected_cols+=("${COLS_ARRAY[$((num-1))]}")
            fi
        done
        COLUMNS=$(IFS=','; echo "${selected_cols[*]}")
        print_info "Selected columns: $COLUMNS"
    else
        # User entered column names directly
        COLUMNS="$selection"
        print_info "Selected columns: $COLUMNS"
    fi
    
    echo ""
}

# Function to validate selected columns
validate_columns() {
    if [ -z "$COLUMNS" ]; then
        return 0
    fi
    
    export PGPASSWORD="$DB_PASSWORD"
    
    local all_cols=$(get_all_column_names)
    IFS=',' read -ra ALL_COLS_ARRAY <<< "$all_cols"
    IFS=',' read -ra SELECTED_COLS_ARRAY <<< "$COLUMNS"
    
    for selected_col in "${SELECTED_COLS_ARRAY[@]}"; do
        selected_col=$(echo "$selected_col" | tr -d ' ')
        local found=false
        for available_col in "${ALL_COLS_ARRAY[@]}"; do
            if [ "$selected_col" = "$available_col" ]; then
                found=true
                break
            fi
        done
        
        if [ "$found" = false ]; then
            print_error "Column '$selected_col' does not exist in table '$TABLE_NAME'"
            return 1
        fi
    done
    
    return 0
}

# Function to export data to CSV using pg_dump with custom format
export_with_pg_dump() {
    print_info "Exporting table '$TABLE_NAME' to CSV..."
    
    export PGPASSWORD="$DB_PASSWORD"
    
    # Get column names for header
    local header=$(get_column_names)
    
    if [ -z "$header" ]; then
        print_error "Could not retrieve column names. Check if table exists."
        return 1
    fi
    
    print_info "Header: $header"
    
    # Write header to CSV file
    echo "$header" > "$OUTPUT_FILE"
    
    # Use pg_dump with --data-only and --inserts to get INSERT statements
    # Then parse them to extract values
    print_info "Dumping data using pg_dump..."
    
    pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        --table="$TABLE_NAME" \
        --data-only \
        --column-inserts \
        --no-owner \
        --no-privileges | \
        grep "^INSERT INTO" | \
        sed -E 's/INSERT INTO [^ ]+ \([^)]+\) VALUES \(//g' | \
        sed 's/);$//' | \
        sed "s/', '/|/g" | \
        sed "s/^'//g" | \
        sed "s/'$//g" | \
        sed 's/|/,/g' >> "$OUTPUT_FILE"
    
    if [ $? -eq 0 ]; then
        print_info "Export completed successfully!"
        print_info "Output file: $OUTPUT_FILE"
        
        # Display file statistics
        local line_count=$(wc -l < "$OUTPUT_FILE")
        local data_rows=$((line_count - 1))
        print_info "Total rows exported: $data_rows (+ 1 header)"
        
        return 0
    else
        print_error "Export failed"
        return 1
    fi
}

# Alternative method using psql with custom query
export_with_psql() {
    print_info "Exporting table '$TABLE_NAME' to CSV using psql..."
    
    export PGPASSWORD="$DB_PASSWORD"
    
    # Get column names for header
    local columns=$(get_column_names)
    
    if [ -z "$columns" ]; then
        print_error "Could not retrieve column names. Check if table exists."
        return 1
    fi
    
    # Write header
    echo "$columns" > "$OUTPUT_FILE"
    
    # Build SELECT statement with specific columns
    local select_cols="${columns}"
    
    print_info "Exporting columns: $select_cols"
    
    # Export data with custom formatting
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -F',' -c "
        SELECT $select_cols FROM $TABLE_NAME;
    " >> "$OUTPUT_FILE"
    
    if [ $? -eq 0 ]; then
        print_info "Export completed successfully!"
        print_info "Output file: $OUTPUT_FILE"
        
        # Display file statistics
        local line_count=$(wc -l < "$OUTPUT_FILE")
        local data_rows=$((line_count - 1))
        print_info "Total rows exported: $data_rows (+ 1 header)"
        
        return 0
    else
        print_error "Export failed"
        return 1
    fi
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -h, --host HOST          Database host (default: localhost)
    -p, --port PORT          Database port (default: 5432)
    -d, --database DATABASE  Database name (required)
    -u, --user USER          Database user (default: postgres)
    -w, --password PASSWORD  Database password
    -t, --table TABLE        Table name to export (required)
    -c, --columns COLUMNS    Comma-separated list of columns to export (default: all)
    -o, --output FILE        Output CSV file (default: output.csv)
    -m, --method METHOD      Export method: 'dump' or 'psql' (default: psql)
    -i, --interactive        Interactive column selection mode
    -l, --list-columns       List available columns and exit
    --help                   Display this help message

Environment Variables:
    DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, TABLE_NAME, OUTPUT_FILE, COLUMNS

Examples:
    # Export all columns
    $0 -d mydb -t users -o users.csv
    
    # Export specific columns
    $0 -d mydb -t users -c "id,name,email" -o users.csv
    
    # Interactive mode (select columns interactively)
    $0 -d mydb -t users -i -o users.csv
    
    # List available columns
    $0 -d mydb -t users -l
    
    # With credentials
    $0 -h localhost -p 5432 -d mydb -u postgres -w mypassword -t users -c "id,username,email" -o users.csv
    
    # Using environment variables
    export DB_HOST=localhost
    export DB_NAME=mydb
    export TABLE_NAME=users
    export COLUMNS="id,name,email,created_at"
    $0

EOF
}

# Parse command line arguments
METHOD="psql"
LIST_COLUMNS_ONLY=false

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
        -t|--table)
            TABLE_NAME="$2"
            shift 2
            ;;
        -c|--columns)
            COLUMNS="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -m|--method)
            METHOD="$2"
            shift 2
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        -l|--list-columns)
            LIST_COLUMNS_ONLY=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_info "=== PostgreSQL Export to CSV ==="
    print_info "Host: $DB_HOST:$DB_PORT"
    print_info "Database: $DB_NAME"
    print_info "User: $DB_USER"
    print_info "Table: $TABLE_NAME"
    
    # Check dependencies
    check_dependencies
    
    # Test connection
    if ! test_connection; then
        exit 1
    fi
    
    # If list-columns only, display and exit
    if [ "$LIST_COLUMNS_ONLY" = true ]; then
        list_available_columns
        exit 0
    fi
    
    # Interactive column selection if requested
    if [ "$INTERACTIVE" = true ]; then
        interactive_column_selection
    fi
    
    # Validate selected columns
    if ! validate_columns; then
        exit 1
    fi
    
    # Display selected columns
    if [ -n "$COLUMNS" ]; then
        print_info "Selected columns: $COLUMNS"
    else
        print_info "Columns: All columns"
    fi
    
    print_info "Output: $OUTPUT_FILE"
    print_info "Method: $METHOD"
    echo ""
    
    # Execute export based on method
    case $METHOD in
        dump)
            export_with_pg_dump
            ;;
        psql)
            export_with_psql
            ;;
        *)
            print_error "Unknown method: $METHOD. Use 'dump' or 'psql'"
            exit 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        print_info "Preview of exported data:"
        head -n 5 "$OUTPUT_FILE"
        echo ""
        print_info "Done!"
    else
        exit 1
    fi
}

# Run main function
main

