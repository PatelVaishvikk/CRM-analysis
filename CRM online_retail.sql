CREATE TABLE online_retail(
	Invoice varchar(20),
	StockCode varchar(20),
	Description text,
	Quantity INT,
	InvoiceDate TIMESTAMP,
	Price DECIMAL(10,2),
	CustomerID INT,
	Country varchar(50)
);

copy online_retail(Invoice,StockCode,Description,Quantity,InvoiceDate,Price,CustomerID,Country)
from 'C:/Drive(D)/CRM online_retail/online_retail_cleaned.csv'
delimiter ','
header csv 


select * from online_retail

DELETE FROM online_retail WHERE CustomerID IS NULL;

DELETE FROM online_retail;


CREATE INDEX idx_invoice ON online_retail(Invoice);
CREATE INDEX idx_customer ON online_retail(CustomerID);
CREATE INDEX idx_date ON online_retail(InvoiceDate);

--  TOTAL SPENDING BY EACH CUSTOMER

SELECT CustomerID, SUM(quantity * price) as MonetaryValue 
FROM online_retail
GROUP BY CustomerID
ORDER BY MonetaryValue DESC
LIMIT 10



UPDATE online_retail
SET InvoiceDate = make_timestamp(
    EXTRACT(YEAR FROM CURRENT_DATE)::int - 1,
    EXTRACT(MONTH FROM InvoiceDate)::int,
    EXTRACT(DAY FROM InvoiceDate)::int,
    EXTRACT(HOUR FROM InvoiceDate)::int,
    EXTRACT(MINUTE FROM InvoiceDate)::int,
    EXTRACT(SECOND FROM InvoiceDate)::int
);


	
--CRM ANALYSIS

-- 1️⃣ RFM Analysis (Customer Segmentation)

WITH rfm AS (
	SELECT
		CustomerID,
		MAX(InvoiceDate) AS LastPurchaseDate,
		COUNT(DISTINCT Invoice) AS Frequency,
		SUM(quantity * price) as MonetaryValue 
	FROM online_retail
	GROUP BY CustomerID
)

SELECT 
	CustomerID,
	DATE_PART('day', CURRENT_TIMESTAMP - LastPurchaseDate) AS Recency,
	Frequency,
	MonetaryValue
FROM rfm
ORDER BY Recency ASC;


-- 2️⃣ Top 10 Highest-Spending Customers

SELECT 
	CustomerID,
	SUM(quantity * price) AS TotalSpent
FROM online_retail
GROUP BY CustomerID
ORDER BY TotalSpent DESC
LIMIT 10;


-- 3️⃣ Customer Retention Rate

WITH RepeatCustomers AS (
    SELECT 
        CustomerID,
        COUNT(DISTINCT Invoice) AS TotalPurchases
    FROM online_retail
    GROUP BY CustomerID
)
SELECT 
    ROUND(COUNT(CASE WHEN TotalPurchases > 1 THEN CustomerID END) * 100.0 / COUNT(*),2) AS RetentionRate
FROM RepeatCustomers;



-- 4️⃣ Customer Lifetime Value (LTV)

-- FOR LTV NEED TO FIND Calculate Customer Lifespan in Years

WITH customer_lifespan AS (
    SELECT 
        CustomerID,
        MIN(InvoiceDate) AS FirstPurchaseDate,
        MAX(InvoiceDate) AS LastPurchaseDate,
        ROUND(EXTRACT(EPOCH FROM (MAX(InvoiceDate) - MIN(InvoiceDate))) / (365.25 * 86400), 2) AS CustomerLifespanYears
    FROM online_retail
    GROUP BY CustomerID
),

customer_revenue AS (
    SELECT 
        CustomerID,
        COUNT(DISTINCT Invoice) AS TotalPurchases,
        ROUND(SUM(quantity * price),2) AS TotalRevenue,
        ROUND(AVG(quantity * price),2) AS AvgOrderValue
    FROM online_retail
    GROUP BY CustomerID
    HAVING COUNT(DISTINCT Invoice) > 5  
)

SELECT 
    cr.CustomerID,
    cr.TotalPurchases,
    cr.TotalRevenue,
    cr.AvgOrderValue,
    cl.CustomerLifespanYears,
    ROUND((cr.AvgOrderValue * cr.TotalPurchases * cl.CustomerLifespanYears), 2) AS LTV
FROM customer_revenue cr
JOIN customer_lifespan cl ON cr.CustomerID = cl.CustomerID
ORDER BY LTV DESC
LIMIT 10;

--🙂 5.Customer Churn Rate (Lost Customers)

WITH last_purchase AS (
    SELECT 
        CustomerID,
        MAX(InvoiceDate) AS LastPurchaseDate
    FROM online_retail
    GROUP BY CustomerID
)
SELECT 
    ROUND(
        COUNT(CASE WHEN EXTRACT(DAY FROM (CURRENT_TIMESTAMP - LastPurchaseDate)) > 180 THEN CustomerID END) * 100.0 / COUNT(*), 2
    ) AS ChurnRate 
FROM last_purchase;

-- 22.75% of customers have not made a purchase in the last 180 days.

-- 🔹 This means customer retention is strong, and only 22.75% of customers have stopped purchasing.

-- 📈 How to Reduce Churn Rate?
-- 1️⃣ Re-engagement Campaigns

-- Send emails with exclusive discounts to inactive customers.
-- Example: “We Miss You! Get 10% Off on Your Next Order.”
-- 2️⃣ Loyalty Programs

-- Offer points, cashback, or exclusive perks to keep customers engaged.
-- 3️⃣ Customer Feedback

-- Ask churned customers why they stopped purchasing and improve based on feedback.
-- 4️⃣ Personalized Recommendations

-- Use past purchase history to suggest relevant products.

-- 🙂 Average Revenue Per User (ARPU)

SELECT 
    ROUND(SUM(quantity * price) / COUNT(DISTINCT CustomerID), 2) AS ARPU
FROM online_retail;

-- 🙂 Repeat Purchase Rate (Customer Loyalty)

WITH purchase_counts AS (
	SELECT 
		CustomerID,
		COUNT(DISTINCT Invoice) AS PurchaseCount
	FROM online_retail
	GROUP BY CustomerID
)

SELECT 
	ROUND(COUNT(CASE WHEN PurchaseCount > 1 THEN CustomerID END) * 100 / COUNT(*),2) AS RepeatPurchaseRate
FROM purchase_counts;



