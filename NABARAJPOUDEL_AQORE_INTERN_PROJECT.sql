----QUESTION NO 1
--CREATE THE CUSTOMER TABLE
CREATE TABLE Customer
(
CustomerID INT IDENTITY(1,1) PRIMARY KEY,
CustomerName VARCHAR(100) NOT NULL,
CustomerEmail NVARCHAR(100) NOT NULL UNIQUE,
CustomerPhone NVARCHAR(15),
CustomerAddress VARCHAR(100),
);

--CREATE THE PRODUCT TABLE
CREATE TABLE Product
(
ProductID INT IDENTITY(1,1) PRIMARY KEY,
ProductName VARCHAR(100) NOT NULL,
Price DECIMAL(10,2) NOT NULL,
ProductRemaining INT NOT NULL DEFAULT 0,
InsertDate Date Default getdate(),
);


--CREATE THE SALES TRANSACTION TABLE
CREATE TABLE SalesTransaction
(
TransactionID INT IDENTITY(1,1) PRIMARY KEY,
ProductID INT NOT NULL,
CustomerID INT NOT NULL,
ProductQuantity INT NOT NULL,
TotalAmount DECIMAL(10,2) NOT NULL,
FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
TransactionDate DATE NOT NULL DEFAULT GETDATE(),
);
ALTER TABLE SalesTransaction
ADD InvoiceMade NVARCHAR(50);




--CREATE THE INVOICE TABLE

CREATE TABLE Invoice
(
InvoiceID INT IDENTITY(1,1) PRIMARY KEY,
CustomerID INT NOT NULL,
TransactionID INT NOT NULL,
DiscountAmount DECIMAL(10,2),
NetAmount DECIMAL(10,2) NOT NULL,
FOREIGN KEY (TransactionID) REFERENCES SalesTransaction(TransactionID),
FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
InvoiceDate DATE DEFAULT GETDATE(),
);

select * from Customer
select * from Product
select * from SalesTransaction
select * from Invoice



-----QUESTION NO 2

--i]

---Stored Procedure to Create Product
CREATE PROCEDURE InsertProduct
@json NVARCHAR(MAX)
AS
BEGIN
SET NOCOUNT ON;
BEGIN TRY
BEGIN TRANSACTION;
INSERT INTO Product
(
ProductName,
Price,
ProductRemaining,
InsertDate
)
SELECT
ProductName,
Price,
ProductRemaining,
InsertDate
FROM OPENJSON(@json)
WITH
(
ProductName VARCHAR(100),
Price DECIMAL(10,2),
ProductRemaining INT,
InsertDate Date
);
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION
THROW;
END CATCH
END


----Stored Procedure to update product
CREATE PROCEDURE UpdateProduct
@ProductID INT,
@json NVARCHAR(MAX)
AS
BEGIN
SET NOCOUNT ON;
BEGIN TRY
BEGIN TRANSACTION;
UPDATE Product
SET
ProductName =J.ProductName,
Price = J.Price,
ProductRemaining = J.ProductRemaining,
InsertDate = J.InsertDate
FROM OPENJSON(@json)
WITH
(
ProductName VARCHAR(100),
Price DECIMAL(10,2),
ProductRemaining INT,
InsertDate Date
) AS J
WHERE ProductID = @ProductID;
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
THROW;
END CATCH
END



----Stored procedure to Delete product
CREATE PROCEDURE DeleteProduct
@ProductID INT
AS
BEGIN
SET NOCOUNT ON;
BEGIN TRY
BEGIN TRANSACTION;
DELETE FROM Product
WHERE ProductID = @ProductID;
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
THROW;
END CATCH


END


----Stored procedure to Insert Customer 
CREATE PROCEDURE InsertCustomer
@json NVARCHAR(MAX)
AS
BEGIN
SET NOCOUNT ON;
BEGIN TRY
BEGIN TRANSACTION;
INSERT INTO Customer
(
CustomerName,
CustomerEmail,
CustomerPhone,
CustomerAddress
)
SELECT
CustomerName,
CustomerEmail,
CustomerPhone,
CustomerAddress
FROM OPENJSON(@json)
WITH
(
CustomerName VARCHAR(100),
CustomerEmail NVARCHAR(100),
CustomerPhone NVARCHAR(15),
CustomerAddress VARCHAR(100)
);
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
THROW;
END CATCH
END



--Stored procedure to update customer
CREATE PROCEDURE UpdateCustomer
@CustomerID INT,
@json NVARCHAR(MAX)
AS
BEGIN
SET NOCOUNT ON;
BEGIN TRY
BEGIN TRANSACTION;
UPDATE Customer
SET
CustomerName = J.CustomerName,
CustomerEmail = J.CustomerEmail,
CustomerPhone = J.CustomerPhone,
CustomerAddress = J.CustomerAddress

