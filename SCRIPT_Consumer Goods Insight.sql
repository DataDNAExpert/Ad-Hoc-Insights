-- 1.Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT DISTINCT MARKET FROM DIM_CUSTOMER WHERE REGION ='APAC'
AND CUSTOMER='ATLIQ EXCLUSIVE';

-- 2.What is the percentage of unique product increase in 2021 vs. 2020? 
-- The final output contains these fields : unique_products_2020, unique_products_2021 ,percentage_chg


WITH T2020 
AS
(SELECT COUNT(distinct(PRODUCT_CODE)) AS CNT_2020 FROM FACT_SALES_MONTHLY 
	WHERE FISCAL_YEAR = '2020'),
T2021 
AS
(SELECT COUNT(distinct(PRODUCT_CODE)) AS CNT_2021 FROM FACT_SALES_MONTHLY 
	WHERE FISCAL_YEAR = '2021')
SELECT T2020.CNT_2020 AS unique_products_2020 , T2021.CNT_2021 AS unique_products_2021,
ROUND((((T2021.CNT_2021 - T2020.CNT_2020) / T2020.CNT_2020)*100),2) AS "percentage_chg" 
	FROM T2020,T2021;

-- 3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
--   The final output contains 2 fields:  segment ,product_count

SELECT SEGMENT ,COUNT(PRODUCT_CODE) AS CNT FROM DIM_PRODUCT
GROUP BY SEGMENT
ORDER BY COUNT(PRODUCT_CODE) DESC;


-- 4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these 
-- fields : segment , product_count_2020 ,product_count_2021 , difference

SELECT A.SEGMENT AS segment, 
MAX(CASE WHEN A.FISCAL_YEAR =2020 THEN A.CONT END) AS product_count_2020 ,
MAX(CASE WHEN A.FISCAL_YEAR = 2021 THEN A.CONT END) AS product_count_2021,
(
MAX(CASE WHEN A.FISCAL_YEAR = 2021 THEN A.CONT END)
-
MAX(CASE WHEN A.FISCAL_YEAR =2020 THEN A.CONT END) 
) AS difference 
FROM  
(
SELECT SEGMENT , P.FISCAL_YEAR, COUNT(DIM_PRODUCT.PRODUCT_CODE) AS CONT FROM DIM_PRODUCT,
FACT_GROSS_PRICE P 
WHERE DIM_PRODUCT.PRODUCT_CODE = P.PRODUCT_CODE 
AND P.FISCAL_YEAR IN (2020,2021)
GROUP BY SEGMENT,P.FISCAL_YEAR
) A
GROUP BY A.SEGMENT;


-- 5.Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields :
-- product_code, product, manufacturing_cost

SELECT A.product_code, D.product, A.manufacturing_cost FROM 
fact_manufacturing_cost A join dim_product D
ON A.PRODUCT_CODE = D.PRODUCT_CODE WHERE manufacturing_cost 
IN 
(
SELECT MAX(manufacturing_cost) AS manufacturing_cost FROM FACT_MANUFACTURING_COST
union
SELECT Min(manufacturing_cost) AS manufacturing_cost FROM FACT_MANUFACTURING_COST
);

-- 6.Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the 
-- fiscal year 2021 and in the Indian market. The final output contains these fields :
-- customer_code, customer, average_discount_percentage

SELECT D.customer_code, D.customer, 
concat(ROUND(AVG(A.pre_invoice_discount_pct),3),'%') AS average_discount_percentage 
FROM fact_pre_invoice_deductions A JOIN DIM_CUSTOMER D
ON A.customer_code= D.customer_code
WHERE D.MARKET ='INDIA' AND A.FISCAL_YEAR=2021 
GROUP BY A.customer_code
ORDER BY AVG(A.pre_invoice_discount_pct) DESC
LIMIT 5;

/* ISSUE NOT ASKED ABOVE AVERAGE : SELECT D.customer_code, D.CUSTOMER, concat(ROUND(AVG(A.pre_invoice_discount_pct),3),'%') AS average_discount_percentage FROM fact_pre_invoice_deductions A JOIN DIM_CUSTOMER D
ON A.customer_code= D.customer_code
WHERE D.MARKET ='INDIA' AND A.FISCAL_YEAR=2021 
AND A.pre_invoice_discount_pct > (SELECT AVG(pre_invoice_discount_pct) FROM fact_pre_invoice_deductions
WHERE fiscal_year = 2021)
GROUP BY A.customer_code
ORDER BY AVG(A.pre_invoice_discount_pct) DESC
LIMIT 5;
*/

