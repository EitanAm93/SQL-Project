/*
Data Panel
All the tables and fields that were used in the analysis in the project.
*/
select h.OrderDate
		,h.SubTotal
		,d.LineTotal
		,d.OrderQty
		,UnitPrice
		,p.[Name]
		,p.Color
		,ps.[Name]
from Sales.SalesOrderHeader as h
	 join Sales.SalesOrderDetail as d
	 on h.SalesOrderID = d.SalesOrderID
	 join Production.Product as p
	 on d.ProductID = p.ProductID
	 join Production.ProductSubcategory as ps
	 on p.ProductSubcategoryID = ps.ProductSubcategoryID
	 


/*
================================
			  Q1
================================

The following queries is to check if there is seasonality between the years 
based on the time periods and the sum of the subtotals. 
*/


/*
In this query we tried to check if there is a seasonality by ranking the months of each year
with dense_rank.
We concluded that there were no seasonality.
*/


with SubTotalYears 
		as (
				select  MONTH(OrderDate) as 'MonthDate'
						,datename(MM,OrderDate) 'MonthDateName'
						,sum(case when year(orderdate) =2011 then SubTotal else 0 end) as 'SumSubTotal2011'
						,sum(case when year(orderdate) =2012 then SubTotal else 0 end) as 'SumSubTotal2012'
						,sum(case when year(orderdate) =2013 then SubTotal else 0 end) as 'SumSubTotal2013'
						,sum(case when year(orderdate) =2014 then SubTotal else 0 end) as 'SumSubTotal2014'
				from Sales.SalesOrderHeader
				group by MONTH(OrderDate),datename(MM,OrderDate) 
			),
RankMonth 
		 as (
				select MonthDate
					   ,MonthDateName
					   ,format(SumSubTotal2011,'#,#') as 'SumSubTotal2011'
					   ,format(case when SumSubTotal2011 = 0 then 0 else dense_rank () over (order by sumSubTotal2011 desc) end,'#,#') as Rank2011
					   ,format(SumSubTotal2012,'#,#') as 'SumSubTotal2012'
					   ,format(case when SumSubTotal2012 = 0 then 0 else dense_rank () over (order by sumSubTotal2012 desc) end,'#,#') as Rank2012
					   ,format(SumSubTotal2013,'#,#') as 'SumSubTotal2013'
					   ,format(case when SumSubTotal2013 = 0 then 0 else dense_rank () over (order by sumSubTotal2013 desc) end,'#,#') as Rank2013
					   ,format(SumSubTotal2014,'#,#') as 'SumSubTotal2014'
					   ,format(case when SumSubTotal2014 = 0 then 0 else dense_rank () over (order by sumSubTotal2014 desc) end,'#,#') as Rank2014
				from SubTotalYears
              )
select *
from RankMonth 
order by MonthDate



/*
In this query we tried to check if there is a seasonality by ranking the months of each year
with dividing it into 4 groups using NTILE.
We concluded that there were no seasonality.
*/
with SubTotalYears 
		as (
				select  MONTH(OrderDate) as 'MonthDate'
				        ,datename(MM,OrderDate) 'MonthDateName'
						,sum(case when year(orderdate) =2011 then SubTotal else 0 end) as 'SumSubTotal2011'
						,sum(case when year(orderdate) =2012 then SubTotal else 0 end) as 'SumSubTotal2012'
						,sum(case when year(orderdate) =2013 then SubTotal else 0 end) as 'SumSubTotal2013'
						,sum(case when year(orderdate) =2014 then SubTotal else 0 end) as 'SumSubTotal2014'
				from Sales.SalesOrderHeader
				group by MONTH(OrderDate),datename(MM,OrderDate)
			),
RankMonth 
		 as (
				select MonthDate
				       ,MonthDateName
			           ,format(SumSubTotal2011,'#,#') as 'SumSubTotal2011'
					   ,format(case when SumSubTotal2011 = 0 then 0 else NTILE (4) over (order by sumSubTotal2011 desc) end,'#,#') as Rank2011
					   ,format(SumSubTotal2012,'#,#') as 'SumSubTotal2012'
					   ,NTILE (4)  over (order by sumSubTotal2012 desc) as Rank2012
					   ,format(SumSubTotal2013,'#,#') as 'SumSubTotal2013'
					   ,NTILE (4)  over (order by sumSubTotal2013 desc) as Rank2013
					   ,format(SumSubTotal2014,'#,#') as 'SumSubTotal2014'
					   ,format(case when SumSubTotal2014 = 0 then 0 else NTILE (4) over (order by sumSubTotal2014 desc) end,'#,#') as Rank2014
				from SubTotalYears
              )
