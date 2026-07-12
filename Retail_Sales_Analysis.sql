==========================================================================================================================
                                RETAIL SALES ANALYSIS PROJECT
==========================================================================================================================

--PROJECT OVERVIEW

--This project analyzes retail sales data using SQL to uncover trends in sales performance, customer behavior, product performance, and revenue generation.
--The project demonstrates end-to-end SQL analytics by building a relational database, performing exploratory data analysis, applying window functions,
-- Common Table Expressions (CTEs), ranking techniques, customer segmentation,and business-oriented reporting.
--The objective is to transform raw transactional data into actionable business insights that support strategic decision-making.

--------------------------------------------------------------------------------------------------------------------------
BUSINESS PROBLEM
--------------------------------------------------------------------------------------------------------------------------

--Retail organizations generate thousands of sales transactions every day.
--However, raw transactional data alone provides limited business value.
--Business stakeholders require answers to questions such as:

• Are sales growing over time?
• Which customers generate the highest revenue?
• Which products drive profitability?
• Which product categories should receive more investment?
• How is customer purchasing behavior changing?
• Which business segments require attention?

--This project answers these questions using SQL.

--------------------------------------------------------------------------------------------------------------------------
TOOLS USED
--------------------------------------------------------------------------------------------------------------------------

• PostgreSQL
• SQL
• Window Functions
• Common Table Expressions (CTEs)
• Aggregate Functions
• Ranking Functions

===============================================================================
DATASET OVERVIEW
===============================================================================

The project uses a retail sales database consisting of multiple related tables.
Each table captures a different aspect of the customer purchasing journey.

--------------------------------------------------------------------------------
TABLE NAME                 DESCRIPTION
--------------------------------------------------------------------------------
gold.dim_customers         Customer demographic information

gold.dim_products          Product details including category and cost

gold.fact_sales            Transaction-level sales records linking customers,
                           products, orders, quantity, price and sales amount


+------------------------+
|     dim_customers      |
+------------------------+
| PK customer_key        |
| customer_id            |
| customer_number        |
| first_name             |
| last_name              |
| country                |
| ...                    |
+------------------------+
           |
           | 1
           |
           |<---------------------- FK customer_key
           |
           | *
+------------------------+
|      fact_sales        |
+------------------------+
| order_number           |
| FK customer_key        |
| FK product_key         |
| order_date             |
| quantity               |
| sales_amount           |
| price                  |
| ...                    |
+------------------------+
           |
           | *
           |
           |----------------------> 1
           |
+------------------------+
|      dim_products      |
+------------------------+
| PK product_key         |
| product_name           |
| category               |
| subcategory            |
| cost                   |
| ...                    |
+------------------------+
=================================================================================
DATABASE RELATIONSHIP
=================================================================================

dim_customers
      |
      | customer_key
      |
fact_sales
      |
      | product_key
      |
dim_products

--The Star Schema enables efficient analytical queries while maintaining data integrity through dimension and fact table relationships.

=================================================================================
-- DATABASE CREATION
=================================================================================
-- NOTE:
-- The CSV files are available in the repository's `datasets` folder.
-- Update the file paths below to point to the location of these files on your local machine before running the COPY commands.

-- Drop and recreate the database
DROP DATABASE IF EXISTS datawarehouseanalytics;
CREATE DATABASE datawarehouseanalytics;

-- Connect to the new database
\c datawarehouseanalytics;

-- Create schema
CREATE SCHEMA gold;

-- Dimension tables
CREATE TABLE gold.dim_customers (
    customer_key     int,
    customer_id      int,
    customer_number  varchar(50),
    first_name       varchar(50),
    last_name        varchar(50),
    country          varchar(50),
    marital_status   varchar(50),
    gender           varchar(50),
    birthdate        date,
    create_date      date
);

CREATE TABLE gold.dim_products (
    product_key   int,
    product_id    int,
    product_number varchar(50),
    product_name  varchar(50),
    category_id   varchar(50),
    category      varchar(50),
    subcategory   varchar(50),
    maintenance   varchar(50),
    cost          int,
    product_line  varchar(50),
    start_date    date
);

CREATE TABLE gold.fact_sales (
    order_number  varchar(50),
    product_key   int,
    customer_key  int,
    order_date    date,
    shipping_date date,
    due_date      date,
    sales_amount  int,
    quantity      smallint,
    price         int
);

