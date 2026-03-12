
-- 1. Retrieve customers who ordered all available products.

SELECT c.customer_id, c.name
FROM Customers c
JOIN Orders o ON c.customer_id=o.customer_id
JOIN Order_Items oi ON o.order_id=oi.order_id
GROUP BY c.customer_id,c.name
HAVING COUNT(DISTINCT oi.product_id) =
(SELECT COUNT(*) FROM Products);

-- 2. List products that have never appeared in any order.

SELECT product_name
FROM Products
WHERE product_id NOT IN
(SELECT product_id FROM Order_Items

-- 3. Find orders that contain only one item, but that item is the most expensive product.

SELECT oi.order_id
FROM Order_Items oi
JOIN Products p ON oi.product_id=p.product_id
GROUP BY oi.order_id
HAVING COUNT(*)=1
AND MAX(p.price)=(SELECT MAX(price) FROM Products);


-- 4. Identify customers whose first-ever order has more than 3 items.

SELECT c.customer_id,c.name
FROM Customers c
JOIN Orders o ON c.customer_id=o.customer_id
JOIN Order_Items oi ON o.order_id=oi.order_id
WHERE o.order_date =
(SELECT MIN(order_date)
 FROM Orders
 WHERE customer_id=c.customer_id)
GROUP BY c.customer_id,c.name
HAVING COUNT(oi.order_item_id) >3;


-- 5. Find customers who placed orders but never made a payment.

SELECT DISTINCT c.customer_id,c.name
FROM Customers c
JOIN Orders o ON c.customer_id=o.customer_id
LEFT JOIN Payments p ON o.order_id=p.order_id
WHERE p.payment_id IS NULL;


-- 6. Retrieve orders that include both Mouse and Keyboard.

SELECT oi1.order_id
FROM Order_Items oi1
JOIN Products p1 ON oi1.product_id=p1.product_id
JOIN Order_Items oi2 ON oi1.order_id=oi2.order_id
JOIN Products p2 ON oi2.product_id=p2.product_id
WHERE p1.product_name='Mouse'
AND p2.product_name='Keyboard';


-- 7. For each customer, list the total amount ordered compared with their total payments.

SELECT c.customer_id,
SUM(oi.quantity*p.price) AS total_ordered,
SUM(pmt.amount) AS total_paid
FROM Customers c
JOIN Orders o ON c.customer_id=o.customer_id
JOIN Order_Items oi ON o.order_id=oi.order_id
JOIN Products p ON oi.product_id=p.product_id
LEFT JOIN Payments pmt ON o.order_id=pmt.order_id
GROUP BY c.customer_id;


-- 8. List orders where the payment amount is less than the order value.

SELECT o.order_id
FROM Orders o
JOIN Payments p ON o.order_id=p.order_id
JOIN Order_Items oi ON o.order_id=oi.order_id
JOIN Products pr ON oi.product_id=pr.product_id
GROUP BY o.order_id,p.amount
HAVING p.amount < SUM(oi.quantity*pr.price);


-- 9. Identify products that appear in orders but have zero inventory.

SELECT DISTINCT p.product_name
FROM Products p
JOIN Order_Items oi ON p.product_id=oi.product_id
JOIN Inventory i ON p.product_id=i.product_id
WHERE i.quantity_on_hand=0;


-- 10. Find all orders where every product in the order has quantity_on_hand <20.

SELECT oi.order_id
FROM Order_Items oi
JOIN Inventory i ON oi.product_id=i.product_id
GROUP BY oi.order_id
HAVING MAX(i.quantity_on_hand) <20;


-- 11. List customers who ordered a product before its inventory was last updated.

SELECT DISTINCT c.customer_id,c.name
FROM Customers c
JOIN Orders o ON c.customer_id=o.customer_id
JOIN Order_Items oi ON o.order_id=oi.order_id
JOIN Inventory i ON oi.product_id=i.product_id
WHERE o.order_date < i.last_updated;


-- 12. Retrieve orders containing products from at least 3 different categories.

SELECT order_id
FROM Order_Items
GROUP BY order_id
HAVING COUNT(DISTINCT product_id)>=3;

-- 13. Find customers who placed orders in each month of a given year.

SELECT customer_id
FROM Orders
GROUP BY customer_id
HAVING COUNT(DISTINCT MONTH(order_date))=
(SELECT COUNT(DISTINCT MONTH(order_date)) FROM Orders);


-- 14. List orders where the highest-priced item is the only item ordered.

SELECT order_id
FROM Order_Items oi
JOIN Products p ON oi.product_id=p.product_id
GROUP BY order_id
HAVING COUNT(*)=1
AND MAX(p.price)=(SELECT MAX(price) FROM Products);


-- 15. Retrieve top 3 customers with the most distinct products ordered.

SELECT c.customer_id,c.name,
COUNT(DISTINCT oi.product_id) AS products
FROM Customers c
JOIN Orders o ON c.customer_id=o.customer_id
JOIN Order_Items oi ON o.order_id=oi.order_id
GROUP BY c.customer_id,c.name
ORDER BY products DESC
LIMIT 3;


-- 16. Identify payments made after 48 hours from order_date.

SELECT *
FROM Payments p
JOIN Orders o ON p.order_id=o.order_id
WHERE TIMESTAMPDIFF(HOUR,o.order_date,p.payment_date)>48;


-- 17. Find duplicate product purchases within the same order.

SELECT order_id,product_id,COUNT(*)
FROM Order_Items
GROUP BY order_id,product_id
HAVING COUNT(*)>1;

-- 18. List products ordered consistently in quantities >1

SELECT product_id
FROM Order_Items
GROUP BY product_id
HAVING MIN(quantity)>1;

-- 19. Find inventory not used in orders for over 90 days.

SELECT p.product_name
FROM Products p
JOIN Inventory i ON p.product_id=i.product_id
LEFT JOIN Order_Items oi ON p.product_id=oi.product_id
LEFT JOIN Orders o ON oi.order_id=o.order_id
GROUP BY p.product_id
HAVING MAX(o.order_date) < DATE_SUB(CURDATE(),INTERVAL 90 DAY)
OR MAX(o.order_date) IS NULL;

-- 20. Identify orders where payment_method is NULL.

SELECT order_id
FROM Payments
WHERE payment_method IS NULL;

-- 21. Using a CTE, compute total stock value for every product.

WITH stock_value AS (
SELECT p.product_id,
p.product_name,
p.price*i.quantity_on_hand AS total_value
FROM Products p
JOIN Inventory i ON p.product_id=i.product_id
)
SELECT * FROM stock_value;

-- 22. Build a CTE to calculate monthly sales and find above-average months.

WITH monthly_sales AS (
SELECT MONTH(o.order_date) m,
SUM(oi.quantity*p.price) sales
FROM Orders o
JOIN Order_Items oi ON o.order_id=oi.order_id
JOIN Products p ON oi.product_id=p.product_id
GROUP BY m
)
SELECT *
FROM monthly_sales
WHERE sales > (SELECT AVG(sales) FROM monthly_sales);

-- 23. Generate calendar dates using recursive CTE and join with orders.

WITH RECURSIVE dates AS (
SELECT MIN(order_date) d FROM Orders
UNION ALL
SELECT DATE_ADD(d,INTERVAL 1 DAY)
FROM dates
WHERE d < (SELECT MAX(order_date) FROM Orders)
)
SELECT d,COUNT(o.order_id)
FROM dates
LEFT JOIN Orders o ON d=o.order_date
GROUP BY d;

-- 24. Categorize products into price tiers using CTE.

WITH tiers AS(
SELECT product_name,
CASE
WHEN price<1000 THEN 'LOW'
WHEN price<5000 THEN 'MEDIUM'
ELSE 'HIGH'
END AS tier
FROM Products
)
SELECT * FROM tiers;

-- 25. Using CTEs, create a customer purchase summary.

WITH summary AS(
SELECT c.customer_id,
SUM(oi.quantity*p.price) total_spent
FROM Customers c
JOIN Orders o ON c.customer_id=o.customer_id
JOIN Order_Items oi ON o.order_id=oi.order_id
JOIN Products p ON oi.product_id=p.product_id
GROUP BY c.customer_id
)
SELECT * FROM summary;


-- 26. Identify top 1% customers by spending using CTE.

WITH spending AS(
SELECT c.customer_id,
SUM(oi.quantity*p.price) total
FROM Customers c
JOIN Orders o ON c.customer_id=o.customer_id
JOIN Order_Items oi ON o.order_id=oi.order_id
JOIN Products p ON oi.product_id=p.product_id
GROUP BY c.customer_id
)
SELECT *
FROM spending
ORDER BY total DESC
LIMIT 1;

-- 27. Find products with declining monthly order quantities.

SELECT product_id,
MONTH(order_date) m,
SUM(quantity) qty
FROM Orders o
JOIN Order_Items oi ON o.order_id=oi.order_id
GROUP BY product_id,m;


-- 28. Find inventory gaps using CTE to compare ordered vs on-hand quantities.

WITH ordered AS(
SELECT product_id,SUM(quantity) total_ordered
FROM Order_Items
GROUP BY product_id
)
SELECT p.product_name,
o.total_ordered,
i.quantity_on_hand
FROM ordered o
JOIN Products p ON o.product_id=p.product_id
JOIN Inventory i ON o.product_id=i.product_id;

-- 29. Compute running total of payments per customer using CTE.

SELECT c.customer_id,
p.payment_date,
SUM(p.amount) OVER(
PARTITION BY c.customer_id
ORDER BY p.payment_date
) AS running_total
FROM Customers c
JOIN Orders o ON c.customer_id=o.customer_id
JOIN Payments p ON o.order_id=p.order_id;

-- 30. Identify products that go out of stock after orders.

SELECT p.product_name,
i.quantity_on_hand,
SUM(oi.quantity) ordered
FROM Products p
JOIN Inventory i ON p.product_id=i.product_id
JOIN Order_Items oi ON p.product_id=oi.product_id
GROUP BY p.product_name,i.quantity_on_hand
HAVING SUM(oi.quantity) >= i.quantity_on_hand;



-- 31. Flag orders without payments using CTE.

WITH OrderPayments AS (
    SELECT o.order_id, p.payment_id
    FROM Orders o
    LEFT JOIN Payments p ON o.order_id = p.order_id
)
SELECT order_id
FROM OrderPayments
WHERE payment_id IS NULL;


-- 32. Compute average fulfillment time using CTE.

WITH Fulfillment AS (
    SELECT o.order_id,
           DATEDIFF(p.payment_date, o.order_date) AS fulfillment_days
    FROM Orders o
    JOIN Payments p ON o.order_id = p.order_id
)
SELECT AVG(fulfillment_days) AS avg_fulfillment_time
FROM Fulfillment;


-- 33. Track duplicate ordered products using CTE.

WITH ProductOrders AS (
    SELECT product_id, COUNT(*) AS order_count
    FROM Order_Items
    GROUP BY product_id
)
SELECT *
FROM ProductOrders
WHERE order_count > 1;


-- 34. Bucket products into 5 equal price groups via CTE.

WITH PriceBuckets AS (
    SELECT product_id, product_name, price,
           NTILE(5) OVER (ORDER BY price) AS price_bucket
    FROM Products
)
SELECT *
FROM PriceBuckets;


-- 35. Find orders that exceed twice the customer’s average order size.

WITH OrderValues AS (
    SELECT o.order_id, o.customer_id,
           SUM(p.price * oi.quantity) AS order_value
    FROM Orders o
    JOIN Order_Items oi ON o.order_id = oi.order_id
    JOIN Products p ON oi.product_id = p.product_id
    GROUP BY o.order_id, o.customer_id
),
CustomerAvg AS (
    SELECT customer_id, AVG(order_value) AS avg_value
    FROM OrderValues
    GROUP BY customer_id
)
SELECT o.*
FROM OrderValues o
JOIN CustomerAvg c
ON o.customer_id = c.customer_id
WHERE o.order_value > 2 * c.avg_value;


-- 36. Bucket products into 10 price bands and count orders.

WITH PriceBand AS (
    SELECT product_id,
           NTILE(10) OVER (ORDER BY price) AS price_band
    FROM Products
)
SELECT pb.price_band, COUNT(oi.order_id) AS order_count
FROM PriceBand pb
LEFT JOIN Order_Items oi
ON pb.product_id = oi.product_id
GROUP BY pb.price_band;


-- 37. Group customers into spending buckets.

WITH CustomerSpending AS (
    SELECT o.customer_id,
           SUM(p.price * oi.quantity) AS total_spent
    FROM Orders o
    JOIN Order_Items oi ON o.order_id = oi.order_id
    JOIN Products p ON oi.product_id = p.product_id
    GROUP BY o.customer_id
)
SELECT customer_id,
       CASE
           WHEN total_spent < 5000 THEN 'Low'
           WHEN total_spent < 20000 THEN 'Medium'
           ELSE 'High'
       END AS spending_bucket
FROM CustomerSpending;


-- 38. Bucket orders into size categories.

SELECT order_id,
       SUM(quantity) AS total_items,
       CASE
           WHEN SUM(quantity) <= 2 THEN 'Small'
           WHEN SUM(quantity) <= 5 THEN 'Medium'
           ELSE 'Large'
       END AS order_size
FROM Order_Items
GROUP BY order_id;


-- 39. Categorize payments based on amount buckets.

SELECT payment_id, amount,
       CASE
           WHEN amount < 5000 THEN 'Low Payment'
           WHEN amount < 20000 THEN 'Medium Payment'
           ELSE 'High Payment'
       END AS payment_bucket
FROM Payments;


-- 40. Bucket products by inventory age.

SELECT product_id,
       CASE
           WHEN DATEDIFF(CURDATE(), last_updated) < 30 THEN 'Recent'
           WHEN DATEDIFF(CURDATE(), last_updated) < 90 THEN 'Moderate'
           ELSE 'Old'
       END AS inventory_age
FROM Inventory;


-- 41. Create weekly sales buckets.

SELECT YEAR(order_date) AS year,
       WEEK(order_date) AS week,
       COUNT(*) AS total_orders
FROM Orders
GROUP BY YEAR(order_date), WEEK(order_date);


-- 42. Bucket customers by order-value distribution.

WITH OrderValues AS (
    SELECT o.customer_id,
           SUM(p.price * oi.quantity) AS total_value
    FROM Orders o
    JOIN Order_Items oi ON o.order_id = oi.order_id
    JOIN Products p ON oi.product_id = p.product_id
    GROUP BY o.customer_id
)
SELECT customer_id,
       NTILE(4) OVER (ORDER BY total_value) AS spending_quartile
FROM OrderValues;


-- 43. Categorize products by sales frequency.

SELECT product_id,
       COUNT(*) AS times_sold,
       CASE
           WHEN COUNT(*) < 3 THEN 'Low'
           WHEN COUNT(*) < 10 THEN 'Medium'
           ELSE 'High'
       END AS sales_category
FROM Order_Items
GROUP BY product_id;


-- 44. Bucket customers by average order gap.

WITH OrderGaps AS (
    SELECT 
        customer_id,
        DATEDIFF(
            order_date,
            LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)
        ) AS gap_days
    FROM Orders
),
AvgGap AS (
    SELECT 
        customer_id,
        AVG(gap_days) AS avg_gap
    FROM OrderGaps
    WHERE gap_days IS NOT NULL
    GROUP BY customer_id
)
SELECT 
    customer_id,
    CASE
        WHEN avg_gap < 10 THEN 'Frequent'
        WHEN avg_gap < 30 THEN 'Regular'
        ELSE 'Rare'
    END AS customer_type