select *
from RankMonth 
order by MonthDate



/*
================================
			  Q2
================================
*/


/*
In the following query we checked if there is any upward or downward trend in the
company's revenues according to successive months over the years.
Result: There is no upward or downward trend.
*/

with Sales_per_Year_Month
       as (
			select year(OrderDate) as 'YearDate'
					,month(OrderDate) as 'MonthDate'
					,sum(SubTotal) as 'TotalRev'
					,dense_rank() over(partition by year(OrderDate) order by sum(SubTotal) desc) as 'Rank_Revenue_Per_Month'
					,lag (sum(SubTotal)) over (order by year(OrderDate),month(OrderDate)) as 'lagMonthsSubtotal'
			from Sales.SalesOrderHeader
			group by year(OrderDate), month(OrderDate)

         )

select YearDate
	   ,Monthdate
	   ,format(TotalRev,'#,#') as 'TotalRev'
	   ,format((TotalRev-lagMonthsSubtotal)/lagMonthsSubtotal,'p') as 'TrendMonths'
From Sales_per_Year_Month ;



/*
In the following query we checked if there is any upward or downward trend in the company's revenues
based on a comparison of one month of the year to the same month in the other years.
Result: There is no upward or downward trend
*/
with Sum_SubTotal_Month_Per_Year
		as (
				select month(OrderDate) as 'MonthDate'
						,DATENAME(MM,OrderDate) as 'MonthDateName'
						,sum(case when year(OrderDate) = 2011 then SubTotal end) as 'SumSubTotal2011'
						,sum(case when year(OrderDate) = 2012 then SubTotal end) as 'SumSubTotal2012'
						,sum(case when year(OrderDate) = 2013 then SubTotal end) as 'SumSubTotal2013'
						,sum(case when year(OrderDate) = 2014 then SubTotal end) as 'SumSubTotal2014'
				from Sales.SalesOrderHeader
				group by month(OrderDate), DATENAME(MM,OrderDate)
			),

	 Sum_SubTotal_Month_Per_Year_Diff
		as
			(
			select *
					,SumSubTotal2012 - SumSubTotal2011 as 'Diff2011-2012'
					,SumSubTotal2013 - SumSubTotal2012 as 'Diff2012-2013'
					,SumSubTotal2014 - SumSubTotal2013 as 'Diff2013-2014'
			from Sum_SubTotal_Month_Per_Year
			)

select MonthDate
		,MonthDateName
		,format([Diff2011-2012]/SumSubTotal2011,'p') as 'Trend2011-2012'
		,format([Diff2012-2013]/SumSubTotal2012,'p') as 'Trend2012-2013'
		,format([Diff2013-2014]/SumSubTotal2013,'p') as 'Trend2013-2014'
from Sum_SubTotal_Month_Per_Year_Diff
order by MonthDate


/*
================================
			  Q3
================================
*/



/*
==================================
Product type effect on the profit
==================================
*/

--Sum of profit earned and amount sold by SubCategory Name level (in all of the life of the company)
select ps.[Name] as 'SubCategoryName'
		,sum(d.LineTotal - d.OrderQty * p.StandardCost) as 'TotalProfit'
		,sum(d.OrderQty) 'QuantitySold'
from Sales.SalesOrderDetail as d
	 join Production.Product as p
		on d.ProductID = p.ProductID
	 join Production.ProductSubcategory as ps
		on p.ProductSubcategoryID = ps.ProductSubcategoryID
group by ps.[Name]
order by TotalProfit desc

--Top 10 of the most profitable products (in all of the life of the company)
select top 10 ps.[Name] as 'SubCategoryName'
		,sum(d.LineTotal - d.OrderQty * p.StandardCost) as 'TotalProfit'
from Sales.SalesOrderDetail as d
	 join Production.Product as p
		on d.ProductID = p.ProductID
	 join Production.ProductSubcategory as ps
		on p.ProductSubcategoryID = ps.ProductSubcategoryID