TRUNCATE TABLE gold.dim_customers;
COPY gold.dim_customers
FROM 'D:\SQL Practice\Projects\Project 1\datasets\flat-files\dim_customers.csv'
DELIMITER ',' CSV HEADER;

TRUNCATE TABLE gold.dim_products;
COPY gold.dim_products
FROM 'D:\SQL Practice\Projects\Project 1\datasets\flat-files\dim_products.csv'
DELIMITER ',' CSV HEADER;

TRUNCATE TABLE gold.fact_sales;
COPY gold.fact_sales
FROM 'D:\SQL Practice\Projects\Project 1\datasets\flat-files\fact_sales.csv'
DELIMITER ',' CSV HEADER;

SELECT *
FROM gold.dim_customers

SELECT *
FROM gold.dim_products

SELECT *
FROM gold.fact_sales

=================================================================================
BUSINESS QUESTION 1: HOW HAS THE BUSINESS PERFORMED OVER TIME?
=================================================================================

BUSINESS OBJECTIVE

--Evaluate overall business performance by analyzing yearly revenue, customer acquisition, order volume, product demand, and cumulative sales growth. 
--This analysis helps identify long-term business trends and assess whether the business is expanding over time.

===============================================================================

SELECT
    EXTRACT(YEAR FROM order_date) AS order_year,

    SUM(sales_amount) AS total_sales,

    COUNT(DISTINCT customer_key) AS total_customers,

    COUNT(DISTINCT order_number) AS total_orders,

    SUM(quantity) AS total_quantity,

    SUM(SUM(sales_amount))
    OVER (
        ORDER BY EXTRACT(YEAR FROM order_date)
    ) AS cumulative_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY order_year;

=================================================================================
BUSINESS INSIGHTS
=================================================================================
• Revenue increased substantially across the complete years (2011–2013),indicating sustained business growth.

• Customer acquisition and order volume also increased during the same period, suggesting that business expansion was driven by a growing
  customer base and higher purchasing activity.

• Product demand peaked in 2013, with the highest quantity of products sold, making it the strongest-performing year in the dataset.

• Cumulative revenue increased consistently over time, demonstrating positive long-term business performance.

• The dataset spans from 20-Dec-2010 to 28-Jan-2014. Since 2010 and 2014 contain only partial-year data, business performance should be
  evaluated primarily using the complete years (2011–2013).

=================================================================================
BUSINESS RECOMMENDATIONS
=================================================================================
• Focus long-term performance evaluations on complete financial years (2011–2013) to ensure accurate trend analysis.

• Investigate the marketing initiatives, customer acquisition strategies, and product portfolio that contributed to the exceptional
  performance observed in 2013.

• Continue monitoring revenue, customer growth, order volume, and cumulative sales together, as they provide a comprehensive view of
  business performance over time.

• Use cumulative revenue trends to support strategic planning, forecasting, and long-term business decision-making.

=================================================================================
BUSINESS QUESTION 2: WHICH PRODUCTS ARE DRIVING BUSINESS PERFORMANCE?
=================================================================================

BUSINESS OBJECTIVE

--Evaluate yearly product performance by comparing each product's sales against its historical average and previous year's performance.
--This analysis helps identify consistently high-performing products,declining products, and products experiencing strong year-over-year growth.

=================================================================================
WITH yearly_product_sales AS
(SELECT EXTRACT(YEAR FROM f.order_date) AS yearly_data, p.product_name, SUM(f.sales_amount) AS yearly_sales
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY EXTRACT(YEAR FROM f.order_date), p.product_name
ORDER BY EXTRACT(YEAR FROM f.order_date), p.product_name)

SELECT yearly_data, product_name, yearly_sales, ROUND(AVG(yearly_sales) OVER(PARTITION BY product_name ORDER BY yearly_data)) AS historical_avg_sales, yearly_sales - ROUND(AVG(yearly_sales) OVER(PARTITION BY product_name ORDER BY yearly_data)) AS difference_from_avg,
CASE 
	WHEN yearly_sales - ROUND(AVG(yearly_sales) OVER(PARTITION BY product_name ORDER BY yearly_data)) > 0 THEN 'above_average'
	WHEN yearly_sales - ROUND(AVG(yearly_sales) OVER(PARTITION BY product_name ORDER BY yearly_data)) < 0 THEN 'below_average'
    ELSE 'avg'