FROM OPENJSON(@json)
WITH
(
CustomerName VARCHAR(100),
CustomerEmail NVARCHAR(100),
CustomerPhone NVARCHAR(15),
CustomerAddress VARCHAR(100)
) AS J

WHERE CustomerID = @CustomerId;
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
THROW;
END CATCH
END


-- Stored procedure to Delete customer
CREATE PROCEDURE DeleteCustomer
@CustomerID INT
AS
BEGIN
SET NOCOUNT ON;
BEGIN TRY
BEGIN TRANSACTION;
DELETE FROM Customer
WHERE CustomerID = @CustomerID;
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
THROW;
END CATCH
END





----Stored procedure to update the Sales Transaction
CREATE PROCEDURE UpdateSalesTransaction
@TransactionId INT,
@json NVARCHAR(MAX)
AS
BEGIN
SET NOCOUNT ON;
BEGIN TRY
BEGIN TRANSACTION;
UPDATE SalesTransaction
SET
ProductId=j.ProductId,
CustomerID=j.CustomerId,
ProductQuantity=j.ProductQuantity,
TotalAmount=j.TotalAmount,
TransactionDate=j.TransactionDate,
InvoiceMade=j.InvoiceMade

FROM OPENJSON(@json)
WITH
(
ProductId int,
CustomerID int,
ProductQuantity int,
TotalAmount decimal(10,2),
TransactionDate date,
InvoiceMade nvarchar
) AS j

WHERE TransactionId=@TransactionId
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
THROW;
END CATCH
END


-- Stored procedure to delete the Sales Transaction
CREATE PROCEDURE DeleteSalesTransaction
@TransactionId INT
AS
BEGIN
SET NOCOUNT ON;
BEGIN TRY
BEGIN TRANSACTION;
DELETE FROM SalesTransaction
WHERE TransactionId = @TransactionId;
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
THROW;
END CATCH
END

 ---Create stored procedure for all CRUD operations.
CREATE PROCEDURE SelectInvoice
AS
BEGIN
SET NOCOUNT ON;
BEGIN TRY
BEGIN TRANSACTION;
SELECT * FROM Invoice
FOR JSON AUTO;
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
THROW;
END CATCH
END


----Stored procedure the delete invoice
CREATE PROCEDURE DeleteInvoice
@InvoiceId INT
AS
BEGIN
SET NOCOUNT ON;
BEGIN TRY
BEGIN TRANSACTION;
DELETE FROM Invoice
WHERE InvoiceId = @InvoiceId;
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
THROW;
END CATCH
END



--ii] Create Invoice with following conditions:
--• Once the invoice is generated for the customer, tag the sales transaction with the
--correct invoice.
--• Even if a customer buys multiple items, create a single invoice (bill) only.
--• Should calculate a discount of 5% if the total invoice amount is less than or equal
--to 1000 and 10% if the total invoice amount is greater than 1000.

CREATE PROCEDURE GenerateInvoice
@json NVARCHAR(MAX)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @TransactionID INT;
DECLARE @TotalAmount DECIMAL(10, 2);
DECLARE @DiscountAmount DECIMAL(10, 2);
DECLARE @NetAmount DECIMAL(10, 2);
BEGIN TRY
BEGIN TRANSACTION;
-- Create Sales Transaction and get the TransactionID
INSERT INTO SalesTransaction

(
ProductID,
CustomerID,
ProductQuantity,
TotalAmount,
TransactionDate
)

SELECT
ProductID,
CustomerID,
ProductQuantity,
TotalAmount,
GETDATE()

FROM OPENJSON(@json)
WITH (
ProductID int,
CustomerID int,
ProductQuantity int,
TotalAmount decimal(10,2),
TransactionDate date
);


SET @TransactionID = SCOPE_IDENTITY();
-- Calculate discount based on TotalAmount
SET @TotalAmount = (SELECT TotalAmount
FROM SalesTransaction
WHERE TransactionID = @TransactionID);

IF @TotalAmount <= 1000
SET @DiscountAmount = @TotalAmount * 0.05;
ELSE
SET @DiscountAmount = @TotalAmount * 0.10;
-- Calculate NetAmount (TotalAmount - DiscountAmount)
SET @NetAmount = @TotalAmount - @DiscountAmount;
-- Insert Invoice with calculated values
INSERT INTO Invoice

(
CustomerID,
TransactionID,
DiscountAmount,
NetAmount,
InvoiceDate
)
VALUES
(
(SELECT CustomerID FROM SalesTransaction
WHERE TransactionID = @TransactionID),
@TransactionID,
@DiscountAmount,
@NetAmount,
GETDATE()
);

COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
THROW;
END CATCH;
END;





------QUESTION NO 3
--Query to return following:
--1] List of customers whose name starts with the letter "A" or ends with the letter "S" but should have the letter "K"

