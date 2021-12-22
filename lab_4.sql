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
Create schema lab4
GO

CREATE TABLE lab4.Rate( 
	ID_Rate INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
	Abonent_price FLOAT NOT NULL,
	Minutes FLOAT NOT NULL,
	Overhead_price FLOAT NOT NULL
)
GO

CREATE FUNCTION lab4.ABSDifference(@f FLOAT, @s FLOAT)
	RETURNS INT
	AS
	BEGIN
		IF (@f < @s) RETURN 0
		RETURN @f - @s
	END
GO

CREATE FUNCTION lab4.BestRate(@q FLOAT)
	RETURNS INT
	AS
	BEGIN
		DECLARE @min FLOAT =(SELECT MIN(t.Abonent_price + t.Overhead_price * lab4.ABSDifference(@q, t.Minutes)) FROM Rate as t)
		DECLARE @id INT=(SELECT MIN(t.ID_Rate) FROM Rate as t
			WHERE (t.Abonent_price + t.Overhead_price * lab4.ABSDifference(@q, t.Minutes) = @min))

		RETURN @id
	END
 GO

CREATE PROCEDURE lab4.OptimalTariffs
	AS
	BEGIN
		CREATE TABLE #t
		(
			Overhead_price FLOAT NOT NULL, 
			id1 INT, 
			id2 INT
		) 

		INSERT INTO #t 
		SELECT (b.Abonent_price - a.Abonent_price - b.Minutes*b.Overhead_price  + a.Minutes*a.Overhead_price)/(a.Overhead_price - b.Overhead_price), a.ID_Rate, b.ID_Rate 
		FROM Rate as a, Rate as b 
		WHERE a.ID_Rate < b.ID_Rate AND b.Overhead_price <> a.Overhead_price AND a.Overhead_price - b.Overhead_price <> 0 and 
		(b.Abonent_price - a.Abonent_price - b.Minutes*b.Overhead_price  + a.Minutes*a.Overhead_price)/(a.Overhead_price - b.Overhead_price)>0

		INSERT INTO #t
		SELECT (a.Abonent_price - b.Abonent_price + b.Overhead_price*b.Minutes)/(b.Overhead_price), a.ID_Rate, b.ID_Rate 
		FROM Rate as a, Rate as b 
		WHERE a.ID_Rate <> b.ID_Rate AND b.Overhead_price <> 0 AND b.Minutes <= a.Minutes

		CREATE TABLE #set
		(
			l FLOAT, 
			r FLOAT, 
			id INT
		) 

		DECLARE @point FLOAT
		DECLARE @id1 INT
		DECLARE @id2 INT
		DECLARE @l FLOAT = 0;
		DECLARE @CURSOR CURSOR
		SET @CURSOR = CURSOR
		FOR
			SELECT #t.Overhead_price, #t.id1, #t.id2 
			FROM #t ORDER BY #t.Overhead_price
		OPEN @CURSOR
		FETCH NEXT FROM @CURSOR INTO @point, @id1, @id2
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF (lab4.BestRate(ROUND(@point,0)-0.001) = @id1)
			BEGIN
				INSERT INTO #set (l, r, id) VALUES (@l, @point, @id1)
				SET @l = @point;
			END
			ELSE
			IF (lab4.BestRate(ROUND(@point, 0)-0.001) = @id2)
			BEGIN
				INSERT INTO #set (l, r, id) VALUES (@l, @point, @id2)
				SET @l = @point;
			END
			FETCH NEXT FROM @CURSOR INTO @point, @id1, @id2
		END
		CLOSE @CURSOR
		INSERT INTO #set (l, r, id) VALUES (@l, 43200, lab4.BestRate(43200))
		SELECT DISTINCT cast(#set.l as int) as 'С какой минуты', cast(#set.r as int) as 'По какую минуту', #set.id as 'Тариф'
			FROM #set WHERE #set.l <> #set.r OR #set.r IS NULL 
	END
GO

INSERT INTO lab4.Rate VALUES
	(0, 0, 0.5),
	(2, 6, 1),
	--(500, 2500, 4),
	(5, 43200, 0)
GO

--Select lab4.BestRate(50000)
--GO

lab4.OptimalTariffs
GO