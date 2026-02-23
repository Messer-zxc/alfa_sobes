/*
Скрипт для заполнения таблиц псевдо-рандомными данными
Начало работы: 05.11.25 20:29
Конец работы: 15.11.25 18:17
Сорокин Никита
*/

USE ALFA_SOBES; --без выбора БД криво удаляет таблицы
GO
SET NOCOUNT ON; -- Затронута 1 строка и десять извилин))))) Отключил вывод этой хрени
GO
/* Перед заполнением нужно очистить все таблицы, если они уже заполнены, а то все сломается. + надо сбрасывать счетчики идентификаторов*/

IF EXISTS (SELECT 1 FROM Incident_history) --самая "нижняя" таблица, зависит от нескольких других
BEGIN 
	DELETE FROM Incident_history;
	DBCC CHECKIDENT ('Incident_history', RESEED, 0);
	PRINT 'Incident_history очищена';
END
ELSE PRINT 'Incident_history не заполнена'


IF EXISTS (SELECT 1 FROM Incidents) -- зависит от Client_products и Categories
BEGIN 
	DELETE FROM Incidents;
	DBCC CHECKIDENT ('Incidents', RESEED, 0);
	PRINT 'Incidents очищена';
END
ELSE PRINT 'Incidents не заполнена'

IF EXISTS (SELECT 1 FROM Client_products) --зависит от Clients и Products
BEGIN 
	DELETE FROM Client_products;
	PRINT 'Client_products очищена';
END
ELSE PRINT 'Client_products не заполнена'

IF EXISTS (SELECT 1 FROM Categories) --с самосвязью
BEGIN 
	DELETE FROM Categories;
	DBCC CHECKIDENT ('Categories', RESEED, 0);
	PRINT 'Categories очищена';
END
ELSE PRINT 'Categories не заполнена'

IF EXISTS (SELECT 1 FROM Specialists) --независимая
BEGIN 
	DELETE FROM Specialists;
	DBCC CHECKIDENT ('Specialists', RESEED, 0);
	PRINT 'Specialists очищена';
END
ELSE PRINT 'Specialists не заполнена'

IF EXISTS (SELECT 1 FROM Products) --независимая
BEGIN 
	DELETE FROM Products;
	DBCC CHECKIDENT ('Products', RESEED, 0);
	PRINT 'Products очищена';
END
ELSE PRINT 'Products не заполнена'

IF EXISTS (SELECT 1 FROM Clients) --независимая
BEGIN 
	DELETE FROM Clients;
	DBCC CHECKIDENT ('Clients', RESEED, 0);
	PRINT 'Clients очищена';
END
ELSE PRINT 'Clients не заполнена'

/* СБРОС СЧЕТЧИКОВ */

PRINT 'ВСЕ таблицы очищены/еще не заполнены';

/* Очистку таблиц можно сделать и по другому, с TRUNCATE TABLE но тогда надо отключать проверку зависимостей (ALTER TABLE Categories NOCHECK CONSTRAINT ALL) и можно
сильно обосраться когда-нибудь, не включив эту проверку обратно.  DBCC CHECKIDENT ('Clients', RESEED, 0); в блоке IF а не отдельно, потому что при повторной генерации почему-то все
нахрен ломается и идентификаторы идут с 0, при двойном ресиде наоборот - при первой генерации все норм, а при повторной - ломается */


