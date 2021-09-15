-- ###### DATA EXPLORATION IN SQL ###### --

-- DATE SOURCE: https://data.gov.uk/dataset/cb7ae6f0-4be6-4935-9277-47e5ce24a11f/road-safety-data


--#########################################################


-- Comparing number of accidents by day of the week (T)

SELECT Day_of_Week, COUNT(*) AS Number_of_Accidents
FROM accidents
GROUP BY Day_of_Week
ORDER BY CASE WHEN Day_of_Week = 'Monday' THEN '1'
			  WHEN Day_of_Week = 'Tuesday' THEN '2'
			  WHEN Day_of_Week = 'Wednesday' THEN '3'
			  WHEN Day_of_Week = 'Thursday' THEN '4'
			  WHEN Day_of_Week = 'Friday' THEN '5'
			  WHEN Day_of_Week = 'Saturday' THEN '6'
			  WHEN Day_of_Week = 'Sunday' THEN '7'
		 END ASC;


--#########################################################


-- Proportion of accidents which were fatal (T)

SELECT Accident_Severity, 
	   COUNT(*) AS Number_of_Accidents, 
	   CAST(ROUND(COUNT(*) * 100.00/ (SELECT COUNT(*) FROM accidents), 2) AS DECIMAL (5,2)) As Proportion
FROM 
accidents
GROUP BY Accident_Severity;


--#########################################################


-- Comparing number of accidents by speed limit

SELECT Speed_Limit, COUNT(*) FROM accidents 
WHERE Speed_Limit IS NOT NULL
AND Speed_Limit <> 0
GROUP BY Speed_Limit
ORDER BY Speed_Limit;


--#########################################################


-- Number of casualties who were pedestrians

SELECT COUNT(*) AS Number_of_Casualties,
	   CASE
			WHEN Casualty_Class ='Pedestrian' THEN 'Pedestrian'
			ELSE 'Not a Pedestrian'
	   END AS Casualty_Type
FROM casualties
GROUP BY CASE
			WHEN Casualty_Class ='Pedestrian' THEN 'Pedestrian'
			ELSE 'Not a Pedestrian'
	   END;


-- We can obtain the same output as the above query with the following

SELECT COUNT(*) AS Number_of_Casualties, Casualty_Type
FROM (
	SELECT
	   CASE
			WHEN Casualty_Class ='Pedestrian' THEN 'Pedestrian'
			ELSE 'Not a Pedestrian'
	   END AS Casualty_Type
    FROM casualties
	) AS subquery  
GROUP BY Casualty_type ;


--#########################################################


-- Pedestrian casualty circumstances

SELECT Pedestrian_Movement,
	   COUNT(*) AS Number_of_Casualties FROM casualties
WHERE 
	Pedestrian_Movement <> 'Not a Pedestrian'
GROUP BY 
	Pedestrian_Movement
ORDER BY 
	COUNT(*);


--#########################################################


-- Casualty severity of pedestrians and non-pedestrians compared (T)

SELECT COUNT(*) AS Number_of_Casualties,
	   Casualty_Severity,
	   CASE 
			WHEN Casualty_Class ='Pedestrian' THEN 'Pedestrian'
			ELSE 'Not a Pedestrian'
	   END AS Casualty_Type
FROM casualties
GROUP BY CASE
			WHEN Casualty_Class ='Pedestrian' THEN 'Pedestrian'
			ELSE 'Not a Pedestrian'
	   END, 
	   Casualty_Severity
ORDER BY
	Casualty_Type, Casualty_Severity;


--#########################################################


-- A breakdown between male and female casualties (each year)

SELECT TOP 50 YEAR(a.Date) AS Calender_Year,
	   c.Sex_of_Casualty,
	   COUNT(*) AS Number_of_Casualties
FROM
	accidents a
		JOIN
	casualties c ON a.Accident_Index = c.Accident_Index
WHERE c.Sex_of_Casualty <> 'Data missing or out of range'
GROUP BY (YEAR(a.Date)),c.Sex_of_Casualty
ORDER BY YEAR(a.Date);


-- A breakdown between male and female casualties (each month)

SELECT
	YEAR(a.Date) AS Calender_Year,
	MONTH(a.Date) AS Month,
	c.Sex_of_Casualty,
	COUNT(*) AS Number_of_Casualties
FROM
	accidents a
		JOIN
	casualties c ON a.Accident_Index = c.Accident_Index
WHERE c.Sex_of_Casualty <> 'Data missing or out of range'
GROUP BY YEAR(a.Date),MONTH(a.Date),c.Sex_of_Casualty
ORDER BY YEAR(a.Date),MONTH(a.Date);


-- A breakdown of Male and Female Casualties (each day) (T)

SELECT
	date,
	c.Sex_of_Casualty,
	COUNT(*) AS Number_of_Casualties
FROM
	accidents a
		JOIN
	casualties c ON a.Accident_Index = c.Accident_Index