END AS performance_vs_average,
LAG(yearly_sales) OVER(PARTITION BY product_name ORDER BY yearly_data ASC) AS prev_year_sales,
yearly_sales - LAG(yearly_sales) OVER(PARTITION BY product_name ORDER BY yearly_data ASC) AS year_over_year_difference,
CASE 
	WHEN yearly_sales - LAG(yearly_sales) OVER(PARTITION BY product_name ORDER BY yearly_data ASC) > 0 THEN 'increase'
	WHEN yearly_sales - LAG(yearly_sales) OVER(PARTITION BY product_name ORDER BY yearly_data ASC) < 0 THEN 'decrease'
    ELSE 'no change'
END AS year_over_year_trend
FROM yearly_product_sales
GROUP BY yearly_data, product_name, yearly_sales
ORDER BY yearly_data, product_name, yearly_sales

=================================================================================
BUSINESS INSIGHTS
=================================================================================
• Product performance varies considerably across years, indicating that customer demand changes over time rather than remaining constant.

• Several products consistently outperform their historical average,suggesting strong and sustained market demand.

• Multiple products demonstrate positive year-over-year sales growth,indicating increasing customer adoption and revenue potential.

• A subset of products experienced declining sales compared to the previous year despite strong historical performance, highlighting the
  importance of monitoring both long-term consistency and recent trends.

• Combining historical average performance with year-over-year comparisons provides a more balanced assessment than relying on a
  single performance metric.

=================================================================================
BUSINESS RECOMMENDATIONS
=================================================================================

• Prioritize inventory planning and marketing investment for products that consistently perform above their historical average and continue
  to grow year over year.

• Investigate products with declining year-over-year sales to identify potential causes such as changing customer preferences, pricing,
  increased competition, or product lifecycle effects.

• Regularly monitor both historical performance and recent growth trends when evaluating product success to support informed merchandising and
  product portfolio decisions.

• Use the performance classifications to identify opportunities for promotional campaigns, inventory optimization, and future sales
  forecasting.

=================================================================================
BUSINESS QUESTION 3: WHICH PRODUCT CATEGORIES CONTRIBUTE THE MOST TO REVENUE?
=================================================================================

BUSINESS OBJECTIVE

--Analyze the contribution of each product category to total business revenue. 
--Understanding category-level revenue distribution helps identify the primary revenue drivers and supports inventory, marketing, and product portfolio decisions.

=================================================================================
WITH category_sales AS
(SELECT category, SUM(sales_amount) AS total_sales
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON f.product_key = p.product_key
GROUP BY category)

SELECT category, total_sales, SUM(total_sales) OVER() AS total_business_sales, ROUND((total_sales :: NUMERIC / SUM(total_sales) OVER())*100,1) AS contribution
FROM category_sales
ORDER BY total_sales DESC;

===============================================================================
BUSINESS INSIGHTS
===============================================================================
• Bikes account for 96.5% of total business revenue, making them the primary revenue driver and the foundation of the company sales
  performance.

• Accessories contribute only 2.4% of total revenue, while Clothing contributes 1.2%, indicating that these categories currently play a
  relatively small role in overall business performance.

• Revenue is highly concentrated in a single product category,suggesting strong specialization but also increased dependence on the
  Bikes category for overall business success.

• The significant difference in category contributions highlights opportunities to evaluate whether Accessories and Clothing can be
  expanded to diversify revenue streams.

===============================================================================
BUSINESS RECOMMENDATIONS
===============================================================================
• Continue prioritizing inventory availability, pricing strategies, and marketing investments for Bikes, as they generate the majority of
  business revenue.

• Explore cross-selling opportunities by bundling Accessories and Clothing with Bike purchases to increase average order value.

• Evaluate product assortment and promotional strategies for Accessories and Clothing to improve their contribution to total
  revenue and reduce dependence on a single category.

• Regularly monitor category-level revenue distribution to identify shifts in customer demand and support long-term product portfolio
  planning.

===============================================================================
BUSINESS QUESTION 4: HOW ARE PRODUCTS DISTRIBUTED ACROSS COST SEGMENTS?
===============================================================================

