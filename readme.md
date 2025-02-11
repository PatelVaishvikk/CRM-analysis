# Customer Relationship Management (CRM) Analysis

![CRM Analysis](images/animation.gif)

## 📌 Overview
This project provides SQL-based CRM analytics using PostgreSQL. The dataset contains transactional data, including invoices, customer IDs, product details, and timestamps. Key metrics analyzed include Customer Lifetime Value (LTV), RFM segmentation, Customer Retention Rate, and Churn Rate.

## 🗂️ Table of Contents
- [1️⃣ Data Preparation](#1️⃣-data-preparation)
- [2️⃣ CRM Analysis](#2️⃣-crm-analysis)
  - [2.1 Total Spending by Each Customer](#21-total-spending-by-each-customer)
  - [2.2 RFM Analysis](#22-rfm-analysis-customer-segmentation)
  - [2.3 Top 10 Highest-Spending Customers](#23-top-10-highest-spending-customers)
  - [2.4 Customer Retention Rate](#24-customer-retention-rate)
  - [2.5 Customer Lifetime Value (LTV)](#25-customer-lifetime-value-ltv)
  - [2.6 Customer Churn Rate](#26-customer-churn-rate)
  - [2.7 Average Revenue Per User (ARPU)](#27-average-revenue-per-user-arpu)
  - [2.8 Repeat Purchase Rate](#28-repeat-purchase-rate-customer-loyalty)

---

## 1️⃣ Data Preparation

### 📌 Create Table
```sql
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
```

### 📌 Load Data
```sql
COPY online_retail(Invoice, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID, Country)
FROM 'C:/Drive(D)/CRM_online_retail/online_retail_cleaned.csv'
DELIMITER ','
CSV HEADER;
```

### 📌 Data Cleaning
```sql
DELETE FROM online_retail WHERE CustomerID IS NULL;
DELETE FROM online_retail;
```

### 📌 Indexing for Faster Queries
```sql
CREATE INDEX idx_invoice ON online_retail(Invoice);
CREATE INDEX idx_customer ON online_retail(CustomerID);
CREATE INDEX idx_date ON online_retail(InvoiceDate);
```

---

## 2️⃣ CRM Analysis

### **2.1 Total Spending by Each Customer**
```sql
SELECT CustomerID, SUM(quantity * price) AS MonetaryValue
FROM online_retail
GROUP BY CustomerID;
```

### 📊 **Top 10 Customers by Total Spending**
| CustomerID | Monetary Value ($) |
|------------|-------------------|
| 14646      | 280,206.02        |
| 18102      | 259,657.30        |
| 17450      | 194,390.79        |
| 16446      | 168,472.50        |
| 14911      | 143,711.17        |
| 12415      | 124,914.53        |
| 14156      | 117,210.08        |
| 17511      | 91,062.38         |
| 16029      | 80,850.84         |
| 12346      | 77,183.60         |

### **2.2 RFM Analysis (Customer Segmentation)**
```sql
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
```

### 📊 **RFM Analysis (Customer Segmentation)**
| CustomerID | Recency (Days) | Frequency | Monetary Value ($) |
|------------|--------------|-----------|---------------------|
| 14085      | 49           | 18        | 4,421.29           |
| 14911      | 49           | 201       | 143,711.17         |
| 13165      | 49           | 2         | 1,021.48           |

### **2.3 Top 10 Highest-Spending Customers**
```sql
SELECT CustomerID, SUM(quantity * price) AS TotalSpent
FROM online_retail
GROUP BY CustomerID
ORDER BY TotalSpent DESC
LIMIT 10;
```

### **2.4 Customer Retention Rate**
```sql
WITH RepeatCustomers AS (
    SELECT CustomerID, COUNT(DISTINCT Invoice) AS TotalPurchases
    FROM online_retail
    GROUP BY CustomerID
)
SELECT ROUND(COUNT(CASE WHEN TotalPurchases > 1 THEN CustomerID END) * 100.0 / COUNT(*), 2) AS RetentionRate
FROM RepeatCustomers;
```
Retention Rate: **65.58%**

### **2.5 Customer Lifetime Value (LTV)**
```sql
WITH customer_lifespan AS (
    SELECT
        CustomerID,
        MIN(InvoiceDate) AS FirstPurchaseDate,
        MAX(InvoiceDate) AS LastPurchaseDate,
        ROUND(EXTRACT(EPOCH FROM (MAX(InvoiceDate) - MIN(InvoiceDate))) / (365.25 * 86400), 2) AS CustomerLifespanYears
    FROM online_retail
    GROUP BY CustomerID
)
SELECT
    CustomerID, 
    ROUND((TotalRevenue / TotalPurchases) * TotalPurchases * CustomerLifespanYears, 2) AS LTV
FROM customer_lifespan
ORDER BY LTV DESC
LIMIT 10;
```

### **2.6 Customer Churn Rate**
```sql
WITH last_purchase AS (
    SELECT CustomerID, MAX(InvoiceDate) AS LastPurchaseDate
    FROM online_retail
    GROUP BY CustomerID
)
SELECT ROUND(
    COUNT(CASE WHEN EXTRACT(DAY FROM (CURRENT_TIMESTAMP - LastPurchaseDate)) > 180 THEN CustomerID END) * 100.0 / COUNT(CustomerID), 2
) AS ChurnRate FROM last_purchase;
```
Churn Rate: **22.75%**

### **2.7 Average Revenue Per User (ARPU)**
```sql
SELECT ROUND(SUM(quantity * price) / COUNT(DISTINCT CustomerID), 2) AS ARPU
FROM online_retail;
```
ARPU: **$2048.69**

### **2.8 Repeat Purchase Rate**
```sql
WITH purchase_counts AS (
    SELECT CustomerID, COUNT(DISTINCT Invoice) AS PurchaseCount
    FROM online_retail
    GROUP BY CustomerID
)
SELECT ROUND(COUNT(CASE WHEN PurchaseCount > 1 THEN CustomerID END) * 100.0 / COUNT(DISTINCT CustomerID), 2) AS RepeatPurchaseRate
FROM purchase_counts;
```
Repeat Purchase Rate: **65.00%**

## **Authors**
- [@PatelVaishvikk](https://github.com/PatelVaishvikk)