DECLARE @i INT = 1; --счетчик
--тупо делаем цикл, другое не придумал)
WHILE @i <= 100 
BEGIN
DECLARE @key1 INT = ABS(CHECKSUM(NEWID())) % 10; --ключ генерации на 10 вариантов
DECLARE @key2 INT = ABS(CHECKSUM(NEWID())) % 20; --ключ на 5%
DECLARE @key3 INT = ABS(CHECKSUM(NEWID())) % 10; --ключ генерации на 10 вариантов для подварианта с женщинами
DECLARE @key4 INT = ABS(CHECKSUM(NEWID())) % 5; --ключ на 20%
DECLARE @key5 INT = ABS(CHECKSUM(NEWID())) % 10; --ключ на 10 вариантов для почты
DECLARE @key6 INT = ABS(CHECKSUM(NEWID())) % 100; --ключ на 100 вариантов для сегмента

	INSERT INTO Clients (first_name, middle_name, last_name, phone, email, segment)
	VALUES(

	--first_name
	CASE @key1
	WHEN 0 THEN 'Никита'
	WHEN 1 THEN 'Афанасий'
	WHEN 2 THEN 'Максим'
	WHEN 3 THEN 'Юлия'
	WHEN 4 THEN 'Анастасия'
	WHEN 5 THEN 'Евгений'
	WHEN 6 THEN 'Александр'
	WHEN 7 THEN 'Федор'
	WHEN 8 THEN 'Владимир'
	WHEN 9 THEN 'Ольга'
	END,

	--middle_name
	CASE 
	WHEN @key2 = 0 THEN NULL --каждый двадцатый без отчества
	WHEN @key1 IN (3,4,9) THEN 
		CASE @key3 --женщины
		WHEN 0 THEN 'Петровна'
		WHEN 1 THEN 'Германовна'
		WHEN 2 THEN 'Никитична'
		WHEN 3 THEN 'Захаровна'
		WHEN 4 THEN 'Эдуардовна'
		WHEN 5 THEN 'Романовна'
		WHEN 6 THEN 'Харитоновна'
		WHEN 7 THEN 'Дмитриевна'
		WHEN 8 THEN 'Самсоновна'
		WHEN 9 THEN 'Леонидовна'
		END
	ELSE 
		CASE @key3 --МУЖИКИ
		WHEN 0 THEN 'Петрович'
		WHEN 1 THEN 'Германович'
		WHEN 2 THEN 'Джексонович'
		WHEN 3 THEN 'Игоревич'
		WHEN 4 THEN 'Эдуардович'
		WHEN 5 THEN 'Романович'
		WHEN 6 THEN 'Харитонович'
		WHEN 7 THEN 'Дмитриевич'
		WHEN 8 THEN 'Королевич'
		WHEN 9 THEN 'Мамутович'
		END
	END,

	--last_name
	CASE
	WHEN @I = 100 THEN 'Сорокин'
		WHEN @key1 IN (3,4,9) THEN 
		CASE @key3 --женщины
		WHEN 0 THEN 'Петрова'
		WHEN 1 THEN 'Васильева'
		WHEN 2 THEN 'Иванова'
		WHEN 3 THEN 'Орешкина'
		WHEN 4 THEN 'Данилова'
		WHEN 5 THEN 'Майонезова'
		WHEN 6 THEN 'Жириновская'
		WHEN 7 THEN 'Библеева'
		WHEN 8 THEN 'Зведочкина'
		WHEN 9 THEN 'Семакина'
		END
	ELSE 
		CASE @key3 --МУЖИКИ
		WHEN 0 THEN 'Краснов'
		WHEN 1 THEN 'Мурадов'
		WHEN 2 THEN 'Херсонов'
		WHEN 3 THEN 'Ольхов'
		WHEN 4 THEN 'Абобкин'
		WHEN 5 THEN 'Праймов'
		WHEN 6 THEN 'Сталин'
		WHEN 7 THEN 'Ленин'
		WHEN 8 THEN 'Бабушкин'
		WHEN 9 THEN 'Ширяев'
		END
	END,

	--phone
	'8800' + RIGHT('555000' + CAST(@i AS VARCHAR),7), --склеиваем 8800 + 7 крайних правых символов из строки 555000 + i

	--email
	CASE WHEN @key4 = 0 THEN NULL --у каждого 5 нет почты
	ELSE CASE @key5
		WHEN 0 THEN 'amogus' + CAST(@i AS VARCHAR) + '@pochta.ru'
		WHEN 1 THEN 'test' + CAST(@i AS VARCHAR) + '@gmail.ru'
		WHEN 2 THEN 'gucci' + CAST(@i AS VARCHAR) + '@super.com'
		WHEN 3 THEN 'easyjob' + CAST(@i AS VARCHAR) + '@gogo.ru'
		WHEN 4 THEN 'rushb' + CAST(@i AS VARCHAR) + '@csgo.com'
		WHEN 5 THEN 'zxc' + CAST(@i AS VARCHAR) + '@midlane.com'
		WHEN 6 THEN 'freakyahh' + CAST(@i AS VARCHAR) + '@elsemail.com'
		WHEN 7 THEN 'anyword' + CAST(@i AS VARCHAR) + '@random.ru'
		WHEN 8 THEN 'hoowermaxpro' + CAST(@i AS VARCHAR) + '@WW.com'
		WHEN 9 THEN 'iwannaalfa' + CAST(@i AS VARCHAR) + '@sobes.com'
		END
	END,
	
	--segment
	CASE 
		WHEN @key6 < 5 THEN 'vip' --5%
		WHEN @key6 < 10 THEN 'business' --5%
		WHEN @key6 < 30 THEN 'premium' --20%
		ELSE 'mass' --70%
	END
	);
	SET @i = @i + 1;
