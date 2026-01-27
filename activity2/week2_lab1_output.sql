--Activity 1
CREATE OR REPLACE FUNCTION get_flight_duration(p_flight_id INT)
RETURNS INTERVAL AS $$
DECLARE
    v_duration INTERVAL;
BEGIN
    SELECT arrival_time - departure_time
    INTO v_duration
    FROM flights
    WHERE flight_id = p_flight_id;

    RETURN v_duration;
END;
$$ LANGUAGE plpgsql;

--Activity 2
CREATE OR REPLACE FUNCTION get_price_category(p_flight_id INT)
RETURNS TEXT AS $$
DECLARE
    v_price NUMERIC;
BEGIN
    SELECT base_price
    INTO v_price
    FROM flights
    WHERE flight_id = p_flight_id;

    IF v_price < 300 THEN
        RETURN 'Budget';
    ELSIF v_price BETWEEN 300 AND 800 THEN
        RETURN 'Standard';
    ELSE
        RETURN 'Premium';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Activity 3
CREATE OR REPLACE PROCEDURE book_flight(
    p_passenger_id INT,
    p_flight_id INT,
    p_seat_number VARCHAR
) AS $$
DECLARE
BEGIN
    INSERT INTO bookings (
        flight_id,
        passenger_id,
        booking_date,
        seat_number,
        status
    )
    VALUES (
        p_flight_id,
        p_passenger_id,
        CURRENT_DATE,
        p_seat_number,
        'Confirmed'
    );
END;
$$ LANGUAGE plpgsql;

-- Activity 4
CREATE OR REPLACE PROCEDURE increase_prices_for_airline(
    p_airline_id INT,
    p_percentage_increase NUMERIC
) AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT flight_id, base_price
        FROM flights
        WHERE airline_id = p_airline_id
    LOOP
        UPDATE flights
        SET base_price = rec.base_price * (1 + p_percentage_increase / 100)
        WHERE flight_id = rec.flight_id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;