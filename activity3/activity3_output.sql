-- Task 1 
create or replace function log_product_changes()
returns trigger as $$
begin
	if TG_OP = 'INSERT' then
	insert into products_audit
	(product_id, change_type, new_name, new_price)
	values 
	(NEW.product_id, 'INSERT', NEW.name, NEW.price);
	return new;
end if;

	if TG_OP = 'DELETE' then
	insert into products_audit
	(product_id, change_type, old_name, old_price)
	VALUES
	(OLD.product_id, 'DELETE', OLD.name, OLD.price);
	return old;
end if;

    if TG_OP = 'UPDATE' then
        if OLD.name IS DISTINCT FROM NEW.name
           OR OLD.price IS DISTINCT FROM NEW.price THEN

            insert into products_audit
            (product_id, change_type, old_name, new_name, old_price, new_price)
            values
            (NEW.product_id, 'UPDATE', OLD.name, NEW.name, OLD.price, NEW.price);
        end if;

        return new;
    end if;

    return null;
end;
$$ language plpgsql;

-- Task 2
create trigger product_audit_trigger
after insert or update or delete on products
for each row
execute function log_product_changes();

-- Task 3
-- 1. Test the INSERT trigger
INSERT INTO products (name, description, price, stock_quantity)
VALUES ('Miniature Thingamabob', 'A very small thingamabob.', 4.99, 500);

-- 2. Test the UPDATE trigger (with a meaningful change)
UPDATE products
SET price = 225.00, name = 'Mega Gadget v2'
WHERE name = 'Mega Gadget';

-- 3. Test an UPDATE with no meaningful change (should not create a log entry)
UPDATE products
SET description = 'An even simpler gizmo for all your daily tasks.'
WHERE name = 'Basic Gizmo';

-- 4. Test the DELETE trigger
DELETE FROM products
WHERE name = 'Super Widget';

-- Task 4
SELECT * FROM products_audit ORDER BY audit_id;