END

--через CAST((SELECT COUNT (*) FROM Specialists) AS VARCHAR) - не работает, потому что в CAST нельзя юзать подзапросы. Поэтому надо объявлять переменную. В других принтах ниже аналогично
DECLARE @clients_count INT;
SELECT @clients_count = COUNT(*) FROM Clients;
PRINT 'Clients заполнена: ' + CAST(@clients_count AS VARCHAR)  + ' записей';

INSERT INTO Products (product_type, product_name, product_description) VALUES 
('card', 'Дебетовая карта', 'Базовая карта без обслуживания'),
('card', 'Апельсиновая карта', 'Кешбек 7% в переке и пятерке'),
('card', 'Золотая карта', 'Кешбек на пиво и чипсы'),
('card', 'Платиновая карта', 'Лучшая карта для лучших людей'),
('deposit', 'Вклад "Накопительный"', 'До 0.15% годовых при условии еженедельного посещения церкви'),
('deposit', 'Вклад "На новый компик"', 'Деноминация счета при каждом изменении курса доллара'),
('deposit', 'Вклад "Бабушкин"', 'Снятие наличных без ограничений на сумму'),
('credit', 'Потребительский кредит', 'До 3 млн рублей на любые цели, кроме додепа'),
('credit', 'Автокредит', 'Специальные условия для покупки авто, ставка х2 при покупке линейки Lada'),
('credit', 'Ипотека', 'Минимальный срок кредитования - от 25 лет'),
('service', 'Мобильный банк', 'Управление средствами и пуш каждые 30 минут'),
('service', 'СМС уведомления', 'Уведомления об совершаемых операциях'),
('service', 'Интернет-банк', 'Доступ к банковскому аккаунту через браузер')

DECLARE @products_count INT;
SELECT @products_count = COUNT(*) FROM Products;
PRINT 'Products заполнена: ' + CAST(@products_count AS VARCHAR)  + ' записей';