BUSINESS OBJECTIVE
=================================================================================
--Classify products into cost-based segments to understand the product portfolio structure. 
--This analysis helps identify the distribution of low-cost, mid-range, and premium products, supporting pricing,
inventory, and merchandising decisions.

===============================================================================

WITH product_segment AS
(SELECT product_key, product_name, cost,
CASE
	WHEN cost < 100 THEN 'below 100'
	WHEN cost BETWEEN 100 AND 500 THEN '100-500'
	WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
	ELSE 'above 1000'
END product_cost_segment
FROM gold.dim_products)

SELECT product_cost_segment, COUNT(product_key) AS total_products
FROM product_segment
GROUP BY product_cost_segment

===============================================================================
BUSINESS INSIGHTS
===============================================================================
• The product portfolio is primarily concentrated in lower-priced segments, with 110 products priced below 100 and 101 products priced
  between 100 and 500.

• Mid-range products (500–1000) represent only 45 products, indicating a relatively smaller presence in this pricing tier.

• Premium products (above 1000) account for 39 products, suggesting the company maintains a focused high-value product offering rather than a
  broad premium portfolio.

• The overall distribution indicates a balanced emphasis on affordable products while maintaining selected premium offerings to address
  different customer segments.

===============================================================================
BUSINESS RECOMMENDATIONS
===============================================================================
• Continue maintaining a strong assortment of lower-priced products, as they represent the largest portion of the product portfolio.

• Evaluate opportunities to expand the mid-range product segment if customer demand exists, creating a smoother progression between
  affordable and premium products.

• Regularly review the performance of premium products to ensure they generate sufficient revenue and profit relative to their inventory
  investment.

• Combine cost segmentation with sales performance analysis to identify whether each pricing tier is contributing proportionately to business
  revenue.

===============================================================================
BUSINESS QUESTION 5: HOW ARE CUSTOMERS SEGMENTED BASED ON PURCHASING BEHAVIOUR?
===============================================================================

BUSINESS OBJECTIVE

Segment customers based on purchasing history and lifetime spending to identify high-value customers, regular customers, and newly acquired
customers. This analysis supports customer relationship management,retention strategies, and targeted marketing initiatives.

Group customers into 3 segments based on their spending behaviour:
--VIP: customers with atleast 12 months of history & spending more than 5000.
--REGULAR: customers with atleast 12 months of history but spending 5000 or less.
--NEW: customers with lifespan less than 12 months.
and then find the number of customers by each group
===============================================================================

WITH customer_summary AS
(SELECT c.customer_key, MIN(f.order_date) AS first_order, MAX(f.order_date) AS last_order, SUM(f.sales_amount) AS total_spending, (DATE_PART('year',AGE(MAX(f.order_date), MIN(f.order_date)))*12 + DATE_PART('month',AGE(MAX(f.order_date), MIN(f.order_date)))) AS lifespan
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key)

SELECT 
	CASE 
		WHEN cs.lifespan >= 12 AND cs.total_spending >= 5000 THEN 'VIP'
		WHEN cs.lifespan >= 12 AND cs.total_spending <= 5000 THEN 'REGULAR'
		ELSE 'NEW'
	END AS customer_segment,
COUNT(cs.customer_key) AS customer_key_count
FROM customer_summary AS cs
GROUP BY customer_segment
ORDER BY customer_key_count	

===============================================================================
BUSINESS INSIGHTS

• New customers represent the largest customer segment (14,884),indicating that most customers have a purchasing history of less than
  12 months.

• Regular customers account for 2,037 customers, demonstrating a smaller but established customer base with ongoing purchasing
  activity.

• VIP customers represent 1,563 high-value customers who have both longer purchasing histories and higher lifetime spending, making them
  the companys most valuable customer segment.

• The significant difference between new and returning customer segments highlights an opportunity to improve long-term customer
  retention and increase customer lifetime value.

===============================================================================
BUSINESS RECOMMENDATIONS
===============================================================================
• Develop customer retention programs to convert New customers into Regular customers through personalized marketing, loyalty programs,
  and repeat purchase incentives.

• Strengthen engagement with VIP customers by offering exclusive benefits, early product access, and premium customer support to
  encourage long-term loyalty.

