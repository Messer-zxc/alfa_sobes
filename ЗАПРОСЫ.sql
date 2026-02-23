/* 
Запросы к созданной БД
Начало работы: 23.11.25 16:49
Конец работы: 29.11.25 15:42
Сорокин Никита
*/

USE ALFA_SOBES;
GO

/*
-----ПРОСТЕНЬКИЕ ЗАПРОСЫ--------
*/

--1. Статистика клиентов по сегментам
SELECT 
segment, --сегмент
COUNT (*) as client_count, --кол-во клиентов по сегментам
CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL (5,2)) AS segment_percentage --процентное распределение клиентов по сегментам, OVER используется чтобы считать сумму по строкам после группировки
FROM Clients
GROUP BY segment
ORDER BY client_count;

--2. Список АКТИВНЫХ специалистов по отделам
SELECT 
department, --отдел
COUNT(*) AS specialist_count, --кол-во активных специалистов
STRING_AGG((first_name + ' ' + CASE WHEN middle_name IS NOT NULL THEN middle_name ELSE '' END) + ' ' + last_name, CHAR(13) + CHAR(10)) as specialists_fio --фио, но в виде списка, т.к. есть группировка
FROM Specialists
WHERE is_active = 1
GROUP BY department
ORDER BY specialist_count DESC;

--3. Распределение инцидентов по статусам
SELECT 
incident_status, --статус
COUNT(*) as incidents_count, --кол-во инцидентов по статусу
CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) as status_percentage --процентовка по статусам
FROM Incidents
GROUP BY incident_status
ORDER BY incidents_count;


--4. Инциденты за последние N дней
DECLARE @days_past INT = 7;
SELECT
CAST(created_time AS DATE) AS creation_date, --когда создан в формате даты
COUNT(*) as incidents_created, --кол-во инцидентов
COUNT(CASE WHEN incident_status IN ('resolved', 'closed') THEN 1 END) as incidents_resolved --сколько решенных\закрытых инцидентов
FROM Incidents
WHERE created_time >= DATEADD(DAY,-@days_past, GETDATE()) --учет времени назад на @days_past дней
GROUP BY CAST(created_time AS DATE)
ORDER BY creation_date DESC;

/*
--------СРЕДНИЕ ЗАПРОСЫ--------
*/

--5. Топ N клиентов по инцидентам (проблемные типа)
DECLARE @count_top INT = 10;
SELECT TOP (@count_top) 
client_fio, --фио клиента
segment, --сегмент в котором клиент
total_incidents, --всего инцидентов у клиента
open_incidents, --инциденты в работе
CAST(open_incidents * 100.0 / total_incidents AS DECIMAL(5,2)) AS open_percentage --какой процент инцидентов в работе
FROM v_client_profile
WHERE total_incidents > 0
ORDER BY total_incidents DESC;

--6. Среднее время решения по категориям с оценкой(только закрытые\решенные инциденты)
SELECT
category_name, --категория проблемы
sla_minutes, --норматив SLA
total_incidents, --всего инц. в категории
avg_resolution_time, --среднее время решения
sla_violations, --наругений SLA
sla_violation_percent, --процент нарушений
CASE 
	WHEN sla_violation_percent < 25 THEN 'Отлично'
	WHEN sla_violation_percent < 35 THEN 'Хорошо'
	ELSE 'Дела идут не важно'
END AS perfomance --оценка решения инцидентов по категориям
FROM v_category_metrics
WHERE total_incidents > 0
ORDER BY sla_violation_percent DESC;

--7. Производительность специалистов (Топ N специалистов по количеству решенных)
DECLARE @number_of_top INT = 10;
SELECT TOP (@number_of_top)
specialist_fio, --ФИО
department, --отдел
specialization, --спецуха
total_incidents_taken, --всего инцидентов
resolved_count, --сколько закрыл инцидентов
CAST(resolved_count * 100.0 / total_incidents_taken AS DECIMAL (5,2)) AS resolution_rate, --процент закрытых инцидентов
CAST(total_time_spent_minutes/60.0 AS DECIMAL (5,2)) AS total_hours --всего потраченных часов на инциденты
FROM v_specialists_stats
WHERE is_active = 1 AND total_incidents_taken > 0
ORDER BY resolved_count DESC, resolution_rate DESC;


