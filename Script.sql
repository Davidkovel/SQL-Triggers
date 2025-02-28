CREATE DATABASE SportShop;
USE SportShop;

CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    Type NVARCHAR(50) NOT NULL,
    QuantityInStock INT NOT NULL,
    CostPrice DECIMAL(10, 2) NOT NULL,
    Manufacturer NVARCHAR(100),
    SellingPrice DECIMAL(10, 2) NOT NULL
);

CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    FullName NVARCHAR(100) NOT NULL,
    Position NVARCHAR(50) NOT NULL,
    HireDate DATE NOT NULL,
    Gender NVARCHAR(10) NOT NULL,
    Salary DECIMAL(10, 2) NOT NULL
);

CREATE TABLE Clients (
    ClientID INT PRIMARY KEY IDENTITY(1,1),
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100),
    Phone NVARCHAR(15),
    Gender NVARCHAR(10) NOT NULL,
    OrderHistory NVARCHAR(MAX),
    DiscountPercentage DECIMAL(5, 2),
    IsSubscribed BIT NOT NULL
);

CREATE TABLE Sales (
    SaleID INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
    SellingPrice DECIMAL(10, 2) NOT NULL,
    Quantity INT NOT NULL,
    SaleDate DATE NOT NULL,
    EmployeeID INT FOREIGN KEY REFERENCES Employees(EmployeeID),
    ClientID INT FOREIGN KEY REFERENCES Clients(ClientID)
);


CREATE TABLE SalesHistory (
    SaleID INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT,
    SellingPrice DECIMAL(10, 2) NOT NULL,
    Quantity INT NOT NULL,
    SaleDate DATE NOT NULL,
    EmployeeID INT,
    ClientID INT
);


CREATE TABLE ArchivedProducts (
    ProductID INT PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Type NVARCHAR(50) NOT NULL,
    QuantityInStock INT NOT NULL,
    CostPrice DECIMAL(10, 2) NOT NULL,
    Manufacturer NVARCHAR(100),
    SellingPrice DECIMAL(10, 2) NOT NULL
);

CREATE TABLE LastUnitProducts (
    ProductID INT PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Type NVARCHAR(50) NOT NULL,
    QuantityInStock INT NOT NULL,
    CostPrice DECIMAL(10, 2) NOT NULL,
    Manufacturer NVARCHAR(100),
    SellingPrice DECIMAL(10, 2) NOT NULL
);

-- INSERTING

INSERT INTO Products (Name, Type, QuantityInStock, CostPrice, Manufacturer, SellingPrice)
VALUES 
('Running Shoes', 'Footwear', 50, 40.00, 'Nike', 80.00),
('Yoga Pants', 'Clothing', 100, 20.00, 'Adidas', 50.00),
('Tennis Racket', 'Equipment', 30, 60.00, 'Wilson', 120.00);

INSERT INTO Employees (FullName, Position, HireDate, Gender, Salary)
VALUES 
('John Doe', 'Sales Manager', '2020-01-15', 'Male', 3000.00),
('Jane Smith', 'Cashier', '2021-05-10', 'Female', 2000.00);

INSERT INTO Clients (FullName, Email, Phone, Gender, OrderHistory, DiscountPercentage, IsSubscribed)
VALUES 
('Alice Johnson', 'alice@example.com', '123-456-7890', 'Female', 'Running Shoes, Yoga Pants', 10.00, 1),
('Bob Brown', 'bob@example.com', '987-654-3210', 'Male', 'Tennis Racket', 5.00, 0);

INSERT INTO Sales (ProductID, SellingPrice, Quantity, SaleDate, EmployeeID, ClientID)
VALUES 
(1, 80.00, 2, '2023-10-01', 1, 1),
(2, 50.00, 1, '2023-10-02', 2, 2);


-- SELECTING TRIGGERS

-- 1
CREATE TRIGGER trg_InsertToHistorySales
ON Sales
AFTER INSERT
AS
BEGIN
	INSERT INTO SalesHistory (ProductID, SellingPrice, Quantity, SaleDate, EmployeeID, ClientID)
	SELECT ProductID, SellingPrice, Quantity, SaleDate, EmployeeID, ClientID FROM INSERTED;
END;

-- 2
CREATE TRIGGER trg_MoveToArchiveProducts
ON Products
AFTER UPDATE
AS 
BEGIN
	INSERT INTO ArchivedProducts (ProductID, Name, Type, QuantityInStock, CostPrice, Manufacturer, SellingPrice)
	SELECT P.ProductID, P.Name, P.Type, P.QuantityInStock, P.CostPrice, P.Manufacturer, P.SellingPrice FROM Products P
	INNER JOIN inserted I ON P.ProductID = I.ProductID
	WHERE I.QuantityInStock = 0;

	DELETE FROM Products
	WHERE ProductID IN (SELECT ProductID FROM INSERTED WHERE QuantityInStock = 0);
END;

