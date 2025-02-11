📊 Customer Relationship Management (CRM) Analysis
==================================================

![CRM Analysis](images/animation.gif)


📌 Overview
-----------

This project provides SQL-based CRM analytics using PostgreSQL. The dataset contains transactional data, including invoices, customer IDs, product details, and timestamps. Key metrics analyzed include Customer Lifetime Value (LTV), RFM segmentation, Customer Retention Rate, and Churn Rate.


## 🗂️ Table of Contents
- [📌 Overview](#-overview)
- [🗂️ Table of Contents](#-table-of-contents)
- [1️⃣ Data Preparation](#1️⃣-data-preparation)
  - [📌 Create Table](#-create-table)
  - [📌 Load Data](#-load-data)
  - [📌 Data Cleaning](#-data-cleaning)
  - [📌 Indexing for Faster Queries](#-indexing-for-faster-queries)
- [2️⃣ CRM Analysis](#2️⃣-crm-analysis)
  - [2.1 Total Spending by Each Customer](#21-total-spending-by-each-customer)
  - [2.2 RFM Analysis (Customer Segmentation)](#22-rfm-analysis-customer-segmentation)
  - [2.3 Top 10 Highest-Spending Customers](#23-top-10-highest-spending-customers)
  - [2.4 Customer Retention Rate](#24-customer-retention-rate)
  - [2.5 Customer Lifetime Value (LTV)](#25-customer-lifetime-value-ltv)
  - [2.6 Customer Churn Rate](#26-customer-churn-rate)
  - [2.7 Average Revenue Per User (ARPU)](#27-average-revenue-per-user-arpu)
  - [2.8 Repeat Purchase Rate (Customer Loyalty)](#28-repeat-purchase-rate-customer-loyalty)
- [**Authors**](#authors)

---


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


   ### 📊 **Top 10 Customers by Total Spending**
| CustomerID | Monetary Value |
|------------|---------------|
| 14646      | 280,206.02    |
| 18102      | 259,657.30    |
| 17450      | 194,390.79    |
| 16446      | 168,472.50    |
| 14911      | 143,711.17    |
| 12415      | 124,914.53    |
| 14156      | 117,210.08    |
| 17511      | 91,062.38     |
| 16029      | 80,850.84     |
| 12346      | 77,183.60     |
 

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


    ### 📊 **RFM Analysis (Customer Segmentation)**

#### 📊 **Result:**
| CustomerID | Recency (Days) | Frequency | Monetary Value ($) |
|------------|--------------|-----------|---------------------|
| 14085      | 49           | 18        | 4,421.29           |
| 14911      | 49           | 201       | 143,711.17         |
| 13165      | 49           | 2         | 1,021.48           |
| 13777      | 49           | 33        | 25,977.16          |
| 13817      | 49           | 2         | 382.98             |
| 13922      | 49           | 1         | 172.25             |
| 12585      | 49           | 2         | 2,040.10           |
| 12748      | 49           | 209       | 33,053.19          |
| 13304      | 49           | 1         | 300.42             |
| 15235      | 49           | 12        | 2,247.51           |


### **2.3 Top 10 Highest-Spending Customers**

    SELECT
        CustomerID,
        SUM(quantity * price) AS TotalSpent
    FROM online_retail
    GROUP BY CustomerID
    ORDER BY TotalSpent DESC
    LIMIT 10;
    
### 📊 **Top 10 Highest-Spending Customers**

#### 📊 **Result:**
| CustomerID | Total Spent ($) |
|------------|---------------|
| 14646      | 280,206.02    |
| 18102      | 259,657.30    |
| 17450      | 194,390.79    |
| 16446      | 168,472.50    |
| 14911      | 143,711.17    |
| 12415      | 124,914.53    |
| 14156      | 117,210.08    |
| 17511      | 91,062.38     |
| 16029      | 80,850.84     |
| 12346      | 77,183.60     |



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

    Retention Rate (%)
65.58

### 📊 **Customer Lifetime Value (LTV)**
## 📌 What is LTV?
Customer Lifetime Value (LTV) represents the total revenue a business expects to earn from a customer during their entire relationship. It helps businesses understand which customers are the most valuable and guides strategies for retention, marketing, and personalized offers.

### 📌 LTV Formula:
\[ LTV = \text{Avg Order Value} \times \text{Total Purchases} \times \text{Customer Lifespan} \]

Where:
- **Avg Order Value** = Total Revenue / Total Purchases
- **Total Purchases** = Number of distinct invoices per customer
- **Customer Lifespan** = The number of years a customer has been active

### 📌 Query:
```sql
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
```

### 📊 **Top 10 Customers by Lifetime Value (LTV)**

| CustomerID | Total Purchases | Total Revenue ($) | Avg Order Value ($) | Customer Lifespan (Years) | LTV ($) |
|------------|----------------|------------------|------------------|-----------------------|----------|
| 17949      | 45             | 58,510.48       | 835.86          | 0.92                  | 34,604.60 |
| 18102      | 60             | 259,657.30      | 602.45          | 0.84                  | 30,363.48 |
| 17450      | 46             | 194,390.79      | 578.54          | 0.91                  | 24,217.68 |
| 16029      | 63             | 80,850.84       | 335.48          | 0.96                  | 20,289.83 |
| 16013      | 47             | 37,130.60       | 267.13          | 0.94                  | 11,801.80 |
| 16333      | 22             | 26,626.80       | 591.71          | 0.83                  | 10,804.62 |
| 15769      | 26             | 56,252.72       | 432.71          | 0.91                  | 10,237.92 |
| 17857      | 23             | 26,879.04       | 497.76          | 0.83                  | 9,502.24  |
| 14646      | 73             | 280,206.02      | 134.97          | 0.94                  | 9,261.64  |
| 12931      | 15             | 42,055.96       | 512.88          | 0.84                  | 6,462.29  |

---


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


**Churn Rate (%)**
**22.75**

### **2.7 Average Revenue Per User (ARPU)**

📌 What is ARPU?
Average Revenue Per User (ARPU) measures the average revenue generated per customer over a given period.
It is calculated using the formula:

ARPU = Total Revenue / Total Customers
 
✅ Helps businesses understand revenue efficiency per customer.
✅ Useful for benchmarking customer profitability & growth.
✅ Higher ARPU means customers are spending more, leading to better revenue.

    SELECT
        ROUND(SUM(quantity * price) / COUNT(DISTINCT CustomerID), 2) AS ARPU
    FROM online_retail;


**ARPU ($)**
**2048.69**

### **2.8 Repeat Purchase Rate (Customer Loyalty)**


📌 What is Repeat Purchase Rate?
Repeat Purchase Rate measures the percentage of customers who made more than one purchase.
It is calculated as:

Repeat Purchase Rate =   (Customers with >1 purchase) * 100/ Total Customers

✅ Indicates customer loyalty & engagement.
✅ A higher repeat purchase rate means strong customer retention.
✅ A 65% rate suggests that most customers return for additional purchases.

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

**Repeat Purchase Rate (%)**
**65.00**

## **Authors**
- [@PatelVaishvikk](https://github.com/PatelVaishvikk)