FROM AvgGap;


-- 45. Rank customers by total ordered amount; return top 5 per email domain.

WITH Spending AS (
    SELECT c.customer_id,
           SUBSTRING_INDEX(c.email,'@',-1) AS domain,
           SUM(p.price*oi.quantity) AS total_spent
    FROM Customers c
    JOIN Orders o ON c.customer_id=o.customer_id
    JOIN Order_Items oi ON o.order_id=oi.order_id
    JOIN Products p ON oi.product_id=p.product_id
    GROUP BY c.customer_id,domain
),
Ranked AS (
    SELECT *,
           RANK() OVER(PARTITION BY domain ORDER BY total_spent DESC) AS rnk
    FROM Spending
)
SELECT *
FROM Ranked
WHERE rnk<=5;


-- 46. Compute running total of sales per customer.

SELECT o.customer_id,
       o.order_id,
       SUM(p.price*oi.quantity)
       OVER(PARTITION BY o.customer_id ORDER BY o.order_date) AS running_total
FROM Orders o
JOIN Order_Items oi ON o.order_id=oi.order_id
JOIN Products p ON oi.product_id=p.product_id;

-- 47. Find first and last orders using window functions.

SELECT customer_id,
       FIRST_VALUE(order_id) OVER(PARTITION BY customer_id ORDER BY order_date) AS first_order,
       LAST_VALUE(order_id) OVER(
           PARTITION BY customer_id ORDER BY order_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
       ) AS last_order
