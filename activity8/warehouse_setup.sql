CREATE TABLE dw.etl_log (
    run_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status TEXT,
    rows_loaded INT,
    error_message TEXT
);

CREATE TABLE dw.dim_date (
    date_key SERIAL PRIMARY KEY,
    date DATE UNIQUE,
    day INT,
    month INT,
    year INT,
    quarter INT,
    weekday INT
);

CREATE TABLE dw.dim_customer (
    customer_key SERIAL PRIMARY KEY,
    source_id INT UNIQUE,
    full_name TEXT,
    region_code TEXT
);

CREATE TABLE dw.dim_product (
    product_key SERIAL PRIMARY KEY,
    source_id INT UNIQUE,
    product_name TEXT,
    category TEXT,
    unit_price NUMERIC(10,2)
);

CREATE TABLE dw.dim_branch (
    branch_key SERIAL PRIMARY KEY,
    source_id INT UNIQUE,
    branch_name TEXT,
    city TEXT,
    region TEXT
);

CREATE TABLE dw.fact_sales (
    sales_id SERIAL PRIMARY KEY,
    source_id INT UNIQUE, -- from sales_txn.id
    date_key INT REFERENCES dw.dim_date(date_key),
    customer_key INT REFERENCES dw.dim_customer(customer_key),
    product_key INT REFERENCES dw.dim_product(product_key),
    branch_key INT REFERENCES dw.dim_branch(branch_key),
    qty INT,
    unit_price NUMERIC(10,2),
    total_amount NUMERIC(12,2),
    UNIQUE(source_id)
);

CREATE INDEX idx_fact_sales_date_branch ON dw.fact_sales(date_key, branch_key);