DECLARE @k INT = 1
WHILE @k <= 30 
BEGIN
DECLARE @s_key1 INT = ABS(CHECKSUM(NEWID())) % 5; --ключ генерации на 5 вариантов
DECLARE @s_key2 INT = ABS(CHECKSUM(NEWID())) % 10; --ключ на 10%
DECLARE @s_key3 INT = ABS(CHECKSUM(NEWID())) % 5; --ключ для подварианта с женщинами
DECLARE @s_key5 INT = ABS(CHECKSUM(NEWID())) % 100; --ключ на 100 вариантов
	INSERT INTO Specialists (first_name, middle_name, last_name, department, specialization, is_active) VALUES (
	--first_name
	CASE @s_key1
	WHEN 0 THEN 'Никита'
	WHEN 1 THEN 'Станислав'
	WHEN 2 THEN 'Генадий'
	WHEN 3 THEN 'Анна'
	WHEN 4 THEN 'Кристина'
	END,

	--middle_name
	CASE 
	WHEN @s_key2 = 0 THEN NULL --каждый десятый без отчества
	WHEN @s_key1 IN (3,4) THEN 
		CASE @s_key3 --женщины
		WHEN 0 THEN 'Романовна'
		WHEN 1 THEN 'Евгеньевна'
		WHEN 2 THEN 'Борисовна'
		WHEN 3 THEN 'Кирилловна'
		WHEN 4 THEN 'Нурлановна'
		END
	ELSE 
		CASE @s_key3 --МУЖИКИ
		WHEN 0 THEN 'Львович'
		WHEN 1 THEN 'Хорусович'
		WHEN 2 THEN 'Жиллиманыч'
		WHEN 3 THEN 'Леонардович'
		WHEN 4 THEN 'Донателлович'
		END
	END,

	--last_name
	CASE
		WHEN @s_key1 IN (3,4) THEN 
		CASE @s_key3 --женщины
		WHEN 0 THEN 'Терешкова'
		WHEN 1 THEN 'Пушкина'
		WHEN 2 THEN 'Тополева'
		WHEN 3 THEN 'Саморезкина'
		WHEN 4 THEN 'Виноградова'
		END
	ELSE 
		CASE @s_key3 --МУЖИКИ
		WHEN 0 THEN 'Суворов'
		WHEN 1 THEN 'Кадиев'
		WHEN 2 THEN 'Зубарев'
		WHEN 3 THEN 'Хмельницкий'
		WHEN 4 THEN 'Жарков'
		END
	END,

	--department
	CASE
	WHEN @s_key5 < 7 THEN 'deploy' --7%
	WHEN @s_key5 < 17 THEN 'support' --10%
	WHEN @s_key5 < 37 THEN 'tech development' --20%
	ELSE 'normis'
	END,

	--specialization
	CASE 
	WHEN @s_key5 < 5 THEN NULL --5%
	WHEN @s_key5 < 20 THEN 'Карты' --15%
	WHEN @s_key5 < 45 THEN 'Кредиты' --25%
	WHEN @s_key5 < 55 THEN 'Вклады' --10%
	ELSE 'Общие вопросы/стажер'
	END,

	--is_active
	CASE WHEN (ABS(CHECKSUM(NEWID())) % 8) = 0 THEN 0 ELSE 1 END -- каждый 8 чилит
	);
	SET @k = @k + 1;
END



DECLARE @specialists_count INT;
SELECT @specialists_count = COUNT(*) FROM Specialists;
PRINT 'Specialists заполнена: ' + CAST(@specialists_count AS VARCHAR)  + ' записей';

INSERT INTO Categories (parent_id, category_name, sla_minutes) VALUES 
(NULL, 'Проблемы с картой', 60), --категория 1
(NULL, 'Проблемы с переводом', 60), --категория 2
(NULL, 'Вопросы по кредиту', 60), --категория 3
(NULL, 'Вопросы по вкладу', 60), --категория 4
(NULL, 'Технические пробелмы', 60) --категория 5

INSERT INTO Categories (parent_id, category_name, sla_minutes) VALUES
(1, 'Карта заблокирована', 30), --подкатегория 6 
(1, 'Утеря карты или её кража', 15), --подкатегория 7 
(1, 'Карта не работает за границей', 120), --подкатегория 8 
(2, 'Перевод не пришел', 20), --подкатегория 9 
(2, 'Проблемы с переводом', 30), --подкатегория 10 
(3, 'Высокая ставка', 240), --подкатегория 11 
(3, 'Досрочное погашение', 180), --подкатегория 12
(4, 'Изменений условий по вкладу', 100), --подкатегория 13
(4, 'Закрытие вклада', 40), --подкатегория 14
(5, 'Не работает приложение', 30), --подкатегория 15
(5, 'Восстановление пароля', 15) --подкатегория 16

DECLARE @categories_count INT;
SELECT @categories_count = COUNT(*) FROM Categories;
PRINT 'Categories заполнена: ' + CAST(@categories_count AS VARCHAR)  + ' записей';