• Monitor customer migration between segments over time to evaluate the effectiveness of retention and customer relationship strategies.

• Combine customer segmentation with purchasing behaviour and product preferences to deliver more targeted marketing campaigns and improve
  overall customer lifetime value.

===============================================================================
FINAL DELIVERABLE: CUSTOMER ANALYTICS REPORT
===============================================================================

REPORT OBJECTIVE

--Create a reusable customer analytics report that consolidates key customer information, purchasing behaviour, and business KPIs into a
single view. 
--This report enables business users to analyze customer value, purchasing patterns, recency, and segmentation for decision-
making, reporting, and customer relationship management.

===============================================================================
REPORT FEATURES
===============================================================================

• Consolidates customer demographics and transaction history into a single analytical view.

• Calculates customer-level KPIs including:
    - Total Orders
    - Total Sales
    - Total Quantity Purchased
    - Total Products Purchased
    - Customer Lifespan
    - Average Order Value
    - Average Monthly Spend
    - Recency

• Classifies customers into business-defined customer segments (VIP, REGULAR, NEW).

• Groups customers into age brackets for demographic analysis.

• Creates a reusable SQL View that can support dashboards,
  reporting, and downstream analytics.

===============================================================================
IMPLEMENTATION
===============================================================================
CREATE VIEW gold.report_customers AS 
--1) Base Query: Retrieve core columns from the tables

WITH base_query AS
(SELECT f.order_number, 
        f.product_key, 
	    f.order_date, 
	    f.sales_amount, 
	    f.quantity, 
	    c.customer_key, 
	    c.customer_number, 
	    CONCAT(c.first_name, ' ', c.last_name) AS customer_name, 
	    EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birthdate)) AS age
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
ON f.customer_key = c.customer_key
WHERE order_date IS NOT NULL),

--2) Customer Aggregations: Summarizes key metrics at customer level

customer_aggregation AS 
(SELECT customer_key, 
        customer_name, 
	    age, 
	    COUNT(DISTINCT order_number) AS total_orders, 
	    SUM(sales_amount) AS total_sales, 
	    SUM(quantity) AS total_quantity,
	    COUNT(product_key) AS total_product_key_purchased,
	    MAX(order_date) AS last_order_date,
	    (DATE_PART('year', AGE(MAX(order_date), MIN(order_date))) * 12 + DATE_PART('month', AGE(MAX(order_date), MIN(order_date)))) AS lifespan_months
FROM base_query
GROUP BY customer_key, customer_name, age)

--3) Final Output: Summarizes key metrics at customer level
SELECT customer_key, 
       customer_name, 
	   age, 
	   total_orders, 
	   total_sales, 
	   total_quantity, 
	   total_product_key_purchased, 
	   lifespan_months,
CASE 
	WHEN age < 18 THEN 'UNDERAGE'
	WHEN age BETWEEN 18 AND 60 THEN 'ADULT'
	ELSE 'SENIOR CITIZEN'
END AS age_bracket,
CASE 
	WHEN lifespan_months > 12 AND total_sales > 5000 THEN 'VIP'
	WHEN lifespan_months >= 12 AND total_sales <= 5000 THEN 'REGULAR'
	ELSE 'NEW'
END AS segmentation,
last_order_date, 
(DATE_PART('year',AGE(CURRENT_DATE, last_order_date))*12 + DATE_PART('month',AGE(CURRENT_DATE, last_order_date))) AS recency_months,
CASE 
	WHEN total_orders = 0 THEN 0
	ELSE total_sales / total_orders 
END AS avg_order_value,
CASE 
	WHEN lifespan_months = 0 THEN total_sales
	ELSE total_sales / lifespan_months 
END AS avg_monthly_spend
FROM customer_aggregation;

SELECT *
FROM gold.report_customers

===============================================================================
BUSINESS VALUE
===============================================================================

• Provides a centralized customer analytics dataset for reporting and
  business intelligence.

• Enables marketing teams to identify high-value customers for targeted
  campaigns and loyalty programs.

• Supports customer retention analysis through recency, lifespan, and
  spending metrics.

• Assists sales teams in understanding customer purchasing behaviour
  and lifetime value.

• Serves as a reusable foundation for Power BI dashboards and advanced
  customer analytics.

===============================================================================