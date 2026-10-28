CREATE TABLE coffee_shop_sales (
    transaction_id INTEGER PRIMARY KEY,
    transaction_date DATE,
    transaction_time TIME,
    transaction_qty INTEGER,
    store_id INTEGER,
    store_location VARCHAR(100),
    product_id INTEGER,
    unit_price NUMERIC(10, 2),
    product_category VARCHAR(100),
    product_type VARCHAR(100),
    product_detail VARCHAR(100)
);

select * from coffee_shop_sales


SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'coffee_shop_sales';

UPDATE coffee_shop_sales
SET transaction_date = transaction_date::date;

--TOTAL SALES
select sum(unit_price * transaction_qty) as TOTAL_SALES
FROM coffee_shop_sales

--EACH MONTH SALES
select ROUND(sum(unit_price * transaction_qty),1) as TOTAL_SALES
FROM coffee_shop_sales
WHERE EXTRACT(MONTH FROM transaction_date) = 5;--may month

--MONTH ON MONTH GROWTH AND MONTH ON MONTH DIFFERENCE
SELECT
    EXTRACT(MONTH FROM transaction_date) AS month,
    ROUND(SUM(unit_price * transaction_qty)) AS total_sales,
    ROUND(
        (
            SUM(unit_price * transaction_qty)
            - LAG(SUM(unit_price * transaction_qty)) OVER (
                ORDER BY EXTRACT(MONTH FROM transaction_date)
            )
        ) * 100.0
        / NULLIF(
            LAG(SUM(unit_price * transaction_qty)) OVER (
                ORDER BY EXTRACT(MONTH FROM transaction_date)
            ),
            0
        ),
        2
    ) AS mom_increase_percentage
FROM coffee_shop_sales
WHERE EXTRACT(MONTH FROM transaction_date) IN (4, 5)
GROUP BY EXTRACT(MONTH FROM transaction_date)
ORDER BY EXTRACT(MONTH FROM transaction_date);


--TOTAL ORDERS
SELECT COUNT(transaction_id) as Total_Orders
FROM coffee_shop_sales 
WHERE EXTRACT (MONTH FROM transaction_date)= 5 -- for month of (CM-May)


--TOTAL ORDERS MON DIFFERENCE AND MOM GROWTH
SELECT 
    EXTRACT(MONTH FROM transaction_date) AS month,
    ROUND(COUNT(transaction_id)) AS total_orders,
    (COUNT(transaction_id)::NUMERIC - LAG(COUNT(transaction_id), 1) 
    OVER (ORDER BY EXTRACT(MONTH FROM transaction_date))) 
    / LAG(COUNT(transaction_id), 1) 
    OVER (ORDER BY EXTRACT(MONTH FROM transaction_date)) * 100 AS mom_increase_percentage
FROM 
    coffee_shop_sales
WHERE 
    EXTRACT(MONTH FROM transaction_date) IN (4, 5) -- for April and May
GROUP BY 
    EXTRACT(MONTH FROM transaction_date)
ORDER BY 
    MONTH;

---TOTAL QUANTITY SOLD
SELECT SUM(transaction_qty) as Total_Quantity_Sold
FROM coffee_shop_sales 
WHERE EXTRACT (MONTH FROM transaction_date) = 5 -- May

--TOTAL QUANTITY SOLD  - MOM DIFFERENCE AND MOM GROWTH

WITH monthly_sales AS (
    SELECT 
        EXTRACT(MONTH FROM transaction_date) AS month,
        SUM(transaction_qty) AS total_quantity_sold
    FROM 
        coffee_shop_sales
    WHERE 
        EXTRACT(MONTH FROM transaction_date) IN (4, 5)
    GROUP BY 
        EXTRACT(MONTH FROM transaction_date)
)
SELECT 
    month,
    ROUND(total_quantity_sold) AS total_quantity_sold,
    (total_quantity_sold - LAG(total_quantity_sold, 1) OVER (ORDER BY month)) * 100.0 
    / LAG(total_quantity_sold, 1) OVER (ORDER BY month) AS mom_increase_percentage
FROM 
    monthly_sales
ORDER BY 
    month;

----CALENDAR TABLE – DAILY SALES, QUANTITY and TOTAL ORDERS

SELECT
    SUM(unit_price * transaction_qty) AS total_sales,
    SUM(transaction_qty) AS total_quantity_sold,
    COUNT(transaction_id) AS total_orders
FROM 
    coffee_shop_sales
WHERE 
    transaction_date = '2023-05-18'; --For 18 May 2023

----SALES TREND OVER PERIOD
SELECT AVG(total_sales) AS average_sales
FROM (
    SELECT 
        SUM(unit_price * transaction_qty) AS total_sales
    FROM 
        coffee_shop_sales
	WHERE 
       EXTRACT (MONTH FROM transaction_date) = 5  -- Filter for May
    GROUP BY 
        transaction_date
) AS internal_query;

----DAILY SALES FOR MONTH SELECTED

SELECT 
    EXTRACT(DAY FROM transaction_date) AS day_of_month,
    ROUND(SUM(unit_price * transaction_qty)::NUMERIC, 1) AS total_sales
FROM 
    coffee_shop_sales
WHERE 
    EXTRACT(MONTH FROM transaction_date) = 5  -- Filter for May
GROUP BY 
    EXTRACT(DAY FROM transaction_date)
ORDER BY 
    day_of_month;