WHERE c.Sex_of_Casualty <> 'Data missing or out of range'
GROUP BY date ,c.Sex_of_Casualty
ORDER BY date;


--#########################################################


-- Male vs Female Drivers Involved in Accidents


-- Summary

SELECT
	v.Sex_of_Driver,
	COUNT(a.Accident_Index)
FROM
	accidents a
		JOIN
	vehicles v ON a.Accident_Index = v.Accident_Index
WHERE v.Sex_of_Driver <> 'Data missing or out of range'
GROUP BY v.Sex_of_Driver
;


-- Daily Numbers

SELECT
	date,
	v.sex_of_driver,
	COUNT(a.Accident_Index) AS number_of_accidents
FROM
	accidents a
		JOIN
	vehicles v ON a.Accident_Index = v.Accident_Index
WHERE v.Sex_of_Driver <> 'Data missing or out of range'
GROUP BY date,v.Sex_of_Driver
ORDER BY date
;


--#########################################################


-- A breakdown of the number male and female drivers involved in accidents within a particular range of speed limits.

CREATE PROCEDURE sp_speed_limits @p_lower INTEGER, @p_higher INTEGER
AS
BEGIN
	SELECT 
		v.Sex_of_Driver,
		COUNT(*) AS Number_of_Accidents
	FROM
		accidents a
			JOIN
		vehicles v ON a.Accident_Index = v.Accident_Index
	WHERE 
		a.Speed_limit BETWEEN @p_lower AND @p_higher
	AND
		v.Sex_of_Driver <> 'Data missing or out of range'
	GROUP BY
		v.Sex_of_Driver
END;


-- Number of drivers involved in accidents where speed limits were between 30 and 40, broken down by sex.

EXEC sp_speed_limits @p_lower = 30 , @p_higher = 40;


-- Number of drivers involved in accidents where the speed limit is 70mph, broken down by sex

EXEC sp_speed_limits @p_lower = 70, @p_higher = 70;


--###################################################################


-- Comparing casualty severity between car occupants and motorcycles occupants involved in accidents


-- Comparing the casualty rate of car occupants invovled in accidents to the casualty rate of motorcycle occupants invovled in accidents, using a common table expression

WITH CTE AS
(
SELECT TOP 1 (SELECT COUNT(*) FROM vehicles WHERE Vehicle_Type LIKE('%Car%')) AS number_of_cars, 
(SELECT COUNT(*) FROM vehicles WHERE Vehicle_Type LIKE('%motorcycle%')) AS number_of_motorcycles,
(SELECT COUNT(*) FROM casualties WHERE Casualty_Type LIKE('%car%')) AS car_casualties,
(SELECT COUNT(*) FROM casualties WHERE Casualty_Type LIKE('%motorcycle%')) AS motorcycle_casualties
FROM vehicles -- place holder (any of the tables here would give the same result, as the releveant tables have already been selected from in the subqueries above)
)
SELECT number_of_cars,
	   car_casualties,
	   ROUND(CAST(car_casualties AS float)/CAST(number_of_cars AS float),3) AS car_casualty_rate, 
	   number_of_motorcycles,
	   motorcycle_casualties,
	   ROUND(CAST(motorcycle_casualties AS float)/CAST(number_of_motorcycles AS float),3) AS motorcycle_casualty_rate 
FROM CTE
;


-- Including the above query in a stored procedure with variable casualty severity

DROP PROCEDURE IF EXISTS sp_car_v_bike;
CREATE PROCEDURE sp_car_v_bike @severity NVARCHAR(255)
AS
BEGIN

WITH CTE AS
(
SELECT TOP 1 
	(SELECT COUNT(*) FROM vehicles WHERE Vehicle_Type LIKE('%Car%')) AS number_of_cars, 
	(SELECT COUNT(*) FROM vehicles WHERE Vehicle_Type LIKE('%motorcycle%')) AS number_of_motorcycles,
	(SELECT COUNT(*) FROM casualties WHERE Casualty_Type LIKE('%car%') AND Casualty_Severity = @severity) AS car_casualties,
	(SELECT COUNT(*) FROM casualties WHERE Casualty_Type LIKE('%motorcycle%') AND Casualty_Severity = @severity) AS motorcycle_casualties
FROM vehicles  -- place holder (any of the tables here would give the same result, as the releveant tables have already been selected from in the subqueries above)	
)
SELECT ROUND(CAST(car_casualties AS float)/CAST(number_of_cars AS float),3) AS car_casualty_rate, 
       ROUND(CAST(motorcycle_casualties AS float)/CAST(number_of_motorcycles AS float),3) AS motorcycle_casualty_rate 
FROM CTE

END;


-- Comparing the casualty rate of car occupants and motorcycle occupants with slight injuries.

EXEC sp_car_v_bike @severity = 'Slight'


