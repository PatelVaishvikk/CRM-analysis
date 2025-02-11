📊 Customer Relationship Management (CRM) Analysis
==================================================

📌 Overview
-----------

This project provides SQL-based CRM analytics using PostgreSQL. The dataset contains transactional data, including invoices, customer IDs, product details, and timestamps. Key metrics analyzed include Customer Lifetime Value (LTV), RFM segmentation, Customer Retention Rate, and Churn Rate.

🗂️ Table of Contents
---------------------

*   [1 Data Preparation]
*   [2 CRM Analysis]
    *   [2.1 Total Spending by Each Customer]
    *   [2.2 RFM Analysis]
    *   [2.3 Top 10 Highest-Spending Customers]
    *   [2.4 Customer Retention Rate]
    *   [2.5 Customer Lifetime Value (LTV)]
    *   [2.6 Customer Churn Rate]
    *   [2.7 Average Revenue Per User (ARPU)]
    *   [2.8 Repeat Purchase Rate]

* * *

1️⃣ Data Preparation
--------------------

### 📌 Create Table

    CREATE TABLE online_retail(
        Invoice VARCHAR(20),
        StockCode VARCHAR(20),
        Description TEXT,
        Quantity INT,
        InvoiceDate TIMESTAMP,
        Price DECIMAL(10,2),
        CustomerID INT,
        Country VARCHAR(50)
    );
    

### 📌 Load Data

    COPY online_retail(Invoice, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID, Country)
    FROM 'C:/Drive(D)/CRM_online_retail/online_retail_cleaned.csv'
    DELIMITER ','
    CSV HEADER;
    

### 📌 Data Cleaning

    DELETE FROM online_retail WHERE CustomerID IS NULL;
    DELETE FROM online_retail;
    

### 📌 Indexing for Faster Queries

    CREATE INDEX idx_invoice ON online_retail(Invoice);
    CREATE INDEX idx_customer ON online_retail(CustomerID);
    CREATE INDEX idx_date ON online_retail(InvoiceDate);
    

* * *

2️⃣ CRM Analysis
----------------

### **2.1 Total Spending by Each Customer**

    SELECT CustomerID, SUM(quantity * price) AS MonetaryValue
    FROM online_retail
    GROUP BY CustomerID;
    

### **2.2 RFM Analysis (Customer Segmentation)**

    WITH rfm AS (
        SELECT
            CustomerID,
            MAX(InvoiceDate) AS LastPurchaseDate,
            COUNT(DISTINCT Invoice) AS Frequency,
            SUM(quantity * price) AS MonetaryValue
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
    

### **2.3 Top 10 Highest-Spending Customers**

    SELECT
        CustomerID,
        SUM(quantity * price) AS TotalSpent
    FROM online_retail
    GROUP BY CustomerID
    ORDER BY TotalSpent DESC
    LIMIT 10;
    

### **2.4 Customer Retention Rate**

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
    

### **2.5 Customer Lifetime Value (LTV)**

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
    

### **2.6 Customer Churn Rate**

    WITH last_purchase AS (
        SELECT
            CustomerID,
            MAX(InvoiceDate) AS LastPurchaseDate
        FROM online_retail
        GROUP BY CustomerID
    )
    SELECT
        ROUND(
            COUNT(CASE WHEN EXTRACT(DAY FROM (CURRENT_TIMESTAMP - LastPurchaseDate)) > 180 THEN CustomerID END) * 100.0 / COUNT(CustomerID), 2
        ) AS ChurnRate
    FROM last_purchase;
    

### **2.7 Average Revenue Per User (ARPU)**

    SELECT
        ROUND(SUM(quantity * price) / COUNT(DISTINCT CustomerID), 2) AS ARPU
    FROM online_retail;
    

### **2.8 Repeat Purchase Rate (Customer Loyalty)**

    WITH purchase_counts AS (
        SELECT
            CustomerID,
            COUNT(DISTINCT Invoice) AS PurchaseCount
        FROM online_retail
        GROUP BY CustomerID
    )
    SELECT
        ROUND(
            COUNT(CASE WHEN PurchaseCount > 1 THEN CustomerID END) * 100.0 / COUNT(DISTINCT CustomerID), 2
        ) AS RepeatPurchaseRate
    FROM purchase_counts;