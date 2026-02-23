/*
Создание всех задуманных таблиц.
Начало работы 03.11.25 13:45
Конец работы 04.11.25 20:47
Сорокин Никита
*/
USE ALFA_SOBES;
GO
/* Проверка на существующие таблицы через id. Если есть, то удаляются.
Удалять в нужной последовательности, иначе выдает ошибку. Начинать удаление с самых вложенных таблиц*/
IF OBJECT_ID('Incident_history','U') IS NOT NULL 
BEGIN
	DROP TABLE Incident_history;
	PRINT('Ранее созданная таблица Incident_history удалена') ;
END

IF OBJECT_ID('Incidents','U') IS NOT NULL
BEGIN
	DROP TABLE Incidents;
	PRINT('Ранее созданная таблица Incidents удалена') ;
END

IF OBJECT_ID('Client_products','U') IS NOT NULL 
BEGIN
	DROP TABLE Client_products;
	PRINT('Ранее созданная таблица Client_products удалена') ;
END

IF OBJECT_ID('Products','U') IS NOT NULL 
BEGIN
	DROP TABLE Products;
	PRINT('Ранее созданная таблица Products удалена') ;
END

IF OBJECT_ID('Specialists','U') IS NOT NULL
BEGIN
	DROP TABLE Specialists;
	PRINT('Ранее созданная таблица Specialists удалена') ;
END

IF OBJECT_ID('Categories','U') IS NOT NULL 
BEGIN
	DROP TABLE Categories;
	PRINT('Ранее созданная таблица Categories удалена') ;
END

IF OBJECT_ID('Clients','U') IS NOT NULL 
BEGIN
	DROP TABLE Clients;
	PRINT('Ранее созданная таблица Clients удалена') ;
END


CREATE TABLE Clients (
client_id INT IDENTITY (1,1) PRIMARY KEY, --первичный ключ
/* VARCHAR - без юникода (цифры, латиница). NVARCHAR - то же самое, но с юникодом (иероглифы)*/
first_name NVARCHAR (50) NOT NULL, -- имя 
middle_name NVARCHAR (50) NULL, -- отчество (может у кого-то нет отчества)
last_name NVARCHAR (50) NOT NULL, -- фамилия
phone VARCHAR (20) NOT NULL UNIQUE, --телефон, нельзя регать два акка на один номер
email VARCHAR (100) NULL, --почта
segment VARCHAR (20) NOT NULL CHECK (segment IN ('mass','premium','business','vip')), --сегмент, должен быть из списка для проверки
registration_date DATETIME2 NOT NULL DEFAULT GETDATE(), --дата регистрации, если не указано, то текущее время
is_active BIT NOT NULL DEFAULT 1 --активность акка, по умолчанию - активен
);

CREATE TABLE Products (
product_id INT IDENTITY (1,1) PRIMARY KEY, --первичынй ключ
product_type VARCHAR(20) NOT NULL CHECK (product_type IN ('card','deposit','credit','service')),--тип продукта, должен быть из списка для проверки
product_name NVARCHAR(100) NOT NULL, --что это такое, ипотека, "Апельсиновая", "супер-пупер карта" и т.д.
product_description NVARCHAR(1000) NULL --описание, какой-то прикол с условиями ипотеки мб
);

CREATE TABLE Specialists (
specialist_id INT IDENTITY (1,1) PRIMARY KEY, --первичный ключ
first_name NVARCHAR (50) NOT NULL, -- имя 
middle_name NVARCHAR (50) NULL, -- отчество (может у кого-то нет отчества)
last_name NVARCHAR (50) NOT NULL, -- фамилия
department NVARCHAR (30) NOT NULL, --отдел, в котором работает чел, мб город
specialization NVARCHAR (100) NULL, --с какими типами проблем может работать спец, если null - то чел гений и умеет все
is_active BIT NOT NULL DEFAULT 1 --работает или нет, по умолчанию да
);

CREATE TABLE Categories (
category_id INT IDENTITY (1,1) PRIMARY KEY, --первичный ключ, условно, потерял карту - 1, проблема с переводом - 2
parent_id INT NULL, /*вторичный ключ, здесь самоссылка на category_id, потерял карту (1) по причине: просто потерял - null, украли - 1, сжёг в печи - 2 и т.п. Тогда, если чел сжег свою карту, то будет 1 и 2*/
category_name VARCHAR(100) NOT NULL,
sla_minutes INT NOT NULL DEFAULT 120 /*(Service Level Agreement) — соглашение об уровне обслуживания, сколько времени дается на решение той или иной проблемы, по умолчанию будет 120 минут*/
CONSTRAINT FK_Categories_parent	FOREIGN KEY (parent_id) REFERENCES Categories(category_id) --самоссылка
);

