/* 
Представления по таблицам, для использования в последующих запросах и т.д.
Начало работы: 16.11.25 17:02 
Конец работы:  23.11.25 1:32
Сорокин Никита
*/
USE ALFA_SOBES
GO

IF OBJECT_ID('v_incident_details','V') IS NOT NULL 
BEGIN
	DROP VIEW v_incident_details;
	PRINT('Ранее созданное представление v_incident_details удалено') ;
END
GO

IF OBJECT_ID('v_specialists_stats','V') IS NOT NULL 
BEGIN
	DROP VIEW v_specialists_stats;
	PRINT('Ранее созданное представление v_specialists_stats удалено') ;
END
GO

IF OBJECT_ID('v_client_profile','V') IS NOT NULL 
BEGIN
	DROP VIEW v_client_profile;
	PRINT('Ранее созданное представление v_client_profile удалено') ;
END
GO

IF OBJECT_ID('v_category_metrics','V') IS NOT NULL 
BEGIN
	DROP VIEW v_category_metrics;
	PRINT('Ранее созданное представление v_category_metrics удалено') ;
END
GO

--Полная сводка по инциденту
CREATE VIEW v_incident_details AS 
SELECT
i.incident_id, --номер инцидента
i.created_time, --когда возник инцидент
i.resolved_time, --когда решен/закрыт инцидент
DATEDIFF(MINUTE, i.created_time, i.resolved_time) AS resolution_minutes, --время решения проблемы, если не решено, то NULL
CASE 
	WHEN i.resolved_time IS NOT NULL AND DATEDIFF(MINUTE, i.created_time, i.resolved_time) > cat.sla_minutes 
	THEN 'Нарушение SLA!'
	WHEN i.resolved_time IS NOT NULL 
	THEN 'SLA соблюден'
	ELSE 'В работе'
END as sla_result, --проверка на соблюдение норматива SLA
c.client_id,
c.first_name + ' ' + ISNULL(c.middle_name, ' ') + ' ' + c.last_name AS client_name, --ФИО клиента
c.segment, --сегмент
c.phone, --телефон клиента
ISNULL(c.email, 'без почты') AS client_email, --почта клиента
p.product_id, --номер продукта
p.product_type, --тип продукта
p.product_name, --название продукта
cp.account_number, --номер аккаунта
cp.balance, --баланс клиента по продукту
cat.category_id, --номер категории инцидента
cat.category_name, --название категории инцидента
cat.sla_minutes, --SLA на решение инцидента
i.channel, --по какому каналу зареган инцидент
i.incident_priority, --приоритет инцидента
i.incident_status, --статус инцидента
i.incident_description --описание инцидента
FROM Incidents i 
JOIN Clients c ON i.client_id = c.client_id
JOIN Products p ON p.product_id = i.product_id
JOIN Client_products cp ON i.account_number = cp.account_number
JOIN Categories cat ON i.category_id = cat.category_id
GO

CREATE VIEW v_specialists_stats AS
SELECT
s.specialist_id, --айди
s.first_name + ' ' + (CASE WHEN s.middle_name IS NOT NULL THEN s.middle_name ELSE '' END)  + ' ' + s.last_name AS specialist_fio, --ФИО
s.department, --отдел
s.specialization, --спецуха
s.is_active, --жив?
COUNT(DISTINCT ih.incident_id) AS total_incidents_taken, --сколько инцидентов закрыл\взял работяга
SUM(ih.time_spent) AS total_time_spent_minutes, --сколько всего времени ушло на закрытие инцидентов
AVG(CAST(ih.time_spent AS DECIMAL (5,2))) AS avg_time_per_action, --в среднем времни на действие
COUNT(DISTINCT CASE WHEN ih.new_status IN ('resolved', 'closed') THEN ih.incident_id END) AS resolved_count --кол-во решенных инцидентов
FROM Specialists s
LEFT JOIN Incident_history ih ON s.specialist_id = ih.specialist_id
GROUP BY s.specialist_id, s.first_name, s.middle_name, s.last_name, s.department, s.specialization, s.is_active
GO	

CREATE VIEW v_client_profile AS
SELECT
c.client_id, --ID
c.first_name + ' ' + (CASE WHEN c.middle_name IS NOT NULL THEN c.middle_name ELSE '' END)  + ' ' + c.last_name AS client_fio, --ФИО
c.phone, --номер
c.email, --почта
c.segment, --сегмент
c.registration_date, --дата регистрации
COUNT (DISTINCT cp.product_id) AS products_count, --сколько всего продуктов у клиента
SUM(cp.balance) AS total_balance, --сумма по всем продуктам
COUNT(DISTINCT i.incident_id) AS total_incidents, --сколько всего инцидентов было у клиента
COUNT(DISTINCT CASE WHEN i.incident_status NOT IN ('resolved', 'closed') THEN i.incident_id END) AS open_incidents --сколько открытых инцидентов сейчас
FROM Clients c
LEFT JOIN Client_products cp ON c.client_id = cp.client_id
LEFT JOIN Incidents i ON c.client_id = i.client_id
GROUP BY c.client_id, c.first_name, c.middle_name, c.last_name, c.phone, c.email, c.segment,  c.registration_date
GO

CREATE VIEW v_category_metrics AS
SELECT
cat.category_id, --ID
cat.category_name, --имя категории
cat.parent_id, --родительская категория
cat.sla_minutes, --норматив SLA
COUNT(i.incident_id) AS total_incidents, --всего инцидентов по категории
AVG(DATEDIFF(MINUTE, i.created_time, i.resolved_time)) AS avg_resolution_time, --среднее время решения инцидентов по категориям
SUM(CASE WHEN DATEDIFF(MINUTE, i.created_time, ISNULL(i.resolved_time, GETDATE())) > cat.sla_minutes THEN 1 ELSE 0 END) AS sla_violations, --количество нарушений sla по категориям
CAST(
	SUM(CASE 
		WHEN i.resolved_time IS NOT NULL AND DATEDIFF(MINUTE, i.created_time, i.resolved_time) > cat.sla_minutes
		THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(CASE WHEN i.resolved_time IS NOT NULL THEN 1 END), 0)
	AS DECIMAL(5,2)) AS sla_violation_percent
/* Вот это чудище сверху подсчитывает количество ЗАКРЫТЫХ ИЛИ ЗАВЕРШЕННЫХ инцидентов (НЕ ПО ВСЕМ!), где нарушен SLA. Для перевода в % оказывается нужно писать 100.0 с нулем после точки, чтобы была дробная часть
Есть защита от деления на ноль через NULLIF, если в категории каким-то образом нет инцидентов (будет NULL если их 0). */
FROM Categories cat
LEFT JOIN Incidents i ON cat.category_id = i.category_id
GROUP BY cat.category_id, cat.category_name, cat.parent_id, cat.sla_minutes