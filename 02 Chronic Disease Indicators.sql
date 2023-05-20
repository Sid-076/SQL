/* SQL Project to analyse trends in chronic diseases in U.S.

Skills used : Data Preprocessing, Aggregate Functions, SubQueries, Temp Tables, CTEs,Window Functions

*/


--Removing Unnecessary columns
ALTER TABLE CDI
DROP COLUMN LocationAbbr,Question,Response,DataValueAlt,LocationID,TopicID


--Converting Data Types
ALTER TABLE CDI
ADD YearStart DATE;

UPDATE CDI
SET YearReported = CASE 
					WHEN ISDATE(CAST(CAST(YearStart AS INT) AS VARCHAR(8))) = 1
					THEN CAST(CAST(CAST(YearStart AS INT) AS VARCHAR(8)) AS DATETIME)
				   END

ALTER TABLE CDI
DROP COLUMN YearStart


--Handling Missing Values
UPDATE CDI
SET DataValue = 0
WHERE DataValue IS NULL


--Data Distribution for all diseases
SELECT Disease,MIN(DataValue) MinDataValue,MAX(DataValue) MaxDataValue,ROUND(AVG(DataValue),2) AvgDataValue
FROM CDI
GROUP BY Disease
ORDER BY AvgDataValue DESC


--TOP 10 locations with Highest values for Diabetes
SELECT TOP 10 LocationDesc,DataValue
FROM CDI
WHERE Disease = 'Diabetes'
ORDER BY DataValue DESC


--Data Values across different stratifications for Cardiovascular Disease
SELECT Strat,ROUND(AVG(DataValue),2) AvgDataValue
FROM CDI
WHERE Disease = 'Cardiovascular Disease'
GROUP BY Strat
ORDER BY AvgDataValue DESC


--Disease with Highest data value
SELECT TOP 1 Disease,SUM(DataValue) TotalDataVal
FROM CDI
GROUP BY Disease
ORDER BY TotalDataVal DESC


--Year-wise data distribution for Cancer 
SELECT YEAR(YearReported) Year,ROUND(AVG(DataValue),2) AvgDataVal
FROM CDI
WHERE Disease = 'Cancer'
GROUP BY YearReported
ORDER BY YearReported


--Find locations with highest data value for each disease
WITH MaxDataValues AS(
 SELECT Disease,MAX(DataValue) AS MaxVal
 FROM CDI
 GROUP BY Disease
)
SELECT CDI.Disease,CDI.LocationDesc,CDI.DataValue
FROM CDI
INNER JOIN MaxDataValues mdv
ON CDI.Disease = mdv.Disease AND CDI.DataValue = mdv.MaxVal


--Average data value for each year, for every stratification
WITH YearlyAvgData AS (
  SELECT YEAR(YearReported) YearReported,Strat,ROUND(AVG(DataValue),2) AvgDataVal
  FROM CDI
  GROUP BY YearReported,Strat
)
SELECT yad.Strat,yad.YearReported,yad.AvgDataVal
FROM YearlyAvgData yad
ORDER BY yad.Strat,yad.YearReported



--Number of instances with data values higher than average data values across all diseases
WITH AvgDataVal As (
   SELECT ROUND(AVG(DataValue),2) AvgData
   FROM CDI
)
SELECT Disease,COUNT(DataValue) TotalNum
FROM CDI
WHERE DataValue > (SELECT AvgData FROM AvgDataVal)
GROUP BY Disease
ORDER BY TotalNum DESC


--Diseases with highest value for each location and year
SELECT CDI.LocationDesc,YEAR(CDI.YearReported) Year,CDI.Disease,CDI.DataValue
FROM CDI
INNER JOIN(
	SELECT LocationDesc,YearReported,MAX(DataValue) MaxVal
	FROM CDI
	GROUP BY LocationDesc,YearReported
) M ON CDI.LocationDesc = M.LocationDesc AND CDI.YearReported = M.YearReported AND CDI.DataValue = M.MaxVal



--Cumulative data values for each year
DROP TABLE IF EXISTS #TempTable
CREATE TABLE #TempTable (
    YearStart DATE,
    CumulativeDataVal FLOAT
);

WITH CumulativeData AS(
	SELECT TOP 1000 YearReported,DataValue,ROW_NUMBER() OVER(ORDER BY YearReported) RowNum
	FROM CDI
)
INSERT INTO  #TempTable (YearStart,CumulativeDataVal)
SELECT c1.YearReported,SUM(c2.DataValue) CumulativeVal
FROM CumulativeData c1
JOIN CumulativeData c2 ON c1.RowNum >= c2.RowNum
GROUP BY c1.YearReported

SELECT YearStart,ROUND(CumulativeDataVal,2)
FROM #TempTable
ORDER BY YearStart



--Year-wise sum and percenage contribution of data for each disease
SELECT YearReported,Disease,SUM(DataValue) TotalDataVal,
		ROUND(SUM(DataValue)*100/SUM(SUM(DataValue)) OVER (PARTITION BY YearReported),2) ContributionPercentage
FROM CDI
GROUP BY YearReported,Disease
ORDER BY YearReported



--Calculate moving average of data values over a specific window for each disease
SELECT YearReported,Disease,DataValue,
		ROUND(AVG(DataValue) OVER (PARTITION BY Disease ORDER BY YearReported ROWS BETWEEN 1000 PRECEDING AND CURRENT ROW),2) MovingAvg
FROM CDI
ORDER BY Disease



--Over the year growth rate of data values for each disease
SELECT Disease,YEAR(YearReported),DataValue,
		ROUND((DataValue - LAG(DataValue) OVER (
			PARTITION BY Disease ORDER BY YearReported))/LAG(DataValue) OVER (
				PARTITION BY Disease ORDER BY YearReported),2) GrowthRate
FROM CDI
WHERE DataValue<>0 
ORDER BY Disease,YearReported