--8. Распределение каналов поступления инцидентов по приоритету
SELECT 
channel, --канал
incident_priority, --приоритет
COUNT(*) AS incident_count, --кол-во инцидентов
AVG(DATEDIFF(MINUTE, created_time, resolved_time)) as avg_response_time --среднее время ответа на обращение
FROM Incidents
WHERE resolved_time IS NOT NULL
GROUP BY channel,incident_priority
ORDER BY channel,incident_priority;


--9. Инциденты с нарушением SLA
SELECT 
incident_id, --id инцидента
client_id, --id клиента
segment, --сегмент
category_name, --имя категории
sla_minutes, --норматив SLA
resolution_minutes, --время решения инцидента
resolution_minutes - sla_minutes AS sla_violation, --на сколько минут нарушен SLA
incident_status, --текущий статус рассматриваемого инцидента
sla_result --выполнен норматив по SLA или нет
FROM v_incident_details 
WHERE SLA_result LIKE '%Нарушение%'
ORDER BY sla_violation DESC;

--10. Динамика создания инцидентов с накопительным итогом
WITH daily_stats AS( --создаем временную таблицу
	SELECT 
	CAST(created_time AS DATE) as incident_date, --дата создания
	COUNT(*) as daily_created, --кол-во созданных за день
	COUNT(CASE WHEN incident_status IN ('resolved','closed') THEN 1 END) as daily_resolved --кол-во решенных за день
	FROM Incidents
	WHERE created_time >= DATEADD(MONTH, -1, GETDATE())
	GROUP BY CAST(created_time AS DATE)
	)
SELECT 
incident_date,
daily_created,
SUM(daily_created) OVER (ORDER BY incident_date) as cumulative_created,
SUM(daily_resolved) OVER (ORDER BY incident_date) as cumulative_resolved
FROM daily_stats
ORDER BY incident_date;

-- 11. Рейтинг специалистов по скорости решения
WITH specialists_metrics AS (
    SELECT 
    specialist_id, --айди спеца
    specialist_fio, --фио спеца
    specialization, --специализация
    total_incidents_taken, --сколько всего инцидентов закрыл
    avg_time_per_action, --среднее время на изменение статуса 
    total_time_spent_minutes / 60.0 as total_hours --всего часов на инциденты
    FROM v_specialists_stats
    WHERE is_active = 1 
    AND total_incidents_taken >= 3
    AND avg_time_per_action IS NOT NULL --проверки на всякий случай
)
SELECT 
    specialist_fio,  --ФИО
    specialization, --спецуха
    total_incidents_taken, --сколько всего инцидентов закрыл
    CAST(avg_time_per_action AS DECIMAL(10,2)) as avg_minutes_per_action, --среднее время на изменение статуса 
    CAST(total_hours AS DECIMAL(10,2)) as total_hours, --всего часов на инциденты
    RANK() OVER (ORDER BY avg_time_per_action) AS speed_rank, --место по скорости решения инцидентов среди ВСЕХ
    DENSE_RANK() OVER (PARTITION BY specialization ORDER BY avg_time_per_action ) AS rank_in_spec --место внутри специализации
FROM specialists_metrics
ORDER BY speed_rank ,rank_in_spec;


--12. Клиенты с повторяющимися проблемами (одна категория >= 3 раз)
WITH client_issues AS (
    SELECT 
    client_id, --айди клиента
    client_name, --фио клиента
    segment, --сегмент
    category_name, --категория проблемы
    COUNT(*) as issue_count, --кол-во инцидентов
    MAX(created_time) as last_incident_date, --дата последнего инцидента
    ROW_NUMBER() OVER (PARTITION BY client_id ORDER BY COUNT(*) DESC) as issue_rank --нумерация категории инцидента по количеству
    FROM v_incident_details 
    GROUP BY client_id, client_name, segment, category_name
    HAVING COUNT(*) >= 3
    )
SELECT 
client_id, --айди клиента
client_name, --фио клиента
segment, --сегмент
category_name as most_frequent_issue, --тип самой частой проблемы
issue_count, --кол-во инцидентов
last_incident_date, --дата последнего инцидента
--issue_rank,
DATEDIFF(DAY, last_incident_date, GETDATE()) as days_since_last_incident --дней прошло с последнего инцидента
FROM client_issues
WHERE issue_rank = 1 --можно брать не только самый частый, но и например, топ 3 самых частых
ORDER BY issue_count DESC, issue_rank ASC; --добавил сторитровку по issue_rank для варианта описанного выше