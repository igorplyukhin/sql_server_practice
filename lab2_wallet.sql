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
Create schema Task2
GO
CREATE TABLE Task2.Wallet
(
	id int NOT NULL PRIMARY KEY , 
	amount decimal(20,10)NOT NULL , 
	currency_name varchar(20) NOT NULL, 
)
GO
CREATE TABLE Task2.Exchange
(
	id_from int NOT NULL,
	id_to  int NOT NULL,
	coef decimal(20,10) NOT NULL, 
)
GO
--Добавление валют
INSERT Task2.Wallet VAlUES (1, 0 ,'USD')
						,(2, 0 ,'EUR')
						,(3, 0 ,'RUB')
						,(4, 0 ,'JPY')
--Добавление коэффициентов
INSERT Task2.Exchange VALUES (1, 2, 1/1.1594)
							,(2, 1, 1.1594)
							,(1, 3, 74.4)
							,(3, 1, 1/74.4)
							,(1, 4, 114.85)
							,(4, 1, 1/114.85)
							,(2, 3, 83.44)
							,(3, 2, 1/83.44)
							,(2, 4, 129.2)
							,(4, 2, 1/129.2)
							,(3, 4, 1.55)
							,(4, 3, 1/1.55)
GO
--  Пополнить
CREATE PROCEDURE Deposit(@currecy VARCHAR(20), @amount DECIMAL(20,10), @id int)
AS
BEGIN 
	IF NOT EXISTS(SELECT id FROM Task2.Wallet WHERE currency_name = @currecy)	
		INSERT Task2.Wallet VAlUES (@id, @amount ,@currecy)
	ELSE
		UPDATE Task2.Wallet
			SET amount = amount + @amount
			WHERE Wallet.currency_name = @currecy
END

GO
-- Перевести в дргую валюту
CREATE PROCEDURE Exchange(@from_currency VARCHAR(20), @to_currency VARCHAR(20), @amount DECIMAL(20,10)) 
AS
BEGIN
	DECLARE @id_from int = (SELECT id FROM Task2.Wallet WHERE currency_name = @from_currency)
	DECLARE @id_to int = (SELECT id FROM Task2.Wallet WHERE currency_name = @to_currency)
	DECLARE @coef DECIMAL(20,10) = (SELECT coef FROM Task2.Exchange  Where  @id_from = Exchange.id_from AND @id_to = Exchange.id_to )
	UPDATE Task2.Wallet
		SET amount = amount - @amount
		WHERE Wallet.currency_name = @from_currency

	UPDATE Task2.Wallet
		SET amount = amount + @coef * @amount
		WHERE Wallet.currency_name = @to_currency
END

GO
--  Потратить
CREATE PROCEDURE Withdraw(@from_currency VARCHAR(20), @amount DECIMAL(20,10))
AS
BEGIN
	DECLARE @balance DECIMAL(20,10) = (SELECT amount FROM Task2.Wallet WHERE currency_name = @from_currency)
	IF @balance > @amount
		UPDATE Task2.Wallet
			SET amount = amount - @amount
			WHERE Wallet.currency_name = @from_currency
	ELSE IF @balance = @amount
		BEGIN
			DELETE FROM Task2.Wallet WHERE Wallet.currency_name = @from_currency
		END
	ELSE
		SELECT 'Недостаточно денег на счету' AS 'ERROR'
END
GO
-- Показать баланс в одной валюте
CREATE FUNCTION Task2.ShowBalanceInCurrency(@id_from int,  @targer_curr_name varchar(20)) 
RETURNS DECIMAL(20,10)
AS
BEGIN
	DECLARE @id_to int = (SELECT id FROM Task2.Wallet WHERE currency_name = @targer_curr_name)
	DECLARE @coef DECIMAL(20,10) = (SELECT coef FROM Task2.Exchange  Where  id_from = @id_from AND  id_to = @id_to)
	if @coef IS NULL 
		SET @coef = 1
	DECLARE @balance DECIMAL(20,10) = (SELECT amount FROM Task2.Wallet WHERE id = @id_from)
	RETURN @balance * @coef
END
GO

-- Баланс карты
SELECT  currency_name as 'Валюта', FORMAT( amount, '#.##') as 'Количество' FROM Task2.Wallet WHERE amount > 0
GO
-------- Пример пополнения
DECLARE @cur_name VARCHAR(20) = 'RUB'
DECLARE @amount DECIMAL(20,10) = 10000
DECLARE @id int = 3
EXECUTE Deposit @cur_name, @amount, @id
GO

------ Пример Перевода в другую валюту----
--DECLARE @from_currency VARCHAR(20) = 'USD'
--DECLARE @to_currency VARCHAR(20) = 'EUR'
--DECLARE @amount DECIMAL(20,10) = 5
--EXECUTE Exchange @from_currency, @to_currency, @amount
--GO

--------Приммер потратить-----
DECLARE @amount DECIMAL(20,10) = 10000
DECLARE @from VARCHAR(20) = 'RUB'
EXECUTE Withdraw @from , @amount
GO

---Баланс в одной валюте----
--DECLARE @target_curr varchar(20) = 'RUB'
--SELECT 
--	FORMAT(SUM(Task2.ShowBalanceInCurrency(id, @target_curr)),'#.##') as 'Баланс в одной валюте',  
--	@target_curr as 'Валюта' 
--	FROM Task2.Wallet 
--GO

