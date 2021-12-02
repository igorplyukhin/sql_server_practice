USE master
GO 
IF  EXISTS (
	SELECT name 
		FROM sys.databases 
		WHERE name = N'KN302_Plyuhin'
)
ALTER DATABASE KN302_Plyuhin set single_user with rollback immediate
GO
IF  EXISTS (
	SELECT name 
		FROM sys.databases 
		WHERE name = N'KN302_Plyuhin'
)
DROP DATABASE KN302_Plyuhin
GO
CREATE DATABASE KN302_Plyuhin
GO
USE KN302_Plyuhin
GO
Create schema CarsTask
GO
------CHECK------
CREATE FUNCTION CarsTask.CheckTransition(@number varchar(9), @direction int)
RETURNS tinyint
AS
BEGIN
	DECLARE @last_direction int = (SELECT TOP 1 direction FROM CarsTask.Transition WHERE car_registration_number = @number ORDER BY tr_date DESC)
	
	RETURN IIF(@last_direction = @direction, 1, 0)
END
GO
--------------TABLES----------------
CREATE TABLE CarsTask.PolicePosts(
	id int NOT NULL PRIMARY KEY,
)
GO
CREATE TABLE CarsTask.Regions(
	code int NOT NULL PRIMARY KEY ,
	str_name varchar(50) NOT NULL,
)
GO
CREATE TABLE CarsTask.Cars
(
	registration_number varchar(9) NOT NULL PRIMARY KEY
)
GO
CREATE TABLE CarsTask.Transition
(
	car_registration_number varchar(9) NOT NULL  FOREIGN KEY REFERENCES CarsTask.Cars(registration_number),
	police_post int NOT NULL  FOREIGN KEY REFERENCES CarsTask.PolicePosts(id),
	direction int  NOT NULL ,
	tr_date time  NOT NULL ,
	CONSTRAINT check_transition CHECK (CarsTask.CheckTransition(car_registration_number, direction) = 1)
)
GO

-----------------PROCEDURES--------------------

CREATE PROCEDURE InsertPolicePost
AS
BEGIN 
	INSERT INTO CarsTask.PolicePosts VALUES (0), (1), (2), (3), (4)
END
GO

CREATE PROCEDURE InsertRegion(@code int, @name varchar(50))
AS
BEGIN 
	INSERT INTO CarsTask.Regions VALUES (@code, @name)
END
GO

CREATE PROCEDURE InsertCar(@reigstation_number varchar(9))
AS
BEGIN 
	INSERT INTO CarsTask.Cars VALUES (@reigstation_number)
END
GO

CREATE FUNCTION CarsTask.GetCarRegion(@registration_number varchar(9)) 
RETURNS varchar(50)
AS
BEGIN
	DECLARE @region_code int
	IF LEN(@registration_number) = 8
		SET @region_code = CONVERT(INT, SUBSTRING(@registration_number, 7, 2))
	ELSE IF LEN(@registration_number) = 9
		SET @region_code = CONVERT(INT, SUBSTRING(@registration_number, 7, 3))

	DECLARE @region_name varchar(50) = (SELECT str_name FROM CarsTask.Regions WHERE code = @region_code)

	RETURN @region_name
END
GO

CREATE PROCEDURE InsertTransition(@reigstation_number varchar(9), @police_post int, @direction int,	@tr_date time)
AS
BEGIN 
	IF NOT EXISTS(SELECT registration_number FROM CarsTask.Cars WHERE registration_number = @reigstation_number)
		EXECUTE InsertCar @reigstation_number
	
	INSERT INTO CarsTask.Transition VALUES (@reigstation_number, @police_post, @direction, @tr_date)
END
GO
--------TRIGGERS--------
CREATE TRIGGER validate_car_number ON CarsTask.Cars INSTEAD OF INSERT
AS
 DECLARE @number varchar(9) = (SELECT registration_number FROM inserted)
 IF LEN(@number) <> 8 AND LEN(@number) <> 9
 BEGIN
	SELECT 'Неверный номер автомобиля' as 'Error', @number as 'Номер автомобиля' 
	RETURN 
 END

 DECLARE @first_letter varchar(10) = SUBSTRING(@number, 1 , 1)
 DECLARE @digits varchar(10) =  SUBSTRING(@number, 2 , 3)
 DECLARE @last_letters varchar(10) =  SUBSTRING(@number, 5 , 2)
 DECLARE @region_code varchar(10) = SUBSTRING(@number, 7 , 2)
 IF @first_letter LIKE '%[^a-z,^A-Z]%'
 OR @digits LIKE '%[^0-9]%'
 OR @last_letters LIKE '%[^a-z,^A-Z]%'
 OR @region_code LIKE  '%[^0-9]%'
 BEGIN
	SELECT 'Неверный номер автомобиля' as 'Error', @number as 'Номер автомобиля'  
	RETURN 
 END

 IF LEN(@number) = 9
 BEGIN
	SET @region_code = SUBSTRING(@number, 7 , 3)
	DECLARE @first_digits_in_region_code varchar(1) = SUBSTRING(@region_code, 1, 1)
	IF @region_code LIKE  '%[0-9]%'
	AND @first_digits_in_region_code IN ('1' , '2' , '7')
		INSERT INTO CarsTask.Cars VALUES (@number)
	ELSE
	BEGIN
		SELECT 'Неверный номер автомобиля' as 'Error', @number as 'Номер автомобиля' 
		RETURN 
	END
 END
 ELSE IF LEN(@number) = 8
	INSERT INTO CarsTask.Cars VALUES (@number)
 ELSE
 BEGIN
	SELECT 'Неверный номер автомобиля' as 'Error', @number as 'Номер автомобиля' 
	RETURN 
 END
 
