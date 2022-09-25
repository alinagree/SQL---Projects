use NORTHWND
go

CREATE VIEW vw_getRANDValue
AS
SELECT RAND() AS Value

Create function fn_Random (@n1 int, @n2 int)
returns int
As
Begin

Declare @res int
Set @res = (Select * From vw_getRANDValue) * (@n1 - @n2 + 1) + @n2
return @res

End

create procedure proc_orders
@HMO int,
@HowManyOrderdetailsMin	int,
@HowManyOrderdetailsMax int
as
Declare
@I int = 1,
@customerID nvarchar(10),
@employeeID int,
@productID int,
@rand_max_min int,
@M int = 1,
@oid int

-----****----
while @HMO >= @I
begin


set @customerID = (select top 1 CustomerID
                   from Customers
			       order by newid())

set @employeeID = (select top 1 EmployeeID
                   from Employees	
			       order by newid())


insert into Orders (CustomerID, EmployeeID, OrderDate)
values(@customerID, @employeeID, Getdate())

set @oid = (Select OrderID From Orders where OrderID = IDENT_CURRENT('orders'))

set @rand_max_min = (select dbo.fn_Random(@HowManyOrderdetailsMin,@HowManyOrderdetailsMax))
set @M = 1
    while @rand_max_min >= @M
    begin
    set @productID = (Select top 1 Productid 
				      from (select Productid 
				            from Products 
						    where Productid not in (select ProductID from [Order Details] Where OrderID = IDENT_CURRENT('orders'))) mewoo
                      order by newid())
																					
    insert into [Order Details] 
    values(@oid,@productID,(Select UnitPrice from Products where ProductID = @productID),(select dbo.fn_Random(1,10)), RAND())
    set @M = @M + 1
    end

set @I = @I + 1
end
-------------
Exec proc_orders
@HMO = 10,
@HowManyOrderdetailsMin = 1,
@HowManyOrderdetailsMax = 4
-------------
select * from [Order Details]
select * from Orders


drop procedure proc_orders 