CREATE DATABASE SportShop;
USE SportShop;

CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(100) NOT NULL,
    Quantity INT NOT NULL,
    Price DECIMAL(10, 2) NOT NULL
);

CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeName NVARCHAR(100) NOT NULL,
    Position NVARCHAR(50) NOT NULL,
    HireDate DATE NOT NULL,
    DismissalDate DATE
);

CREATE TABLE ArchivedEmployees (
    EmployeeID INT PRIMARY KEY,
    EmployeeName NVARCHAR(100) NOT NULL,
    Position NVARCHAR(50) NOT NULL,
    HireDate DATE NOT NULL,
    DismissalDate DATE
);

CREATE TABLE Sellers (
    SellerID INT PRIMARY KEY IDENTITY(1,1),
    SellerName NVARCHAR(100) NOT NULL
);

-- INSERTING

INSERT INTO Products (ProductName, Quantity, Price)
VALUES 
('Football', 10, 500.00),
('Basketball', 5, 700.00),
('Tennis Racket', 8, 1200.00);

INSERT INTO Employees (EmployeeName, Position, HireDate, DismissalDate)
VALUES 
('Ivan Petrov', 'Manager', '2020-01-15', NULL),
('Olena Sidorova', 'Salesperson', '2021-03-10', NULL),
('Vasyl Ivanov', 'Salesperson', '2019-11-20', '2023-01-01');

INSERT INTO Sellers (SellerName)
VALUES 
('Olena Sidorova'),
('Vasyl Ivanov'),
('Maria Koval'),
('Oleg Pavlov'),
('Natalia Lysenko'),
('Dmytro Shevchenko');

-- SELECTING TRIGGERS

CREATE TRIGGER trg_UpdateProductQuantity
ON Products
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Products p INNER JOIN inserted i ON p.ProductName = i.ProductName AND p.Price = i.Price)
    BEGIN
        UPDATE p
        SET p.Quantity = p.Quantity + i.Quantity
        FROM Products p
        INNER JOIN inserted i ON p.ProductName = i.ProductName AND p.Price = i.Price;
    END
    ELSE
    BEGIN
        INSERT INTO Products (ProductName, Quantity, Price)
        SELECT ProductName, Quantity, Price FROM inserted;
    END
END;

CREATE TRIGGER trg_ArchiveEmployee
ON Employees
AFTER UPDATE
AS
BEGIN
    IF UPDATE(DismissalDate)
    BEGIN
        INSERT INTO ArchivedEmployees (EmployeeID, EmployeeName, Position, HireDate, DismissalDate)
        SELECT EmployeeID, EmployeeName, Position, HireDate, DismissalDate
        FROM inserted
        WHERE DismissalDate IS NOT NULL;
    END
END;

CREATE TRIGGER trg_CheckSellerCount
ON Sellers
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @SellerCount INT;
    SELECT @SellerCount = COUNT(*) FROM Sellers;

    IF @SellerCount >= 6
    BEGIN
        RAISERROR('The number of sellers cannot exceed 6', 0, 1);
        ROLLBACK;
    END
    ELSE
    BEGIN
        INSERT INTO Sellers (SellerName)
        SELECT SellerName FROM inserted;
    END
END;

-- TEST TRIGGERS

INSERT INTO Products (ProductName, Quantity, Price)
VALUES ('Laptop', 15, 500);

UPDATE Employees
SET DismissalDate = GETDATE()
WHERE EmployeeID = 1;

INSERT INTO Sellers (SellerName)
VALUES ('David Seller');

-- deleting db

DROP TABLE Sellers;
DROP TABLE Employees;
DROP TABLE Products;
DROP TABLE ArchivedEmployees;


USE master;
DROP DATABASE SportShop;