----COMPARING DAILY SALES WITH AVERAGE SALES – IF GREATER THAN “ABOVE AVERAGE” and LESSER THAN “BELOW AVERAGE”
SELECT 
    day_of_month,
    CASE 
        WHEN total_sales > avg_sales THEN 'Above Average'
        WHEN total_sales < avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_status,
    total_sales
FROM (
    SELECT 
        EXTRACT(DAY FROM transaction_date) AS day_of_month,
        SUM(unit_price * transaction_qty) AS total_sales,
        AVG(SUM(unit_price * transaction_qty)) OVER () AS avg_sales
    FROM 
        coffee_shop_sales
    WHERE 
        EXTRACT(MONTH FROM transaction_date) = 5  -- Filter for May
    GROUP BY 
        EXTRACT(DAY FROM transaction_date)
) AS sales_data
ORDER BY 
    day_of_month;

---SALES BY WEEKDAY / WEEKEND:
SELECT 
    CASE 
        WHEN EXTRACT(ISODOW FROM transaction_date) IN (6, 7) THEN 'Weekends'
        ELSE 'Weekdays'
    END AS day_type,
    ROUND(SUM(unit_price * transaction_qty)::NUMERIC, 2) AS total_sales
FROM 
    coffee_shop_sales
WHERE 
    EXTRACT(MONTH FROM transaction_date) = 5  -- Filter for May
GROUP BY 
    CASE 
        WHEN EXTRACT(ISODOW FROM transaction_date) IN (6, 7) THEN 'Weekends'
        ELSE 'Weekdays'
    END;

----SALES BY STORE LOCATION
SELECT 
    store_location,
    SUM(unit_price * transaction_qty) AS total_sales
FROM 
    coffee_shop_sales
WHERE 
    EXTRACT(MONTH FROM transaction_date) = 5 
GROUP BY 
    store_location
ORDER BY 
    SUM(unit_price * transaction_qty) DESC;


---SALES BY PRODUCT CATEGORY
SELECT 
    product_category,
    ROUND(SUM(unit_price * transaction_qty)::NUMERIC, 1) AS total_sales
FROM 
    coffee_shop_sales
WHERE 
    EXTRACT(MONTH FROM transaction_date) = 5 
GROUP BY 
    product_category
ORDER BY 
    SUM(unit_price * transaction_qty) DESC;

----SALES BY PRODUCTS (TOP 10)
SELECT 
    product_type,
    ROUND(SUM(unit_price * transaction_qty)::NUMERIC, 1) AS total_sales
FROM 
    coffee_shop_sales
WHERE 
    EXTRACT(MONTH FROM transaction_date) = 5 
GROUP BY 
    product_type
ORDER BY 
    SUM(unit_price * transaction_qty) DESC
LIMIT 10;


---SALES BY DAY | HOUR
SELECT 
    ROUND(SUM(unit_price * transaction_qty)::NUMERIC) AS total_sales,
    SUM(transaction_qty) AS total_quantity,
    COUNT(*) AS total_orders
FROM 
    coffee_shop_sales
WHERE 
    EXTRACT(ISODOW FROM transaction_date) = 2 -- Filter for Tuesday 
    AND EXTRACT(HOUR FROM transaction_time) = 8 -- Filter for hour number 8
    AND EXTRACT(MONTH FROM transaction_date) = 5; -- Filter for May (month number 5)

---TO GET SALES FOR ALL HOURS FOR MONTH OF MAY
SELECT 
    EXTRACT(HOUR FROM transaction_time) AS hour_of_day,
    ROUND(SUM(unit_price * transaction_qty)::NUMERIC) AS total_sales
FROM 
    coffee_shop_sales
WHERE 
    EXTRACT(MONTH FROM transaction_date) = 5 -- Filter for May (month number 5)
GROUP BY 
    EXTRACT(HOUR FROM transaction_time)
ORDER BY 
    hour_of_day;

----TO GET SALES FROM MONDAY TO SUNDAY FOR MONTH OF MAY

SELECT 
    CASE 
        WHEN EXTRACT(ISODOW FROM transaction_date) = 1 THEN 'Monday'
        WHEN EXTRACT(ISODOW FROM transaction_date) = 2 THEN 'Tuesday'
        WHEN EXTRACT(ISODOW FROM transaction_date) = 3 THEN 'Wednesday'
        WHEN EXTRACT(ISODOW FROM transaction_date) = 4 THEN 'Thursday'
        WHEN EXTRACT(ISODOW FROM transaction_date) = 5 THEN 'Friday'
        WHEN EXTRACT(ISODOW FROM transaction_date) = 6 THEN 'Saturday'
        ELSE 'Sunday'
    END AS day_of_week,
    ROUND(SUM(unit_price * transaction_qty)::NUMERIC) AS total_sales
FROM 
    coffee_shop_sales
WHERE 
    EXTRACT(MONTH FROM transaction_date) = 5 -- Filter for May (month number 5)
GROUP BY 
    CASE 
        WHEN EXTRACT(ISODOW FROM transaction_date) = 1 THEN 'Monday'
        WHEN EXTRACT(ISODOW FROM transaction_date) = 2 THEN 'Tuesday'
        WHEN EXTRACT(ISODOW FROM transaction_date) = 3 THEN 'Wednesday'
        WHEN EXTRACT(ISODOW FROM transaction_date) = 4 THEN 'Thursday'
        WHEN EXTRACT(ISODOW FROM transaction_date) = 5 THEN 'Friday'
        WHEN EXTRACT(ISODOW FROM transaction_date) = 6 THEN 'Saturday'
        ELSE 'Sunday'
    END;