-- 7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions.
-- The final report contains these columns: Month, Year, Gross sales Amount

SELECT MONTHNAME(SALES.DATE) AS MONTH, YEAR(SALES.DATE) AS YEAR, 
-- CONCAT(ROUND((SUM(PRD.gross_price * SALES.sold_quantity)/1000000),4), ' m') AS "Gross sales Amount" 
ROUND((SUM(PRD.gross_price * SALES.sold_quantity)/1000000),4) AS "Gross sales Amount" 
FROM fact_sales_monthly SALES JOIN fact_gross_price PRD
ON SALES.fiscal_year=PRD.fiscal_year
JOIN DIM_CUSTOMER CUST
ON SALES.CUSTOMER_CODE = CUST.CUSTOMER_CODE
AND SALES.product_code=PRD.product_code
WHERE 
CUST.CUSTOMER ='Atliq Exclusive'
GROUP BY
MONTH(SALES.DATE), YEAR(SALES.DATE)  
ORDER BY MONTH(SALES.DATE) ASC;


-- 8.In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted 
-- by the total_sold_quantity,Quarter, total_sold_quantit

-- QUARTER START WITH SEPTEMBER TILL AUGUST IF FY = 2020 THEN SEP 2019 TILL AUG 2020 
SELECT a.quarter, sum(a.total_sold_quantity) as total_sold_quantity from 
(
SELECT  
CASE 
WHEN S.DATE >= '2019-01-01' AND S.DATE <= '2019-11-30' THEN 'Q1'   
WHEN S.DATE >= '2019-12-01' AND S.DATE <= '2020-02-29' THEN 'Q2'   
WHEN S.DATE >= '2020-03-01' AND S.DATE <= '2020-05-30' THEN 'Q3'   
WHEN S.DATE >= '2019-06-01' AND S.DATE <= '2020-08-31' THEN 'Q4'   
END AS Quarter, SUM(S.sold_quantity) AS total_sold_quantity FROM 
fact_sales_monthly S  WHERE
S.fiscal_year='2020'
GROUP BY S.DATE
) as a
group by a.quarter;

SELECT SUM(S.sold_quantity * P.gross_price) AS TOTAL FROM fact_sales_monthly Q WHERE Q.fiscal_year=2021;

-- 9.Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields :
-- channel, gross_sales_mln, percentage

SELECT A.CHANNEL AS channel, A.GROSS_SALES_MLN AS gross_sales_mln, 
concat(ROUND(((ROUND(A.GROSS_SALES_MLN,0) / ROUND(B.sales,0))*100),2), '%') AS percentage 
FROM
(SELECT C.CHANNEL AS channel, ROUND((SUM(S.sold_quantity * P.gross_price)/1000000),4) AS gross_sales_mln FROM 
fact_sales_monthly S JOIN fact_gross_price P
ON S.fiscal_year = P.fiscal_year AND S.product_code = P.product_code
JOIN DIM_CUSTOMER C
ON S.CUSTOMER_CODE = C.CUSTOMER_CODE
WHERE S.fiscal_year = 2021
GROUP BY C.CHANNEL
) A,
(
SELECT ROUND((SUM(S.sold_quantity * P.gross_price)/1000000),4) AS sales
 FROM fact_sales_monthly S JOIN fact_gross_price P
ON S.fiscal_year = P.fiscal_year AND
S.product_code = P.product_code
JOIN DIM_CUSTOMER C
ON S.CUSTOMER_CODE = C.CUSTOMER_CODE
WHERE S.fiscal_year = 2021
)B;

-- 10.Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields :
-- division, product_code, product, total_sold_quantity, rank_order
SELECT	A.division, A.product_code, A.product,A.QTY AS total_sold_quantity,A.RANKING AS rank_order FROM
(
SELECT PRD.DIVISION, PRD.product_code,PRD.product,
SUM(SALES.sold_quantity) AS qty, DENSE_RANK() OVER(PARTITION BY PRD.division ORDER BY division,SUM(SALES.SOLD_QUANTITY) DESC) AS Ranking 
FROM fact_sales_monthly SALES JOIN dim_product PRD ON SALES.product_code=PRD.product_CODE
WHERE SALES.fiscal_year='2021'
GROUP BY PRD.DIVISION, PRD.product_code,PRD.product
) A
WHERE A.RANKING <=3
group by A.DIVISION,A.PRODUCT_CODE