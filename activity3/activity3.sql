-- Drop tables if they exist to ensure a clean slate
DROP TABLE IF EXISTS products_audit;
DROP TABLE IF EXISTS products;

-- Create the main table for products
CREATE TABLE products (
    product_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_modified TIMESTAMPTZ DEFAULT NOW()
);

-- Create the audit table to log changes to the products table
CREATE TABLE products_audit (
    audit_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id INT NOT NULL,
    change_type TEXT NOT NULL, -- e.g., 'INSERT', 'UPDATE', 'DELETE'
    old_name TEXT,
    new_name TEXT,
    old_price NUMERIC(10, 2),
    new_price NUMERIC(10, 2),
    change_timestamp TIMESTAMPTZ DEFAULT NOW(),
    db_user TEXT DEFAULT current_user
);

-- Insert some initial data to work with
INSERT INTO products (name, description, price, stock_quantity) VALUES
('Super Widget', 'A high-quality widget for all your needs.', 29.99, 100),
('Mega Gadget', 'The latest and greatest gadget.', 199.50, 50),
('Basic Gizmo', 'A simple gizmo for everyday tasks.', 9.75, 250);