FROM Orders;


-- 48. Calculate days between customer orders using LAG.

SELECT customer_id,
       order_id,
       order_date,
       DATEDIFF(order_date,
                LAG(order_date) OVER(PARTITION BY customer_id ORDER BY order_date)) AS days_between
FROM Orders;


-- 49. Identify top-selling product per month using RANK.

WITH MonthlySales AS (
    SELECT MONTH(o.order_date) AS month,
           oi.product_id,
           SUM(oi.quantity) AS total_qty
    FROM Orders o
    JOIN Order_Items oi ON o.order_id=oi.order_id
    GROUP BY month, oi.product_id
)
SELECT *
FROM (
    SELECT *,
           RANK() OVER(PARTITION BY month ORDER BY total_qty DESC) rnk
    FROM MonthlySales
) t
WHERE rnk=1;


-- 50. Compute moving average of product quantities.

SELECT product_id,
       order_id,
       AVG(quantity) OVER(
           PARTITION BY product_id
           ORDER BY order_id
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ) AS moving_avg
FROM Order_Items;


-- 51. Detect customers who stopped purchasing for 60 days via LEAD.

SELECT *
FROM (
    SELECT customer_id, order_date,
           LEAD(order_date) OVER(PARTITION BY customer_id ORDER BY order_date) AS next_order,
           DATEDIFF(
               LEAD(order_date) OVER(PARTITION BY customer_id ORDER BY order_date),
               order_date
           ) AS gap
    FROM Orders
) t
WHERE gap > 60;


