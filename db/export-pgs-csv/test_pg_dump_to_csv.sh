#!/bin/bash

################################################################################
# Script: test_pg_dump_to_csv.sh
# Description: Script de test pour créer une base de données exemple
#              et tester l'export CSV
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Configuration
TEST_DB="test_export_db"
TEST_USER="postgres"
TEST_HOST="localhost"
TEST_PORT="5432"

print_info "=== Test Script for pg_dump_to_csv.sh ==="
echo ""

# Step 1: Create test database
print_step "Creating test database..."

psql -h "$TEST_HOST" -U "$TEST_USER" -c "DROP DATABASE IF EXISTS $TEST_DB;" 2>/dev/null || true
psql -h "$TEST_HOST" -U "$TEST_USER" -c "CREATE DATABASE $TEST_DB;"

print_info "Database '$TEST_DB' created successfully"
echo ""

# Step 2: Create test tables
print_step "Creating test tables..."

psql -h "$TEST_HOST" -U "$TEST_USER" -d "$TEST_DB" << EOF
-- Table: users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    age INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: products
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    stock INTEGER DEFAULT 0,
    category VARCHAR(50)
);

-- Table: orders
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER,
    total_amount DECIMAL(10, 2),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20)
);

-- Insert sample data into users
INSERT INTO users (username, email, age, is_active) VALUES
    ('john_doe', 'john@example.com', 30, true),
    ('jane_smith', 'jane@example.com', 25, true),
    ('bob_johnson', 'bob@example.com', 35, false),
    ('alice_williams', 'alice@example.com', 28, true),
    ('charlie_brown', 'charlie@example.com', 42, true),
    ('diana_prince', 'diana@example.com', 31, true),
    ('frank_castle', 'frank@example.com', 38, false),
    ('grace_hopper', 'grace@example.com', 45, true),
    ('henry_ford', 'henry@example.com', 50, true),
    ('iris_west', 'iris@example.com', 27, true);

-- Insert sample data into products
INSERT INTO products (name, description, price, stock, category) VALUES
    ('Laptop Pro', 'High performance laptop', 1299.99, 50, 'Electronics'),
    ('Wireless Mouse', 'Ergonomic wireless mouse', 29.99, 200, 'Electronics'),
    ('USB-C Cable', '2m USB-C charging cable', 15.99, 500, 'Accessories'),
    ('Mechanical Keyboard', 'RGB mechanical keyboard', 149.99, 75, 'Electronics'),
    ('Monitor 27"', '4K UHD monitor', 449.99, 30, 'Electronics'),
    ('Webcam HD', '1080p webcam with microphone', 79.99, 120, 'Electronics'),
    ('Desk Lamp', 'LED desk lamp with USB port', 34.99, 150, 'Furniture'),
    ('Office Chair', 'Ergonomic office chair', 299.99, 25, 'Furniture'),
    ('Standing Desk', 'Adjustable standing desk', 499.99, 15, 'Furniture'),
    ('Noise Cancelling Headphones', 'Premium ANC headphones', 349.99, 60, 'Electronics');

-- Insert sample data into orders
INSERT INTO orders (user_id, product_id, quantity, total_amount, status) VALUES
    (1, 1, 1, 1299.99, 'completed'),
    (1, 2, 2, 59.98, 'completed'),
    (2, 3, 3, 47.97, 'shipped'),
    (3, 4, 1, 149.99, 'completed'),
    (4, 5, 1, 449.99, 'pending'),
    (5, 6, 2, 159.98, 'completed'),
    (6, 7, 1, 34.99, 'shipped'),
    (7, 8, 1, 299.99, 'completed'),
    (8, 9, 1, 499.99, 'pending'),
    (9, 10, 1, 349.99, 'completed'),
    (10, 1, 1, 1299.99, 'shipped'),
    (1, 4, 1, 149.99, 'completed'),
    (2, 5, 1, 449.99, 'cancelled'),
    (3, 6, 1, 79.99, 'completed'),
    (4, 7, 2, 69.98, 'shipped');
EOF

print_info "Tables created and populated with sample data"
echo ""

# Step 3: Display database info
print_step "Database information:"
psql -h "$TEST_HOST" -U "$TEST_USER" -d "$TEST_DB" -c "\dt"
echo ""

# Step 4: Test exports
print_step "Testing CSV exports..."
echo ""

# Test 1: Export users table with psql method
print_info "Test 1: Exporting 'users' table with psql method..."
./pg_dump_to_csv.sh -h "$TEST_HOST" -d "$TEST_DB" -u "$TEST_USER" -t users -o users.csv -m psql
echo ""

# Test 2: Export products table with pg_dump method
print_info "Test 2: Exporting 'products' table with pg_dump method..."
./pg_dump_to_csv.sh -h "$TEST_HOST" -d "$TEST_DB" -u "$TEST_USER" -t products -o products.csv -m dump
echo ""

# Test 3: Export orders table with psql method
print_info "Test 3: Exporting 'orders' table with psql method..."
./pg_dump_to_csv.sh -h "$TEST_HOST" -d "$TEST_DB" -u "$TEST_USER" -t orders -o orders.csv -m psql
echo ""

# Step 5: Verify exports
print_step "Verifying exported CSV files..."
echo ""

for file in users.csv products.csv orders.csv; do
    if [ -f "$file" ]; then
        lines=$(wc -l < "$file")
        print_info "✓ $file: $lines lines"
        echo "  Preview:"
        head -n 3 "$file" | sed 's/^/    /'
        echo ""
    else
        print_error "✗ $file not found"
    fi
done

# Step 6: Display summary
print_step "Test Summary:"
echo ""
print_info "Database: $TEST_DB"
print_info "Tables exported: users, products, orders"
print_info "CSV files created: users.csv, products.csv, orders.csv"
echo ""

# Optional: Cleanup
read -p "Do you want to drop the test database? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Dropping test database..."
    psql -h "$TEST_HOST" -U "$TEST_USER" -c "DROP DATABASE IF EXISTS $TEST_DB;"
    print_info "Test database dropped"
fi

echo ""
print_info "Test completed successfully! ✓"
