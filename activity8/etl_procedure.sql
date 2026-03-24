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