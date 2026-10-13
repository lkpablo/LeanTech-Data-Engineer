
CREATE SCHEMA IF NOT EXISTS SALES_DW.SCRATCH;
USE SCHEMA SALES_DW.SCRATCH;

---------------------------------------------- Sample data ---------------------------------------

CREATE OR REPLACE TEMPORARY TABLE Employees (EmployeeID INT, Name VARCHAR, ManagerID INT);
INSERT INTO Employees VALUES
    (1, 'Alice', NULL),   -- CEO
    (2, 'Bob',   1),
    (3, 'Carol', 1),
    (4, 'Dave',  2),
    (5, 'Eve',   2),
    (6, 'Frank', 4),
    (7, 'Grace', 3),
    (8, 'Heidi', 6);      -- four levels below the CEO

CREATE OR REPLACE TEMPORARY TABLE Orders (OrderID INT, CustomerID INT, OrderDate DATE);
INSERT INTO Orders VALUES
    (1, 101, '2026-01-05'), (2, 101, '2026-02-10'),   -- ordered and paid
    (3, 102, '2026-01-20'),                           -- ordered, never paid
    (4, 103, '2026-03-01'), (5, 103, '2026-03-15'), (6, 103, '2026-04-02');  -- three orders, never paid

CREATE OR REPLACE TEMPORARY TABLE Payments (PaymentID INT, CustomerID INT, PaymentDate DATE, Amount NUMBER(12, 2));
INSERT INTO Payments VALUES
    (1, 101,  '2026-01-06', 50.00),
    (2, 104,  '2026-02-01', 20.00),   -- paid without an order
    (3, NULL, '2026-02-15', 10.00);   -- payment not linked to a customer

------------------ 1. Every employee with all their managers up to the CEO ---------------------


WITH RECURSIVE chain AS (
    SELECT 
        EmployeeID
        ,Name
        ,ManagerID
        ,IFF(ManagerID IS NULL, 0, 1) AS Level
    FROM Employees

    UNION ALL

    SELECT 
        c.EmployeeID
        ,c.Name
        ,m.ManagerID
        ,c.Level + 1
    FROM chain c
        JOIN Employees m 
            ON m.EmployeeID = c.ManagerID
    WHERE m.ManagerID IS NOT NULL
      AND c.Level < 50
)
SELECT
    c.EmployeeID,
    c.Name AS Employee,
    c.ManagerID,
    m.Name AS Manager,
    c.Level AS LevelsUp      
FROM chain c
LEFT JOIN Employees m 
    ON m.EmployeeID = c.ManagerID
ORDER BY c.EmployeeID, c.Level;

--------------------------- 2. Customers who made an order but no payment -------------------------


SELECT DISTINCT 
    o.CustomerID
FROM Orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM Payments p
    WHERE p.CustomerID = o.CustomerID
)
ORDER BY o.CustomerID;

SELECT DISTINCT o.CustomerID
FROM Orders o
LEFT JOIN Payments p 
    ON p.CustomerID = o.CustomerID
WHERE p.CustomerID IS NULL
ORDER BY o.CustomerID;


SELECT DISTINCT 
    o.CustomerID
FROM Orders o
WHERE o.CustomerID NOT IN (SELECT p.CustomerID FROM Payments p);