DECLARE @j INT = 1
WHILE @j <= 200
BEGIN
	DECLARE @rand_client INT = (ABS(CHECKSUM(NEWID())) % 100) + 1; --100 клиентов
	DECLARE @rand_prod INT = (ABS(CHECKSUM(NEWID())) % 13) + 1; --13 продуктов
	--надо проверить, чтобы у чела не было двух одинаковых продуктов
	IF NOT EXISTS ( SELECT 1 FROM Client_products WHERE client_id = @rand_client AND product_id = @rand_prod)
	BEGIN 
	DECLARE @cc_key1 INT = ABS(CHECKSUM(NEWID())) % 100; --ключ генерации на 100 вариантов
	INSERT INTO Client_products (client_id, product_id, account_number, cp_status, balance) VALUES (
	@rand_client,
	@rand_prod,
	'322228' + RIGHT('00000000' + CAST(@j AS VARCHAR), 9),
	CASE 
	WHEN @cc_key1 < 5 THEN 'closed' --5%
	WHEN @cc_key1 < 13 THEN 'blocked' --8%
	ELSE 'active' --87%
	END,
	CAST((ABS(CHECKSUM(NEWID())) % 1150000 - 350000) AS DECIMAL (18,2))
	);
END
SET @j = @j + 1;
END

DECLARE @client_products_count INT;
SELECT @client_products_count = COUNT(*) FROM Client_products;
PRINT 'Client_products заполнена: ' + CAST(@client_products_count AS VARCHAR)  + ' записей';

DECLARE @m INT = 1;
WHILE @m<=500 
BEGIN --собираем случайную комбинацию из трех столбцов через newid
	DECLARE @cp_client INT;
	DECLARE @cp_product INT;
	DECLARE @cp_account VARCHAR(30);
	SELECT TOP 1 
		@cp_client = client_id,
		@cp_product = product_id,
		@cp_account = account_number  
	FROM Client_products
	ORDER BY NEWID(); --чтобы был случайный порядок

	DECLARE @days_ago INT = ABS(CHECKSUM(NEWID()))%180; --случайное количество дней, которое будет вычитать от текущей даты, в диапазоне от 0 до 179
	DECLARE @created_time DATETIME2 = DATEADD(DAY, -@days_ago, GETDATE()); --получаем дату создания\закрытия
	DECLARE @cp_key1 INT = ABS(CHECKSUM(NEWID())) % 100; --ключ генерации на 100 вариантов
	DECLARE @cp_key2 INT = ABS(CHECKSUM(NEWID())) % 10; --ключ генерации на 10 вариантов
	DECLARE @cp_key3 INT = ABS(CHECKSUM(NEWID())) % 100; --ключ генерации на 100 вариантов для channel
	DECLARE @category INT = ((ABS(CHECKSUM(NEWID())) % 11) + 6); --сначала определяем категорию
	DECLARE @category_sla INT;
	SELECT @category_sla = sla_minutes FROM Categories WHERE category_id = @category;

	--status
	DECLARE @status VARCHAR (20) =
	CASE 
	WHEN @cp_key1 < 35 THEN 'closed' --35%
	WHEN @cp_key1 < 65 THEN 'resolved' --30%
	ELSE CASE 
		WHEN @cp_key2 < 2 THEN 'new' -- 20%
		WHEN @cp_key2 < 4 THEN 'waiting' -- 20%
		ELSE 'in_work' --30%
		END
	END;
		
	

	--resolved_time
	/* изменил генерацию, чтобы не было безумных чисел в resolved*/
	DECLARE @resolved DATETIME2 = 
	CASE 
		WHEN @status IN ('resolved', 'closed') THEN
			CASE
				--70% решаются в рамках SLA
				WHEN (ABS(CHECKSUM(NEWID())) % 100) < 70 THEN 
				DATEADD(MINUTE,
				@category_sla * (ABS(CHECKSUM(NEWID())) % 80 + 15) / 100, -- 15-95% от SLA
				@created_time)
				--30% нарушают SLA
				ELSE
				DATEADD(MINUTE, 
				@category_sla * (ABS(CHECKSUM(NEWID())) % 70 + 120) / 100, --120-190% от SLA
				@created_time)
			END
		ELSE NULL --для new, waiting, in_work
	END;

	INSERT INTO Incidents (client_id, product_id, account_number, category_id, created_time, channel, incident_priority, incident_status, incident_description, resolved_time) VALUES (
	@cp_client, --client_id
	@cp_product, --product_id
	@cp_account, --account_number
	@category, 
	@created_time,
	--channel
	CASE 
	WHEN @cp_key3 < 5 THEN 'chat' --5%
	WHEN @cp_key3 < 10 THEN 'department' --5%
	WHEN @cp_key3 < 60 THEN 'phone' --50%
	WHEN @cp_key3 < 90 THEN 'app' --30%
	ELSE 'email' --10%
	END,
	--priority
	CASE 
	WHEN @cp_key2 = 0 THEN 'critical' --10%
	WHEN @cp_key2 < 3 THEN 'high' --20%
	WHEN @cp_key2 < 6 THEN 'medium' --30%
	ELSE 'low' --40%
	END,
	@status, --incident_status
	'Очередная проблема #' + CAST(@m AS VARCHAR) + ', клиент №' + CAST(@cp_client AS VARCHAR) + ' делает мозги по поводу ' + (SELECT TOP 1 category_name FROM Categories WHERE  category_id = @category),
	@resolved
	);
	SET @m = @m + 1;