SELECT *
FROM Customer
WHERE (CustomerName LIKE 'A%' OR CustomerName LIKE '%S')
AND CustomerName LIKE '%K%';




--2] Customers whose invoice is not processed yet.
SELECT c.CustomerID, c.CustomerName, c.CustomerEmail, c.CustomerPhone, c.CustomerAddress
FROM Customer c
WHERE NOT EXISTS (
    SELECT 1
    FROM Invoice i
    WHERE i.CustomerID = c.CustomerID
)

--3] Name of customer who has spent highest amount in a specific date range.DECLARE @StartDate DATE = '2022-01-01'
DECLARE @EndDate DATE = '2023-12-31'
SELECT TOP 1 C.CustomerName, SUM(st.TotalAmount) AS 'Amount Spend'
FROM Customer AS C
INNER JOIN SalesTransaction st
ON C.CustomerID = st.CustomerID
WHERE st.TransactionDate BETWEEN @StartDate AND @EndDate
GROUP BY C.CustomerName
ORDER BY SUM(st.TotalAmount) DESC


--4] Remove the product which is not bought in the current year.

DELETE FROM Product
WHERE ProductID NOT IN (
    SELECT DISTINCT p.ProductID
    FROM Product p
    INNER JOIN SalesTransaction st ON p.ProductID = st.ProductID
    WHERE YEAR(st.TransactionDate) = YEAR(GETDATE())
);


--5] The product should have a remaining column which shows the remaining quantity of
--the product. This should be updated on the basis of sales transactions. List out the
--products whose remaining quantity is less than 2.
SELECT *
FROM Product
WHERE ProductRemaining < 2;

--6] Get the product of the year (The product that was bought by maximum customers this
--year.)
SELECT TOP 1 P.ProductID, P.ProductName, COUNT(DISTINCT
ST.CustomerID) AS CustomerCount
FROM Product P
JOIN SalesTransaction ST
ON P.ProductID = ST.ProductID
WHERE YEAR(ST.TransactionDate) = YEAR(GETDATE())
GROUP BY P.ProductID, P.ProductName
ORDER BY CustomerCount DESC;


--7] Return the list of customers who bought more than 10 products.
SELECT C.CustomerID, C.CustomerName
FROM Customer C
JOIN SalesTransaction ST
ON C.CustomerID = ST.CustomerID
GROUP BY C.CustomerID, C.CustomerName
HAVING COUNT(ST.TransactionID) > 10;





-------QUESTION NO 4
--4. Create a function with following:
--• Input Parameters:
--• Customer (can pass multiple ids e.g.: 103,904)
--• Start Date and End Date
--• Requirement:
--• Should return total bill amount of the customer in the given date range.

CREATE FUNCTION GetTotalBillAmount
(
@ID INT,
@StartDate DATE,
@EndDate DATE
)
RETURNS DECIMAL(10,2)
AS
BEGIN
DECLARE @TotalBillAmount DECIMAL(10,2)
SELECT @TotalBillAmount =
(
SELECT SUM(NetAmount) AS TotalBill FROM Invoice AS I
WHERE I.InvoiceDate BETWEEN @StartDate AND @EndDate
GROUP BY CustomerID
HAVING CustomerID =@ID
)
RETURN @TotalBillAmount
END


------QUESTION NO 5

--5. Create a Store Procedure:
--• Input Parameters:
--• Start Date and End date
--• Customer Id (if no customer Id is passed then return all data else the given customer’s
--data only)
--• Requirement:
--• Should return all the customers’ information entered in the database within the date
--range
--• Should return the total invoice (bill) amount of the customer

CREATE PROC GetCustomerBillByDate
@json NVARCHAR(MAX)
AS
DECLARE
@ID INT,
@StartDate DATE,
@EndDate DATE
BEGIN
SELECT
@ID = ID,
@StartDate = StartDate,
@EndDate = EndDate
FROM
OPENJSON(@json)
WITH
(
ID INT,
StartDate DATE,
EndDate DATE
)
IF @ID > 0
BEGIN
SELECT
C.CustomerID,
C.CustomerName,
C.CustomerAddress,
I.NetAmount AS BillAmount,
I.InvoiceDate
FROM Customer AS C
INNER JOIN Invoice AS I
ON C.CustomerID = I.CustomerID
WHERE C.CustomerID = @ID
AND I.InvoiceDate BETWEEN @StartDate AND @EndDate
FOR JSON AUTO;
END
ELSE
BEGIN
SELECT
C.CustomerID,
C.CustomerName,
C.CustomerAddress,
I.NetAmount AS BillAmount,
I.InvoiceDate
FROM Customer AS C
INNER JOIN Invoice AS I
ON C.CustomerID = I.CustomerID
WHERE I.InvoiceDate BETWEEN @StartDate AND @EndDate
FOR JSON AUTO;
END
END