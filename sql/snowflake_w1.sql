CREATE DATABASE TAPIR_ECOMERSE_DB;

USE TAPIR_ECOMERSE_DB;
CREATE OR REPLACE SCHEMA TAPIR_ECOMERSE_DB_TOOLS.INTERNAL_STAGES;
CREATE OR REPLACE SCHEMA STAGE_EXTERNAL;
CREATE OR REPLACE STAGE TAPIR_ECOMERSE_DB.STAGE_EXTERNAL.ecommerce_orders;

LIST @TAPIR_ECOMERSE_DB.STAGE_EXTERNAL.ecommerce_orders;

CREATE OR REPLACE TABLE td_ecommerce_orders
AS
SELECT $1 as Order_ID,
       $2 as Customer_ID,
       $3 AS Customer_Name,
       $4 as Order_Date,
       $5 as Product, 
       $6 as Quantity,
       $7 as Price,
       $8 as Discount,
       $9 as Total_Amount,
       $10 as Payment_Method,
       $11 as Shipping_Address,
       $12 as Status
FROM @TAPIR_ECOMERSE_DB.STAGE_EXTERNAL.ecommerce_orders/ecommerce_orders.csv
where 1=2;

SELECT * FROM td_ecommerce_orders;
DELETE FROM td_ecommerce_orders;

COPY INTO td_ecommerce_orders
FROM (
   select $1 as Order_ID,
       $2 as Customer_ID,
       $3 AS Customer_Name,
       $4 as Order_Date,
       $5 as Product, 
       $6 as Quantity,
       $7 as Price,
       $8 as Discount,
       $9 as Total_Amount,
       $10 as Payment_Method,
       $11 as Shipping_Address,
       $12 as Status
FROM @TAPIR_ECOMERSE_DB.STAGE_EXTERNAL.ecommerce_orders/ecommerce_orders.csv
)
FILE_FORMAT = (
    TYPE = CSV, SKIP_HEADER = 1
)

FORCE = TRUE;

CREATE OR REPLACE TABLE td_for_review 
AS
SELECT $1 as Order_ID,
       $2 as Customer_ID,
       $3 AS Customer_Name,
       $4 as Order_Date,
       $5 as Product, 
       $6 as Quantity,
       $7 as Price,
       $8 as Discount,
       $9 as Total_Amount,
       $10 as Payment_Method,
       $11 as Shipping_Address,
       $12 as Status
FROM TAPIR_ECOMERSE_DB.STAGE_EXTERNAL.TD_ECOMMERCE_ORDERS
WHERE 1=2;

INSERT INTO td_for_review
SELECT *
FROM TAPIR_ECOMERSE_DB.STAGE_EXTERNAL.TD_ECOMMERCE_ORDERS
WHERE Shipping_Address IS NULL AND Status = 'Delivered';

SELECT * FROM td_for_review;

CREATE OR REPLACE TABLE td_suspisios_records 
AS
SELECT $1 as Order_ID,
       $2 as Customer_ID,
       $3 AS Customer_Name,
       $4 as Order_Date,
       $5 as Product, 
       $6 as Quantity,
       $7 as Price,
       $8 as Discount,
       $9 as Total_Amount,
       $10 as Payment_Method,
       $11 as Shipping_Address,
       $12 as Status
FROM TAPIR_ECOMERSE_DB.STAGE_EXTERNAL.TD_ECOMMERCE_ORDERS
WHERE 1=2;

SELECT * FROM td_suspisios_records;

INSERT INTO td_for_review
SELECT *
FROM TAPIR_ECOMERSE_DB.STAGE_EXTERNAL.TD_ECOMMERCE_ORDERS
WHERE Customer_ID IS NULL;

UPDATE TD_ECOMMERCE_ORDERS
SET Payment_Method = 'Unknown'
WHERE Payment_Method IS NULL;


CREATE OR REPLACE TABLE td_invalid_quanity_or_price
AS
SELECT $1 as Order_ID,
       $2 as Customer_ID,
       $3 AS Customer_Name,
       $4 as Order_Date,
       $5 as Product, 
       $6 as Quantity,
       $7 as Price,
       $8 as Discount,
       $9 as Total_Amount,
       $10 as Payment_Method,
       $11 as Shipping_Address,
       $12 as Status
FROM TAPIR_ECOMERSE_DB.STAGE_EXTERNAL.TD_ECOMMERCE_ORDERS
WHERE 1=2;

select * from TAPIR_ECOMERSE_DB.STAGE_EXTERNAL.TD_SUSPISIOS_RECORDS;

insert into TAPIR_ECOMERSE_DB.STAGE_EXTERNAL.TD_INVALID_QUANITY_OR_PRICE 
select *
FROM TD_ECOMMERCE_ORDERS
WHERE TRY_TO_NUMBER(Quantity) <= 0 OR TRY_TO_NUMBER(Price) <= 0;

DELETE FROM TD_ECOMMERCE_ORDERS
WHERE TRY_TO_NUMBER(Quantity) <= 0 OR TRY_TO_NUMBER(Price) <= 0;

UPDATE TD_ECOMMERCE_ORDERS
SET Discount = 
    CASE 
        WHEN Discount < 0.0 THEN 0.0
        WHEN Discount > 0.5 THEN 0.5
        ELSE Discount
    END;

UPDATE TD_ECOMMERCE_ORDERS
SET Total_Amount = Quantity * Price * (1 - Discount);

UPDATE TD_ECOMMERCE_ORDERS
SET STATUS = 'Pending'
WHERE STATUS = 'Delivered' AND SHIPPING_ADDRESS IS NULL;

CREATE OR REPLACE TABLE td_clean_records
AS
SELECT $1 as Order_ID,
       $2 as Customer_ID,
       $3 AS Customer_Name,
       $4 as Order_Date,
       $5 as Product, 
       $6 as Quantity,
       $7 as Price,
       $8 as Discount,
       $9 as Total_Amount,
       $10 as Payment_Method,
       $11 as Shipping_Address,
       $12 as Status
FROM TAPIR_ECOMERSE_DB.STAGE_EXTERNAL.TD_ECOMMERCE_ORDERS
WHERE 1=2;

select * from TAPIR_ECOMERSE_DB.STAGE_EXTERNAL.TD_ECOMMERCE_ORDERS;

INSERT INTO TAPIR_ECOMERSE_DB.STAGE_EXTERNAL.TD_CLEAN_RECORDS
SELECT *
FROM ( select distinct * 
    from TAPIR_ECOMERSE_DB.STAGE_EXTERNAL.TD_ECOMMERCE_ORDERS
);

select * from TAPIR_ECOMERSE_DB.STAGE_EXTERNAL.TD_CLEAN_RECORDS;