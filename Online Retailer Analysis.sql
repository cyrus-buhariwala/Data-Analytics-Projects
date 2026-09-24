/*
This project analyzes a retail store’s sales, customers, and product performance using SQL.
It demonstrates real‑world data analyst skills:

Data modeling
Data cleaning
Exploratory SQL analysis
Business KPI calculation
Customer segmentation
Insight generation

Here is a breakdown of the schemas:

customers
| customer_id | first_name | last_name | city | state | signup_date |

orders
| order_id | customer_id | order_date | order_status |

order_items
| order_item_id | order_id | product_id | quantity | price |

products
| product_id | product_name | category | unit_cost |
*/

--Let's model the data by creating the relevant tables.

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    signup_date DATE
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    unit_cost DECIMAL(10,2)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    order_status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    price DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

--Let's clean the data.

-- Removing cancelled orders:
DELETE FROM orders
WHERE order_status = 'cancelled';

-- Fixing negative quantities:
UPDATE order_items
SET quantity = ABS(quantity)
WHERE quantity < 0;

-- Removing duplicate customers
DELETE FROM customers c
WHERE c.customer_id IN (
    SELECT customer_id
    FROM (
        SELECT customer_id,
               ROW_NUMBER() OVER (PARTITION BY first_name, last_name ORDER BY signup_date) AS rn
        FROM customers
    ) t
    WHERE rn > 1
);

--Let's explore the data in more depth (EDA):

-- Total number of customers:
SELECT COUNT(*) AS total_customers FROM customers;

-- Total orders:
SELECT COUNT(*) AS total_orders FROM orders;

-- Top 10 cities by customer count:
SELECT city, COUNT(*) AS num_customers
FROM customers
GROUP BY city
ORDER BY num_customers DESC
LIMIT 10;

--Let's generate the KPIs:

-- Total revenue:
SELECT SUM(quantity * price) AS total_revenue
FROM order_items;

-- Average order value (AOV):
SELECT AVG(order_total) AS avg_order_value
FROM (
    SELECT order_id, SUM(quantity * price) AS order_total
    FROM order_items
    GROUP BY order_id
) t;

-- Revenue by category:
SELECT p.category, SUM(oi.quantity * oi.price) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;

--Let's segment the customer data using RFM Segmentation (Recency, Frequency, Monetary):

-- Monetary value per customer:
WITH monetary AS (
    SELECT o.customer_id,
           SUM(oi.quantity * oi.price) AS total_spent
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),

-- Frequency:
frequency AS (
    SELECT customer_id,
           COUNT(*) AS num_orders
    FROM orders
    GROUP BY customer_id
),

-- Recency:
recency AS (
    SELECT customer_id,
           CURRENT_DATE - MAX(order_date) AS days_since_last_order
    FROM orders
    GROUP BY customer_id
)

SELECT c.customer_id,
       c.first_name,
       c.last_name,
       r.days_since_last_order,
       f.num_orders,
       m.total_spent
FROM customers c
JOIN recency r ON c.customer_id = r.customer_id
JOIN frequency f ON c.customer_id = f.customer_id
JOIN monetary m ON c.customer_id = m.customer_id
ORDER BY m.total_spent DESC;

--Let's provide insight on the best performing products and categories and the customers generating the most revenue:

-- Top 5 best-selling products:
SELECT p.product_name, SUM(oi.quantity) AS units_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY units_sold DESC
LIMIT 5;

-- Top customers by revenue:
SELECT c.first_name, c.last_name, SUM(oi.quantity * oi.price) AS revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id
ORDER BY revenue DESC
LIMIT 10;

-- Category performance:
SELECT category,
       SUM(quantity * price) AS revenue,
       AVG(price) AS avg_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY category
ORDER BY revenue DESC;