GO


--CREATE TRIGGER validate_transition ON CarsTask.Transition INSTEAD OF INSERT
--AS
--	DECLARE @reigstation_number varchar(9) = (SELECT car_registration_number FROM inserted)
--	DECLARE @police_post int = (SELECT police_post FROM inserted) 
--	DECLARE @direction int =  (SELECT direction FROM inserted)
--	DECLARE @tr_date time =  (SELECT tr_date FROM inserted)
--	DECLARE @last_direction int = (SELECT TOP 1 direction FROM CarsTask.Transition WHERE car_registration_number = @reigstation_number ORDER BY tr_date DESC)
--	IF @last_direction = @direction
--		SELECT 'Два одинаковых направления движения подряд' as 'Error', @reigstation_number AS 'Номер автомобиля'
--	ELSE 
--		INSERT INTO CarsTask.Transition VALUES (@reigstation_number, @police_post, @direction, @tr_date)
--GO
-------VIEWS-----------
-- Местный
CREATE VIEW [Местные] AS
SELECT
	'Местный' as 'Тип автомобиля'
	,T1.car_registration_number as 'Номер автомобиля'
	, CarsTask.GetCarRegion(T1.car_registration_number) as 'Регион'
	,CAST(T1.tr_date as TIME(0)) as 'Время въезда'
	, CAST(T2.tr_date as TIME(0)) as 'Время выезда'
FROM CarsTask.Transition T1 
INNER JOIN CarsTask.Transition T2 
ON (T1.car_registration_number = T2.car_registration_number
	AND T1.tr_date < T2.tr_date
	AND T1.direction = 0
	AND T2.direction = 1
	AND 'Свердловская область' = CarsTask.GetCarRegion(T1.car_registration_number)
)
GO
---- Транзит
CREATE VIEW [Транзитные] AS
SELECT
	'Транзитный' as 'Тип автомобиля'
	,T1.car_registration_number as 'Номер автомобиля'
	, CarsTask.GetCarRegion(T1.car_registration_number) as 'Регион'
	, CAST(T1.tr_date as TIME(0)) as 'Время въезда'
	, CAST(T2.tr_date as TIME(0)) as 'Время выезда'
FROM CarsTask.Transition T1 
INNER JOIN CarsTask.Transition T2 
ON (T1.car_registration_number = T2.car_registration_number
	AND T1.tr_date < T2.tr_date
	AND T1.direction = 1
	AND T2.direction = 0
	AND 'Свердловская область' <> CarsTask.GetCarRegion(T1.car_registration_number)
)
GO
----Иногородний
CREATE VIEW [Иногородние] AS
SELECT
	'Иногородний' as 'Тип автомобиля'
	,T1.car_registration_number as 'Номер автомобиля'
	, CarsTask.GetCarRegion(T1.car_registration_number) as 'Регион'
	, CAST(T1.tr_date as TIME(0)) as 'Время въезда'
	, CAST(T2.tr_date as TIME(0)) as 'Время выезда'
FROM CarsTask.Transition T1 
INNER JOIN CarsTask.Transition T2 
ON (T1.car_registration_number = T2.car_registration_number
	AND T1.tr_date < T2.tr_date
	AND T1.direction = 1
	AND T2.direction = 0
	AND T1.police_post = T2.police_post
)
GO
-------TEST TRIGGERS-------
--EXECUTE InsertCar 'A123AA66'
--EXECUTE InsertCar 'A123AA446'
--EXECUTE InsertCar 'A123БA66'

--EXECUTE InsertPolicePost
--EXECUTE InsertTransition 'A123AA66', 0, 0, '20211201 10:10:10 AM'
--EXECUTE InsertTransition 'A123AA66', 0, 0, '20211201 10:11:10 AM'


--------------MAIN----------------

EXECUTE InsertPolicePost

EXECUTE InsertRegion 01, 'Республика Адыгея'
EXECUTE InsertRegion 66, 'Свердловская область'
EXECUTE InsertRegion 196, 'Свердловская область'
EXECUTE InsertRegion 74, 'Челябинская Область'
EXECUTE InsertRegion 174, 'Челябинская Область'
EXECUTE InsertRegion 77, 'Московская область'

EXECUTE InsertCar 'A123AA66'
EXECUTE InsertCar 'B123BB77'
EXECUTE InsertCar 'C123CC01'

-----МЕСТНЫЙ
EXECUTE InsertTransition 'A123AA66', 0, 0, '20211201 10:10:10 AM'
EXECUTE InsertTransition 'A123AA66', 0, 1, '20211201 10:11:10 AM'
EXECUTE InsertTransition 'A123AA66', 0, 0, '20211201 10:12:10 AM'
EXECUTE InsertTransition 'A123AA66', 0, 1, '20211201 10:13:10 AM'
--ИНОГОРОДНИЙ
EXECUTE InsertTransition 'B123BB01', 0, 1, '20211201 10:10:10 AM'
EXECUTE InsertTransition 'B123BB01', 0, 0, '20211201 10:11:10 AM'
--ТРАНЗИТНЫЙ
EXECUTE InsertTransition 'B123BB77', 2, 1, '20211201 10:10:10 AM'
EXECUTE InsertTransition 'B123BB77', 1, 0, '20211201 10:11:10 AM'
GO


SELECT * FROM [Местные]
SELECT * FROM [Транзитные]
SELECT * FROM [Иногородние]