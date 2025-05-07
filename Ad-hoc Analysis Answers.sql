USE `gdb023`;


/* 1.Provide the list of markets in which customer 
"Atliq  Exclusive" operates its business in the  APAC region. */

SELECT market
FROM dim_customer 
WHERE customer='Atliq Exclusive' AND region='APAC'
GROUP BY market;



/* 2.What is the percentage of unique product increase in 2021 vs. 2020? The final
output contains these fields, unique_products_2020, unique_products_2021,
percentage_chg.*/

WITH cte1 AS(
SELECT COUNT(DISTINCT product_code) AS unique_products_2020
	FROM fact_sales_monthly
	WHERE fiscal_year=2020),
cte2 AS(
SELECT COUNT(DISTINCT product_code) AS unique_products_2021
	FROM fact_sales_monthly
	WHERE fiscal_year=2021)
SELECT*,
round((unique_products_2021-unique_products_2020)*100/unique_products_2020,2) 
as percentage_chg
FROM cte1 cross join cte2;
    
    
    
/* 3.Provide a report with all the unique product counts for each  segment  and 
sort them in descending order of product counts. The final output contains 
2 fields, segment product_count */

SELECT Segment,
COUNT(DISTINCT (product_code)) as Product_count
FROM dim_product
GROUP BY Segment
ORDER BY Product_count DESC ;



/* 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
The final output contains these fields, segment, product_count_2020, 
product_count_2021, difference. */
WITH cte1 AS
( SELECT
      dp.segment AS segment,
      COUNT(DISTINCT
          (CASE 
              WHEN fiscal_year = 2020 THEN fsm.product_code END)) AS product_count_2020,
       COUNT(DISTINCT
          (CASE 
              WHEN fiscal_year = 2021 THEN fsm.product_code END)) AS product_count_2021        
 FROM fact_sales_monthly AS fsm
 INNER JOIN dim_product AS dp
 ON fsm.product_code = dp.product_code
 GROUP BY dp.segment  )
SELECT segment, product_count_2020, product_count_2021, 
	(product_count_2021-product_count_2020) AS difference
FROM cte1
ORDER BY difference DESC;



/* 5.Get the products that have the highest and lowest manufacturing costs. The final output should
contain these fields, product_code ,product, manufacturing_cost */
 
SELECT fmc.product_code, dp.product, fmc.manufacturing_cost
FROM fact_manufacturing_cost fmc
	JOIN dim_product dp
	ON fmc.product_code = dp.product_code
WHERE manufacturing_cost
	IN (
		SELECT MAX(manufacturing_cost)
		FROM fact_manufacturing_cost
	UNION
		SELECT MIN(manufacturing_cost)
		FROM fact_manufacturing_cost
	   )
ORDER BY manufacturing_cost DESC;
 
 
 
 /*6. Generate a report which contains the top 5 customers who received an average high
pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these
fields, customer_code, customer, average_discount_percentage .*/

SELECT dc.customer_code, dc.customer,
ROUND(AVG(pre_invoice_discount_pct)*100,2) AS average_discount_percentage
	FROM fact_pre_invoice_deductions fd
		JOIN dim_customer dc
		ON fd.customer_code = dc.customer_code
	WHERE dc.market = "India" AND fiscal_year = "2021"
GROUP BY customer_code,dc.customer
ORDER BY average_discount_percentage DESC
	LIMIT 5;
 
 
 
/*7.Get the complete report of the Gross sales amount for the customer “AtliQ Exclusive” for each month. This
analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report
contains these columns: Month, Year, Gross sales Amount.*/

SELECT 
    MONTHNAME(fsm.date) AS month_name,
    fsm.fiscal_year AS year,
    ROUND(SUM(fsm.sold_quantity * fgp.gross_price), 2) AS gross_sales_amount
FROM fact_sales_monthly AS fsm
JOIN dim_customer AS dc 
    ON fsm.customer_code = dc.customer_code
JOIN fact_gross_price AS fgp 
    ON fsm.product_code = fgp.product_code 
    AND fsm.fiscal_year = fgp.fiscal_year
WHERE dc.customer = 'AtliQ Exclusive'
GROUP BY month_name,year
ORDER BY year;



/* 8.In which quarter of 2020, got the maximum total_sold_quantity? 
The final output contains these fields sorted by the total_sold_quantity,
Quarter, total_sold_quantity. */

SELECT
	CASE
		WHEN MONTH(date) IN (9,10,11) THEN 'Q1'
		WHEN MONTH(date) IN (12,1,2) THEN 'Q2'
		WHEN MONTH(date) IN (3,4,5) THEN 'Q3'
	ELSE 'Q4'
	END AS quarters,
SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters
ORDER BY total_sold_quantity DESC;



/* 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of
contribution? The final output contains these fields, channel, gross_sales_mln, percentage.*/
WITH gross_sales AS
( SELECT c.channel AS channel_,
    ROUND(SUM(b.gross_price * a.sold_quantity) / 1000000, 2) AS gross_sales_million
  FROM fact_sales_monthly AS a
  LEFT JOIN fact_gross_price AS b
    ON a.product_code = b.product_code
    AND a.fiscal_year = b.fiscal_year
  LEFT JOIN dim_customer AS c
    ON a.customer_code = c.customer_code
  WHERE a.fiscal_year = 2021
  GROUP BY c.channel
)SELECT 
  channel_ AS channel,gross_sales_million,
  ROUND(gross_sales_million / SUM(gross_sales_million) OVER() * 100, 2) AS percentage
FROM gross_sales
ORDER BY percentage DESC;



/* 10.Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year
2021? The final output contains these fields, division product_code product total_sold_quantity
rank_order. */

SELECT division, product_code, product, total_sold_quantity, rank_order
FROM (
    SELECT 
        dp.division,
        fsm.product_code,
        dp.product,
        SUM(fsm.sold_quantity) AS total_sold_quantity,
        RANK() OVER (PARTITION BY dp.division ORDER BY SUM(fsm.sold_quantity) DESC) AS 
        rank_order
    FROM fact_sales_monthly fsm
    JOIN dim_product dp ON fsm.product_code = dp.product_code
    WHERE fsm.fiscal_year = 2021
    GROUP BY dp.division, fsm.product_code, dp.product
) ranked
WHERE rank_order <=3
ORDER BY division, rank_order;











 
 
 