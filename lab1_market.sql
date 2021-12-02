USE master
GO 

IF  EXISTS (
	SELECT name 
		FROM sys.databases 
		WHERE name = N'KN302_Plyuhin_Market'
)
ALTER DATABASE KN302_Plyuhin_Market set single_user with rollback immediate
GO

IF  EXISTS (
	SELECT name 
		FROM sys.databases 
		WHERE name = N'KN302_Plyuhin_Market'
)
DROP DATABASE KN302_Plyuhin_Market
GO


CREATE DATABASE KN302_Plyuhin_Market
GO


USE KN302_Plyuhin_Market
GO

Create schema Plyuhin
GO

CREATE TABLE Plyuhin.market
(
	id_m int NOT NULL, 
	m_name varchar(20) NOT NULL, 
	addres varchar(20) NOT NULL, 
	PRIMARY KEY (id_m) 
)
GO


CREATE TABLE Plyuhin.product_group
(
	id_g int NOT NULL, 
	g_name varchar(50) NOT NULL, 
	PRIMARY KEY (id_g) 
)
GO

CREATE TABLE Plyuhin.product_type
(
	id_t int NOT NULL, 
	t_name varchar(50) NOT NULL, 
	descr varchar(100) NOT NULL, 
	id_g int NOT NULL,
	PRIMARY KEY (id_t) ,
	FOREIGN KEY (id_g)
		REFERENCES	Plyuhin.product_group(id_g)
)
GO

CREATE TABLE Plyuhin.product
(
	id int NOT NULL, 
	id_m int NOT NULL, 
	id_t int NOT NULL, 
	amount decimal(14, 3) NULL, 
	price int NOT NULL,
	post_date date NULL, 
	is_sold tinyint Null,
	actionDate date Null,
    PRIMARY KEY (id) ,
	FOREIGN KEY (id_m)
		REFERENCES	Plyuhin.market(id_m),
	FOREIGN KEY (id_t)
		REFERENCES	Plyuhin.product_type(id_t)
)
GO



INSERT Plyuhin.market(id_m, m_name, addres) VALUES (1, 'market1', 'address1')

INSERT Plyuhin.market(id_m, m_name, addres) VALUES (2, 'market2', 'address2')

INSERT Plyuhin.product_group(id_g, g_name) VALUES (1, 'vipechka')

INSERT Plyuhin.product_group(id_g, g_name) VALUES (2, 'molochnie')

INSERT Plyuhin.product_type(id_t,	t_name, descr,id_g) VALUES (1, 'bread', 'хлеб', 1)

INSERT Plyuhin.product_type(id_t,	t_name, descr,id_g) VALUES (2, 'milk', 'молоко',2)

INSERT Plyuhin.product(id, id_m, id_t, amount, price , post_date, is_sold,	actionDate) VALUES (1, 1, 1, 100, 50, '20121011 10:10:10 AM', 1, '20121011 10:10:10 AM')

INSERT Plyuhin.product(id, id_m, id_t, amount, price,  post_date ,is_sold,	actionDate) VALUES (2, 2, 1, 5, 10, '20121010 10:10:11 AM', 0, '20121011 10:10:10 AM')

INSERT Plyuhin.product(id, id_m, id_t, amount, price, post_date,  is_sold,	actionDate) VALUES (3, 1, 2, 1050, 40, '20121011 10:10:12 AM', 1, '20121011 10:10:10 AM')

INSERT Plyuhin.product(id, id_m, id_t, amount, price, post_date,  is_sold,	actionDate) VALUES (4, 2, 2, 1, 20, '20121008 10:10:13 AM',0 , '20121011 10:10:10 AM')



SELECT        *
FROM            Plyuhin.market INNER JOIN
                         Plyuhin.product ON Plyuhin.market.id_m = Plyuhin.product.id_m INNER JOIN
                         Plyuhin.product_type ON Plyuhin.product.id_t = Plyuhin.product_type.id_t INNER JOIN
                         Plyuhin.product_group ON Plyuhin.product_type.id_g = Plyuhin.product_group.id_g

-- Products amount of exact type in all markets						 
--SELECT      COUNT (*)
--FROM Plyuhin.product  P INNER JOIN Plyuhin.product_type PT ON P.id_t= PT.id_t WHERE PT.t_name ='bread'

-- Products amount on exact date
SELECT COUNT(*) as count, PT.t_name, FORMAT(P.post_date, 'D', 'ru-RU') as date
	FROM Plyuhin.product  P INNER JOIN Plyuhin.product_type PT ON P.id_t= PT.id_t WHERE P.post_date > '20121009' GROUP BY P.id, P.post_date, PT.t_name

-- Колво товара в каждом магазине
SELECT M.m_name, COUNT(*) as count 
	FROM Plyuhin.product P INNER JOIN Plyuhin.market M ON P.id_m = M.id_m  GROUP BY P.id_m, M.m_name

-- Макс цена
SELECT  
	PT.t_name,  
	MAX(price) as max_price 
FROM Plyuhin.product P 
INNER JOIN Plyuhin.product_type PT ON P.id_t = PT.id_t 
GROUP BY PT.t_name

--Средняя
SELECT  
	PT.t_name,  
	AVG(price) as max_price 
FROM Plyuhin.product P 
INNER JOIN Plyuhin.product_type PT ON P.id_t = PT.id_t 
GROUP BY PT.t_name