-- Comparing the serious casualty rate of car occupants and motorcycle occupants.

EXEC sp_car_v_bike @severity = 'Serious'


-- Comparing the fatality rate of car occupants and motorcycle occupants.

EXEC sp_car_v_bike @severity = 'Fatal'



-- Breaking down casualty rates for all vehicles, motorcycle and cars in separate queries

--TOTALS

SELECT 
    number_of_vehicles
    , total_casualties 
    , ROUND(CONVERT(float, total_casualties)/CONVERT(float, number_of_vehicles),3) AS casualty_vehicle_ratio
	, slight_casualties
	, ROUND(CONVERT(float, slight_casualties)/CONVERT(float, number_of_vehicles),3) AS slight_casualty_vehicle_ratio
	, serious_casualties
	, ROUND(CONVERT(float, serious_casualties)/CONVERT(float, number_of_vehicles),3) AS serious_casualty_vehicle_ratio
	, fatal_casualties
	, ROUND(CONVERT(float, fatal_casualties)/CONVERT(float, number_of_vehicles),3) AS fatal_casualty_vehicle_ratio
FROM
    (SELECT COUNT(*) AS number_of_vehicles from vehicles) a
    , (SELECT COUNT(*) AS total_casualties from casualties) b
	, (SELECT COUNT(*) AS slight_casualties from casualties WHERE Casualty_Severity = 'Slight') c
	, (SELECT COUNT(*) AS serious_casualties from casualties WHERE Casualty_Severity = 'Serious') d
	, (SELECT COUNT(*) AS fatal_casualties from casualties WHERE Casualty_Severity = 'Fatal') e
;


-- MOTORCYCLES

SELECT 
      number_of_motorcycles
    , total_mc_casualties 
    , ROUND(CONVERT(float, total_mc_casualties)/CONVERT(float, number_of_motorcycles),3) AS mc_casualty_vehicle_ratio
	, slight_mc_casualties
	, ROUND(CONVERT(float, slight_mc_casualties)/CONVERT(float, number_of_motorcycles),3) AS slight_mc_casualty_vehicle_ratio
	, serious_mc_casualties
	, ROUND(CONVERT(float, serious_mc_casualties)/CONVERT(float, number_of_motorcycles),3) AS serious_mc_casualty_vehicle_ratio
	, fatal_mc_casualties
	, ROUND(CONVERT(float, fatal_mc_casualties)/CONVERT(float, number_of_motorcycles),3) AS fatal_mc_casualty_vehicle_ratio
FROM
    (SELECT COUNT(*) AS number_of_motorcycles from vehicles WHERE vehicle_type LIKE('%motorcycle%')) a
    , (SELECT COUNT(*) AS total_mc_casualties from casualties WHERE Casualty_Type LIKE('%motorcycle%')) b
	, (SELECT COUNT(*) AS slight_mc_casualties from casualties WHERE Casualty_Severity = 'Slight' AND Casualty_Type LIKE('%motorcycle%')) c
	, (SELECT COUNT(*) AS serious_mc_casualties from casualties WHERE Casualty_Severity = 'Serious' AND Casualty_Type LIKE('%motorcycle%')) d
	, (SELECT COUNT(*) AS fatal_mc_casualties from casualties WHERE Casualty_Severity = 'Fatal' AND Casualty_Type LIKE('%motorcycle%')) e
;


-- CAR

SELECT 
      number_of_cars
    , total_car_casualties 
    , ROUND(CONVERT(float, total_car_casualties)/CONVERT(float, number_of_cars),3) AS car_casualty_vehicle_ratio
	, slight_car_casualties
	, ROUND(CONVERT(float, slight_car_casualties)/CONVERT(float, number_of_cars),3) AS slight_car_casualty_vehicle_ratio
	, serious_car_casualties
	, ROUND(CONVERT(float, serious_car_casualties)/CONVERT(float, number_of_cars),3) AS serious_car_casualty_vehicle_ratio
	, fatal_car_casualties
	, ROUND(CONVERT(float, fatal_car_casualties)/CONVERT(float, number_of_cars),3) AS fatal_car_casualty_vehicle_ratio
FROM
    (SELECT COUNT(*) AS number_of_cars from vehicles WHERE vehicle_type LIKE('%car%')) a
    , (SELECT COUNT(*) AS total_car_casualties from casualties WHERE Casualty_Type LIKE('%car%')) b
	, (SELECT COUNT(*) AS slight_car_casualties from casualties WHERE Casualty_Severity = 'Slight' AND Casualty_Type LIKE('%car%')) c
	, (SELECT COUNT(*) AS serious_car_casualties from casualties WHERE Casualty_Severity = 'Serious' AND Casualty_Type LIKE('%car%')) d
	, (SELECT COUNT(*) AS fatal_car_casualties from casualties WHERE Casualty_Severity = 'Fatal' AND Casualty_Type LIKE('%car%')) e