-- 3
CREATE TRIGGER trg_AvoidDuplicateUser
ON Clients
INSTEAD OF INSERT
AS 
BEGIN
	 (
		SELECT 1
		FROM Clients C
		INNER JOIN INSERTED I ON C.FullName = I.FullName OR C.Email = I.Email
	)
	BEGIN
		RAISERROR('Client with the same Full Name or Email already exists.', 0, 1)	
	END
	ELSE
	BEGIN
		INSERT INTO Clients (FullName, Email, Phone, Gender, OrderHistory, DiscountPercentage, IsSubscribed)
		SELECT FullName, Email, Phone, Gender, OrderHistory, DiscountPercentage, IsSubscribed FROM INSERTED;
	END
END

-- 4

CREATE TRIGGER trg_PreventDeletion
ON Clients
INSTEAD OF DELETE
AS
BEGIN
	RAISERROR('You can not delete the Clients', 0, 1);
	
END;

-- 5	
CREATE TRIGGER trg_PreventDeletionEmployees
ON Employees
INSTEAD OF DELETE
AS
BEGIN
	 (
		SELECT 1
		FROM SELECTED
		WHERE HireDate < '2015-01-01'
	)
	BEGIN
		RAISERROR('Deletion of employees hired before 2015 is not allowed', 0, 1);
	END
	ELSE
	BEGIN
		DELETE FROM Employees
		WHERE EmployeeID IN (SELECT EmployeeID FROM DELETED);
	END
END;

-- 6
CREATE TRIGGER trg_SetClientDiscount
ON Sales
AFTER INSERT
AS
BEGIN
	UPDATE Clients
	SET DiscountPercentage = 15
	WHERE ClientID IN (
		SELECT S.ClientID
		FROM Sales S
		INNER JOIN INSERTED I ON S.ClientID = I.ClientID
		GROUP BY S.ClientID
		HAVING SUM(S.SellingPrice * S.Quantity) > 50000
	);
END

-- 7
CREATE TRIGGER trg_PreventSpecificManufactur
ON Products
INSTEAD OF INSERT
AS
BEGIN
	 (
		SELECT 1
		FROM INSERTED
		WHERE Manufacturer = 'Sport, Sun, Bar'
	)
	BEGIN 
		RAISERROR('Adding products from this manufacturer is not allowed.', 0, 1);
	END
	ELSE
	BEGIN
		INSERT INTO Products (Name, Type, QuantityInStock, CostPrice, Manufacturer, SellingPrice)
		SELECT Name, Type, QuantityInStock, CostPrice, Manufacturer, SellingPrice
		FROM INSERTED;
	END
END;

-- 8
CREATE TRIGGER trg_CheckLastUnit
ON Products
AFTER UPDATE
AS
BEGIN
	INSERT INTO LastUnitProducts (ProductID, Name, Type, QuantityInStock, CostPrice, Manufacturer, SellingPrice)
    SELECT P.ProductID, P.Name, P.Type, P.QuantityInStock, P.CostPrice, P.Manufacturer, P.SellingPrice
    FROM Products P
	INNER JOIN INSERTED I ON P.ProductID = I.ProductID
	WHERE I.QuantityInStock = 1;
END


-- TEST TRIGGERS

-- 1
INSERT INTO Sales (ProductID, SellingPrice, Quantity, SaleDate, EmployeeID, ClientID)
VALUES (1, 80.00, 2, '2023-10-05', 1, 1);

SELECT * FROM SalesHistory;

-- 2
UPDATE Products
SET QuantityInStock = 0
WHERE ProductID = 1;

SELECT * FROM ArchivedProducts;

-- 3
INSERT INTO Clients (FullName, Email, Phone, Gender, OrderHistory, DiscountPercentage, IsSubscribed)
VALUES ('Alice Johnson', 'alice@example.com', '123-456-7890', 'Female', 'Running Shoes', 10.00, 1);

-- 4
DELETE FROM Clients WHERE ClientID = 1;

-- 5
DELETE FROM Employees WHERE EmployeeID = 1;

-- 6
INSERT INTO Sales (ProductID, SellingPrice, Quantity, SaleDate, EmployeeID, ClientID)
VALUES (2, 50.00, 1000, '2023-10-06', 2, 2);

SELECT * FROM Clients WHERE ClientID = 2;

-- 7
INSERT INTO Products (Name, Type, QuantityInStock, CostPrice, Manufacturer, SellingPrice)
VALUES ('Test Product', 'Test Type', 10, 10.00, 'Спорт, сонце та штанга', 20.00);

-- 8
UPDATE Products
SET QuantityInStock = 1
WHERE ProductID = 2;

SELECT * FROM LastUnitProducts;


-- deleting db

DROP TABLE SalesHistory;
DROP TABLE LastUnitProducts;
DROP TABLE ArchivedProducts;
DROP TABLE Sales;
DROP TABLE Clients;
DROP TABLE Employees;
DROP TABLE Products;


USE master;
DROP DATABASE SportShop;