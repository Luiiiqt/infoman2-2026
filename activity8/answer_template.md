# Activity 8 Answer Template

## Part 1: Star Schema Design

### 1. Fact Table Grain

- One row per sales transaction (sales_txn.id). Each row represents a single product sale at a branch to a customer on a specific date.

### 2. Fact Measures

- `qty` – quantity sold
- `unit_price` – price per unit
- `total_amount` – computed as qty * unit_price

### 3. Dimension Tables and Attributes

- `dim_date`: **date_key (surrogate PK), date, day, month, year, quarter, weekday**
- `dim_customer`: **customer_key (surrogate PK), source_id, full_name, region_code**
- `dim_product`: **product_key (surrogate PK), source_id, product_name, category, unit_price**
- `dim_branch`: **branch_key (surrogate PK), source_id, branch_name, city, region**

### 4. Relationship Summary

- **fact_sales.date_key → dim_date.date_key**
- **fact_sales.customer_key → dim_customer.customer_key**
- **fact_sales.product_key → dim_product.product_key**
- **fact_sales.branch_key → dim_branch.branch_key**

## Part 2: Warehouse DDL

```sql
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
```

## Part 3: ETL Procedure

### 1. Procedure Code

```sql
CREATE OR REPLACE PROCEDURE dw.run_sales_etl()
LANGUAGE plpgsql
AS $$
DECLARE
    rows_loaded INT := 0;
BEGIN
    INSERT INTO dw.dim_date(date, day, month, year, quarter, weekday)
    SELECT DISTINCT txn_date,
           EXTRACT(DAY FROM txn_date),
           EXTRACT(MONTH FROM txn_date),
           EXTRACT(YEAR FROM txn_date),
           EXTRACT(QUARTER FROM txn_date),
           EXTRACT(DOW FROM txn_date)
    FROM sales_txn
    ON CONFLICT (date) DO NOTHING;

    INSERT INTO dw.dim_customer(source_id, full_name, region_code)
    SELECT id, full_name, region_code
    FROM customers
    ON CONFLICT (source_id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        region_code = EXCLUDED.region_code;

    INSERT INTO dw.dim_product(source_id, product_name, category, unit_price)
    SELECT id, product_name, category, unit_price
    FROM products
    ON CONFLICT (source_id) DO UPDATE
    SET product_name = EXCLUDED.product_name,
        category = EXCLUDED.category,
        unit_price = EXCLUDED.unit_price;

    INSERT INTO dw.dim_branch(source_id, branch_name, city, region)
    SELECT id, branch_name, city, region
    FROM branches
    ON CONFLICT (source_id) DO UPDATE
    SET branch_name = EXCLUDED.branch_name,
        city = EXCLUDED.city,
        region = EXCLUDED.region;

    INSERT INTO dw.fact_sales(
        source_id, date_key, customer_key, product_key, branch_key,
        qty, unit_price, total_amount
    )
    SELECT 
        s.id,
        d.date_key,
        c.customer_key,
        p.product_key,
        b.branch_key,
        s.qty,
        s.unit_price,
        s.qty * s.unit_price
    FROM sales_txn s
    JOIN dw.dim_date d ON s.txn_date = d.date
    JOIN dw.dim_customer c ON s.customer_id = c.source_id
    JOIN dw.dim_product p ON s.product_id = p.source_id
    JOIN dw.dim_branch b ON s.branch_id = b.source_id
    WHERE 
        s.qty > 0         
        AND s.unit_price > 0     
        AND s.customer_id IS NOT NULL  
        AND s.product_id IS NOT NULL
        AND s.branch_id IS NOT NULL
        AND NOT EXISTS ( 
            SELECT 1 
            FROM dw.fact_sales f 
            WHERE f.source_id = s.id
        );

    GET DIAGNOSTICS rows_loaded = ROW_COUNT;

    INSERT INTO dw.etl_log(status, rows_loaded)
    VALUES ('SUCCESS', rows_loaded);

EXCEPTION WHEN OTHERS THEN
    INSERT INTO dw.etl_log(status, rows_loaded, error_message)
    VALUES ('FAIL', 0, SQLERRM);
END;
$$;
```

### 2. Procedure Execution

```sql
CALL dw.run_sales_etl();
```

### 3. ETL Log Output

```sql
SELECT * FROM dw.etl_log ORDER BY run_ts DESC;
```
```txt
SELECT * FROM dw.etl_log ORDER BY run_ts DESC;
           run_ts           | status | rows_loaded |              error_message
----------------------------+--------+-------------+-----------------------------------------
 2026-03-22 12:16:04.709079 | FAIL   |           0 | relation "dw.fact_sales" does not exist
(1 row)


Time: 3.977 ms
```

## Part 4: Analytical Queries

### Query 1: Monthly Revenue by Branch Region

```sql
SELECT 
    EXTRACT(MONTH FROM d.date) AS month,
    b.region,
    SUM(f.total_amount) AS revenue
FROM dw.fact_sales f
JOIN dw.dim_date d ON f.date_key = d.date_key
JOIN dw.dim_branch b ON f.branch_key = b.branch_key
GROUP BY EXTRACT(MONTH FROM d.date), b.region
ORDER BY month, b.region; 
```

Interpretation:

This query shows how much revenue each branch region generates each month. It helps management understand which regions perform better and track sales trends over time.

### Query 2: Top 5 Products by Total Revenue

```sql
SELECT 
    p.product_name,
    SUM(f.total_amount) AS revenue
FROM dw.fact_sales f
JOIN dw.dim_product p ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 5;
```

Interpretation:

This query identifies the five products that generate the most revenue. This insight helps the coffee chain prioritize popular items and manage inventory effectively.

### Query 3: Customer Region Contribution to Sales

```sql
SELECT 
    c.region_code,
    SUM(f.total_amount) AS revenue,
    ROUND(SUM(f.total_amount) / (SELECT SUM(total_amount) FROM dw.fact_sales) * 100, 2) AS pct_contribution
FROM dw.fact_sales f
JOIN dw.dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.region_code
ORDER BY revenue DESC;
```

Interpretation:

This query shows how much each customer region contributes to total sales, both in revenue and as a percentage. It helps the business identify which regions are most valuable and tailor marketing strategies.