CREATE TABLE Client_products (
client_id INT NOT NULL,--вторичный ключ, часть составного первичного
product_id INT NOT NULL, --вторичный ключ, часть составного первичного
account_number VARCHAR(30) NOT NULL UNIQUE,--комбинация client_id и account_number, уникальное
activation_date DATETIME2 NOT NULL DEFAULT GETDATE(), --дата создания 
cp_status VARCHAR(20) NOT NULL CHECK (cp_status IN ('active','blocked','closed')), --статус, должен быть из списка для проверки
balance DECIMAL (18,2) NULL, -- баланс на счету, до 18 нулей, 2 знака после запятой
/* outline ограничения (нельзя inline).*/
CONSTRAINT PK_ClientProducts PRIMARY KEY (client_id,product_id), --составной ключ
CONSTRAINT FK_ClientProducts_client FOREIGN KEY (client_id) REFERENCES Clients(client_id), --ссылка на clients
CONSTRAINT FK_ClientProducts_product FOREIGN KEY (product_id) REFERENCES Products(product_id) --ссылка на products
);

CREATE TABLE Incidents (
incident_id INT IDENTITY (1,1) PRIMARY KEY,--первичный ключ
client_id INT NOT NULL, --вторичный ключ
product_id INT NOT NULL, --вторичный ключ
account_number VARCHAR(30) NOT NULL, --вторичный ключ
category_id INT NOT NULL, --вторичный ключ
created_time DATETIME2 NOT NULL DEFAULT GETDATE(), --когда создано
channel VARCHAR(20) NOT NULL CHECK (channel IN ('phone','app','email','chat','department')), --как сообщили о проблеме
incident_priority VARCHAR(10) NOT NULL CHECK (incident_priority IN('low','medium','high','critical')), --опасность\важность проблемы
incident_status VARCHAR(20) NOT NULL DEFAULT 'new' CHECK (incident_status IN ('new','waiting','in_work','resolved','closed')), --стадия решения проблемы
incident_description NVARCHAR(3000) NULL, --описание проблемы
resolved_time DATETIME2 NULL, --за сколько решена проблема
/* outline ограничения (нельзя inline).*/
CONSTRAINT FK_Incidents_client FOREIGN KEY (client_id) REFERENCES Clients(client_id), --ссылка на Clients
CONSTRAINT FK_Incidents_product FOREIGN KEY (product_id) REFERENCES Products(product_id), --ссылка на Products
CONSTRAINT FK_Incidents_account FOREIGN KEY (account_number) REFERENCES Client_products(account_number), --ссылка на Client_products
CONSTRAINT FK_Incidents_category FOREIGN KEY (category_id) REFERENCES Categories(category_id), --ссылка на Categories
);

CREATE TABLE Incident_history (
history_id INT IDENTITY (1,1) PRIMARY KEY,--первичный ключ
incident_id INT NOT NULL, --вторичный ключ
specialist_id INT NOT NULL, --вторичный ключ
action_time DATETIME2 NOT NULL DEFAULT GETDATE(), --время действия
action_type VARCHAR(100) NOT NULL, --описание, что изменилось
previous_status VARCHAR(30) NULL, --что было до изменения, null, если первая запись
new_status VARCHAR(30) NULL, --новый статус
ih_comment NVARCHAR(1500) NULL, --коммент спеца
time_spent INT NULL, --времени потрачено
/* outline ограничения (нельзя inline).*/
CONSTRAINT FK_IncidentsHistory_incident FOREIGN KEY (incident_id) REFERENCES Incidents(incident_id), --ссылка на Incidents
CONSTRAINT FK_IncidentsHistory_specialist FOREIGN KEY (specialist_id) REFERENCES Specialists(specialist_id), --ссылка на Specialists
);

/* Создаем индексы пока что просто на все внешние ключи (аля оптимизация) */
CREATE INDEX IX_ClientProducts_ClientId ON Client_products(client_id);
CREATE INDEX IX_ClientProducts_ProductId ON Client_products(product_id);
CREATE INDEX IX_Incidents_ClientId ON Incidents(client_id);
CREATE INDEX IX_Incidents_ProductId ON Incidents(product_id);
CREATE INDEX IX_Incidents_CategoryId ON Incidents(category_id);
CREATE INDEX IX_IncidentHistory_IncidentId ON Incident_history(incident_id);
CREATE INDEX IX_IncidentHistory_SpecialistId ON Incident_history(specialist_id);


PRINT ('ВСЕ ТАБЛИЦЫ СОЗДАНЫ (ПУСТЫЕ)');