-- 52. Calculate percentage contribution of each item to order total.

WITH OrderValue AS (
    SELECT o.order_id,
           oi.product_id,
           p.price*oi.quantity AS item_value,
           SUM(p.price*oi.quantity) OVER(PARTITION BY o.order_id) AS order_total
    FROM Orders o
    JOIN Order_Items oi ON o.order_id=oi.order_id
    JOIN Products p ON oi.product_id=p.product_id
)
SELECT order_id, product_id,
       (item_value/order_total)*100 AS percent_contribution
FROM OrderValue;


-- 53. Dense-rank products by total quantity sold.

SELECT product_id,
       SUM(quantity) AS total_qty,
       DENSE_RANK() OVER(ORDER BY SUM(quantity) DESC) AS product_rank
FROM Order_Items
GROUP BY product_id;


-- 54. Compute cumulative payments per order and find unpaid ones.

SELECT order_id,
       SUM(amount) OVER(PARTITION BY order_id ORDER BY payment_date) AS cumulative_payment
FROM Payments;

SELECT o.order_id
FROM Orders o
LEFT JOIN Payments p ON o.order_id=p.order_id
WHERE p.payment_id IS NULL;

-- 55. Identify second most purchased product per customer using window functions.

WITH ProductCount AS (
    SELECT o.customer_id, oi.product_id,
           SUM(oi.quantity) qty
    FROM Orders o
    JOIN Order_Items oi ON o.order_id=oi.order_id
    GROUP BY o.customer_id, oi.product_id
),
Ranked AS (
    SELECT *,
           RANK() OVER(PARTITION BY customer_id ORDER BY qty DESC) rnk
    FROM ProductCount
)
SELECT *
FROM Ranked
WHERE rnk=2;


