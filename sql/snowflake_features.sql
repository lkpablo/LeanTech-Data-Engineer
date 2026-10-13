
USE SCHEMA SALES_DW.SCRATCH;

------------------------------------------ Cloning --------------------------------

CREATE OR REPLACE TABLE fact_sales_demo CLONE SALES_DW.ANALYTICS.FACT_SALES;
ALTER TABLE fact_sales_demo SET DATA_RETENTION_TIME_IN_DAYS = 30;   -- Enterprise: up to 90

SELECT 
    COUNT(*) AS sales
    ,SUM(amount) AS revenue 
FROM fact_sales_demo;

---------------------------------------- Time Travel -------------------------------

UPDATE fact_sales_demo SET amount = 0;
SET bad_statement = LAST_QUERY_ID();

SELECT 
    SUM(amount) AS revenue_after_mistake 
FROM fact_sales_demo;


SELECT 
    SUM(amount) AS revenue_before_mistake
FROM fact_sales_demo BEFORE (STATEMENT => $bad_statement);


INSERT OVERWRITE INTO fact_sales_demo
SELECT 
    * 
FROM fact_sales_demo BEFORE (STATEMENT => $bad_statement);

SELECT 
    SUM(amount) AS revenue_restored 
FROM fact_sales_demo;


DROP TABLE fact_sales_demo;
UNDROP TABLE fact_sales_demo;
SELECT COUNT(*) AS sales_after_undrop FROM fact_sales_demo;

DROP TABLE fact_sales_demo;