END

DECLARE @incidents_count INT;
SELECT @incidents_count = COUNT(*) FROM Incidents;
PRINT 'Incidents заполнена: ' + CAST(@incidents_count AS VARCHAR)  + ' записей';

INSERT INTO Incident_history (incident_id, specialist_id, action_time, action_type, previous_status, new_status, ih_comment, time_spent) 
SELECT 
	incident_id,
	(ABS(CHECKSUM(NEWID()) % 30) + 1), --от 1 до 30 (кол-во спецов)
	created_time,
	'Создан инцидент',
	NULL,
	'new',
	'Инцидент зафиксирован в системе',
	NULL
FROM Incidents;
/* Созданы записи для только что появившихся инцидентов*/

INSERT INTO Incident_history (incident_id, specialist_id, action_time, action_type, previous_status, new_status, ih_comment, time_spent) 
SELECT 
	incident_id, 
	(ABS(CHECKSUM(NEWID()) % 30) + 1), --от 1 до 30 (кол-во спецов)
	DATEADD(MINUTE,(ABS(CHECKSUM(NEWID()) % 110) + 10), created_time), --добавляем время, от 10 до 120 минут
	CASE incident_status 
		WHEN 'waiting' THEN 'Запрошена дополнительная информация'
		ELSE 'Взято в работу'
	END,
	'new',
	CASE incident_status 
        WHEN 'waiting' THEN 'waiting'
        ELSE 'in_work'
    END,  
	'Специалист начал работу',
	(ABS(CHECKSUM(NEWID()) % 60) + 5) --потраченное время, от 5 до 65 минут
FROM Incidents
WHERE incident_status != 'new';
/* Создаются записи для уже НЕ НОВЫХ инцидентов*/

INSERT INTO Incident_history (incident_id, specialist_id, action_time, action_type, previous_status, new_status, ih_comment, time_spent) 
SELECT
	incident_id, --incident_id
	(ABS(CHECKSUM(NEWID()) % 30) + 1), --от 1 до 30 (кол-во спецов) specialist_id
	CASE 
		WHEN resolved_time IS NOT NULL THEN resolved_time
		ELSE DATEADD(minute, (ABS(CHECKSUM(NEWID()) % 240) + 30), created_time) --добавляем время, от 30 до 270 минут 
	END, --action_time
	CASE incident_status 
		WHEN 'resolved' THEN 'Инцидент решен'
		WHEN 'closed' THEN 'Инцидент закрыт'
	END, --action_type
	CASE incident_status 
		WHEN 'resolved' THEN 'in_work'
		WHEN 'closed' THEN 'resolved'
	END, --previous_status
	incident_status,
	'Проблема решена, все счастливы и пьют шампанское (пиво)',
	(ABS(CHECKSUM(NEWID()) % 120) + 10) --время на изменение, от 10 до 130 минут
FROM Incidents
WHERE incident_status IN ('resolved','closed');
/* Записи для решенных и закрытых инцидентов */

DECLARE @incident_history_count INT;
SELECT @incident_history_count = COUNT(*) FROM Incident_history;
PRINT 'Incidents_history заполнена: ' + CAST(@incident_history_count AS VARCHAR)  + ' записей';