-- 56. Rank customers per product by quantity purchased.

SELECT oi.product_id,
       o.customer_id,
       SUM(oi.quantity) qty,
       RANK() OVER(PARTITION BY oi.product_id ORDER BY SUM(oi.quantity) DESC) rnk
FROM Orders o
JOIN Order_Items oi ON o.order_id=oi.order_id
GROUP BY oi.product_id, o.customer_id;


-- 57. Find orders above the 90th percentile in value.

WITH OrderValues AS (
    SELECT o.order_id,
           SUM(p.price*oi.quantity) AS order_value
    FROM Orders o
    JOIN Order_Items oi ON o.order_id=oi.order_id
    JOIN Products p ON oi.product_id=p.product_id
    GROUP BY o.order_id
)
SELECT *
FROM (
    SELECT *,
           PERCENT_RANK() OVER(ORDER BY order_value) AS pct_rank
    FROM OrderValues
) t
WHERE pct_rank >= 0.9;


-- 58. Split customers into quartiles quartiles based on spending.

WITH Spending AS (
    SELECT o.customer_id,
           SUM(p.price*oi.quantity) total_spent
    FROM Orders o
    JOIN Order_Items oi ON o.order_id=oi.order_id
    JOIN Products p ON oi.product_id=p.product_id
    GROUP BY o.customer_id
)
SELECT customer_id,
       NTILE(4) OVER(ORDER BY total_spent DESC) AS spending_quartile
FROM Spending;
