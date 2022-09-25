use Northwind_DW
go
-----------------------------------------for Product Dim--------------------------------------------------------------------

Create Function Fn_avg_product(@productID int)
returns nvarchar(20)
As 
Begin 
Declare 
@avg float,
@Y int,
@A nvarchar(20)

set @avg = (select avg(unitprice) from NORTHWND.dbo.Products)
set @Y = (select UnitPrice from NORTHWND.dbo.Products where ProductID = @productID)
    if @Y >= @avg
       set @A = 'Expensive'

       else
           set @A = 'Cheap'
return @A
end

-------------------------------------------for Dim Date------------------------------------------------------------------

create function fn_date(@start_day date, @last_day date)
returns @DDate TABLE ([DATE] date)
as
begin

while @start_day <= @last_day
      begin
      insert into @DDate([DATE])
      values(@start_day)
      set @start_day = dateadd(dd,1,@start_day)
	  end
return
end

--------------------------------------------------procedure-------------------------------------------------------

create procedure [Tables]
as
begin 

IF OBJECT_ID('dbo.Dim_Date') IS not NULL
   BEGIN
   PRINT 'The Table Dim_Date is already exists.'
   END
else
   BEGIN
   create table Dim_Date(DateKey int, [Date] Date, [Year] int, [Quarter] int, [Month] int, [MonthName] nvarchar(20))
   insert into Dim_Date
   select 
		cast(format(DATE,'yyyyMMdd') as int) as DateKey, 
		[DATE] as [Date],
		year(DATE) as [year],
		DATEPART(QUARTER,[DATE]) as [Quarter],
		month(DATE) as [Month],
		DATENAME(month,DATE) as [MonthName]
    from dbo.fn_date('1996-01-01', '1999-12-31')
	END


if EXISTS(select count(*) from Dim_Customers having count(*) = 0)
   BEGIN
   insert into Dim_Customers(CustomerBK, CustomerName, city, Region, Country)
   select CustomerID, CompanyName, City, isnull(Region, 'UnKnow'), Country
   from NORTHWND.dbo.Customers
   END
ELSE
   BEGIN
   PRINT 'The Table Dim_Customers is already exists.'
   END


if EXISTS(select count(*) from Dim_Employees having count(*) = 0)
   BEGIN
   insert into Dim_Employees(EmployeeBK, LastName, FirstName, FullName, Title, BirthDate, age, HireDate, Seniority, City, Country, Photo, ReportsTo)
   select EmployeeID, LastName, FirstName,FirstName + ' ' + LastName as FullName, Title, BirthDate, ceiling(round(datediff(d,BirthDate, getdate())/365.00, 0)) as age, HireDate, ceiling(round(datediff(d,HireDate, getdate())/365.00, 0)) as Seniority, City, Country, Photo, ReportsTo
   from NORTHWND.dbo.Employees
   END
ELSE
   BEGIN
   PRINT 'The Table Dim_Employees is already exists.'
   END


if EXISTS(select count(*) from Dim_Orders having count(*) = 0)
   BEGIN
   insert into Dim_Orders(OrderBK, ShipCity, ShipRegion, ShipCountry)
   select OrderID, ShipCity, isnull(ShipRegion, 'UnKnow'), ShipCountry
   from NORTHWND.dbo.Orders
   END
ELSE
   BEGIN
   PRINT 'The Table Dim_Orders is already exists.'
   END


if EXISTS(select count(*) from Dim_Products having count(*) = 0)
   BEGIN
   insert into Dim_Products(ProductBK, ProductName, ProductUnitPrice, ProductType, Discontinued, CategoryName, SupplierName)
   select P.ProductID, P.ProductName, MAX(OD.UnitPrice) AS ProductUnitPrice, dbo.Fn_avg_product(P.ProductID) as ProductType, P.Discontinued, C.CategoryName, S.CompanyName
   from NORTHWND.dbo.Products [P] left join NORTHWND.dbo.Categories [C]  
   on C.CategoryID = P.CategoryID
   join NORTHWND.dbo.Suppliers [S]
   on S.SupplierID = P.SupplierID
   join NORTHWND.dbo.[Order Details] [OD]
   on P.ProductID = OD.ProductID
   group by p.ProductID, P.ProductName, dbo.Fn_avg_product(P.ProductID), P.Discontinued, C.CategoryName, s.CompanyName
   order by P.ProductID
   END
ELSE
   BEGIN
   PRINT 'The Table Dim_Products is already exists.'
   END


if EXISTS(select count(*) from Fact_Sales having count(*) = 0)
   BEGIN
   insert into Fact_Sales(OrderSK, ProductSK, DateKey, CustomerSK, EmployeeSK, UnitPrice, Quantity, Discount)
   select distinct(DO.OrderSK), DP.productSK, DD.DateKey, DC.CustomerSK, DE.EmployeeSK, OD.UnitPrice, OD.Quantity, OD.Discount
   from NORTHWND.dbo.Orders [O] LEFT JOIN Dim_Customers [DC]
   ON DC.CustomerBK = O.CustomerID
   JOIN NORTHWND.dbo.[Order Details] [OD]
   on O.OrderID = OD.OrderID
   LEFT JOIN Dim_Employees [DE]
   ON O.EmployeeID = DE.EmployeeBK
   LEFT JOIN Dim_Orders [DO]
   on DO.OrderBK = OD.OrderID
   LEFT JOIN Dim_Products [DP]
   ON OD.ProductID = DP.ProductBK
   LEFT JOIN Dim_Date [DD]
   on O.OrderDate = DD.Date
   END
ELSE
   BEGIN
   PRINT 'The Table Fact_Sales is already exists.'
   END

end
---------------------------------------------------------------------------------------------------------------------------
Exec [Tables]