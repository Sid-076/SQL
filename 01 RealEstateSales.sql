/* First Basic Sql Excercise

Cleaning Dataset to remove unwanted columns and exploring data to get insights using aggregate functions and cte

*/



--Cleaning Dataset
--Rename Columns 
sp_rename 'RealEstateSales.[Serial Number]','Id'
sp_rename 'RealEstateSales.[List Year]','YearListed'
sp_rename 'RealEstateSales.[Assessed Value]','AssessedVal'
sp_rename 'RealEstateSales.[Sale Amount]','SalesAmount'
sp_rename 'RealEstateSales.[Sales Ratio]','SaleRatio'
sp_rename 'RealEstateSales.[Property Type]','PropType'
sp_rename 'RealEstateSales.[Residential Type]','ResType'


--Dropping unwanted columns
Alter Table RealEstateSales
Drop Column [Date Recorded],[F11],[F12]

Alter Table RealEstateSales
Drop Column PropType,ResType


--Maximum, Minimum, Average and Total sales each year of every Town
Select Town,YearListed,Min(SalesAmount) MinSaleAmount,Max(SalesAmount) MaxSaleAmount,Round(Avg(SalesAmount),2) AvgSales,Sum(SalesAmount) TotalSales
From RealEstateSales
Group By Town,YearListed
Order By Town,YearListed


--Total number of sold properties,maximum and minimum sale amount and average sale amount in each town by type of Property
Select Town,PropType,Count(SalesAmount) NumofSales,Min(SalesAmount) MinSaleAmt,Max(SalesAmount) MaxSaleAmt,Round(Avg(SalesAmount),2) AvgSaleAmt
From RealEstateSales
Group By Town,PropType
Order By Town,PropType


--Number of unsold Properties in each Town
Select Town,Count(SalesAmount) Unsold
From RealEstateSales
Where SalesAmount =0
Group By Town
Order By Unsold Desc


--Properties with more than 100% loss using CTE
With PercentProfit as(
Select *,Round((SalesAmount-AssessedVal)/SalesAmount*100,2) PercentageProfit
From RealEstateSales
Where SalesAmount <> 0
)
Select Town,Address,AssessedVal,SalesAmount,PercentageProfit
From PercentProfit
Where PercentageProfit <-100
Order By PercentageProfit

Select * 
From RealEstateSales
Where SalesAmount = 0