group by ps.[Name]
order by TotalProfit desc

--List of products that made the company lose money (in all of the life of the company)
select ps.[Name] as 'SubCategoryName'
		,sum(d.LineTotal - d.OrderQty * p.StandardCost) as 'TotalProfit'
from Sales.SalesOrderDetail as d
	 join Production.Product as p
		on d.ProductID = p.ProductID
	 join Production.ProductSubcategory as ps
		on p.ProductSubcategoryID = ps.ProductSubcategoryID
group by ps.[Name]
having sum(d.LineTotal - d.OrderQty * p.StandardCost) < 0
order by TotalProfit


/*
It can be seen in the query below that the products that caused a lost for the company,
where mostly sold with a price that was under its cost or with a price that was just a little 
bit higher which as a result caused the lost of money.
*/

with UnprofitProducts
		as (
				select ps.[Name] as 'SubCategoryName'
						,sum(d.LineTotal - d.OrderQty * p.StandardCost) as 'TotalProfit'
				from Sales.SalesOrderDetail as d
					 join Production.Product as p
						on d.ProductID = p.ProductID
					 join Production.ProductSubcategory as ps
						on p.ProductSubcategoryID = ps.ProductSubcategoryID
				group by ps.[Name]
				having sum(d.LineTotal - d.OrderQty * p.StandardCost) < 0		
		   )

			select ps.[Name] as 'SubCategoryName'
					,p.[Name] as 'ProductName'
					,p.Color
					,d.LineTotal
					,d.OrderQty
					,p.StandardCost
					,d.UnitPrice
					,d.LineTotal/d.OrderQty - p.StandardCost as 'ProfitLosePerUnitPrice'
					,sum(d.LineTotal/d.OrderQty - p.StandardCost) over(partition by p.Color) as 'SumColor'	
			from Sales.SalesOrderDetail as d
				 join Production.Product as p
					on d.ProductID = p.ProductID
				 join Production.ProductSubcategory as ps
					on p.ProductSubcategoryID = ps.ProductSubcategoryID
				 join UnprofitProducts as up
					on ps.[Name] = up.SubCategoryName
					order by ProfitLosePerUnitPrice
			
/*
In the query below we checked for each sub category product and color if there were products that
were not profitable at all, i.e they always have a lost per unit price.
Result - for the following sub category product and color there were always lost per unit price: 
Road Frames	- Black
Road Frames - Yellow
*/


with UnprofitProducts
		as (
				select ps.[Name] as 'SubCategoryName'
						,sum(d.LineTotal - d.OrderQty * p.StandardCost) as 'TotalProfit'
				from Sales.SalesOrderDetail as d
					 join Production.Product as p
						on d.ProductID = p.ProductID
					 join Production.ProductSubcategory as ps
						on p.ProductSubcategoryID = ps.ProductSubcategoryID
				group by ps.[Name]
				having sum(d.LineTotal - d.OrderQty * p.StandardCost) < 0		
		   ),

	 UnprofitProductsDetails
		as(
			select ps.[Name] as 'SubCategoryName'
					,p.[Name] as 'ProductName'
					,p.Color
					,d.LineTotal
					,d.OrderQty
					,p.StandardCost
					,d.UnitPrice
					,d.LineTotal/d.OrderQty - p.StandardCost as 'ProfitLosePerUnitPrice'
					,sum(d.LineTotal/d.OrderQty - p.StandardCost) over(partition by p.Color) as 'SumColor'	
			from Sales.SalesOrderDetail as d
				 join Production.Product as p
					on d.ProductID = p.ProductID
				 join Production.ProductSubcategory as ps
					on p.ProductSubcategoryID = ps.ProductSubcategoryID
				 join UnprofitProducts as up
					on ps.[Name] = up.SubCategoryName
		 )

select SubCategoryName
		,Color
		,(	select case when COUNT (*) > 0 then 'Yes' else 'No' end
			from  UnprofitProductsDetails as upd_in
			where upd_in.SubCategoryName = upd_out.SubCategoryName
				  and upd_in.Color = upd_out.Color
				  and upd_in.ProfitLosePerUnitPrice >= 0) as 'FlagLostProfit'
from UnprofitProductsDetails as upd_out
group by SubCategoryName, Color












