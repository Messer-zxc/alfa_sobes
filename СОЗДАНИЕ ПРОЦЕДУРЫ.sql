/* 
Хранимая процедура для создания инцидента
Начало работы: 29.11.25 09:45
Конец работы: 29.11.25 16:13
Сорокин Никита
*/

USE ALFA_SOBES;
GO

IF OBJECT_ID('sp_create_incident','P') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_create_incident;
    PRINT('Ранее созданная продедура sp_create_incident удалена') ;
END
GO


CREATE PROCEDURE sp_create_incident
@client_id INT,
@product_id INT,
@account_number VARCHAR(30),
@category_id INT,
@channel VARCHAR(20),
@priority VARCHAR(10),
@description NVARCHAR(3000)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @new_incident_id INT;
DECLARE @random_specialist_id INT;
--Начало транзакции
BEGIN TRANSACTION;
	BEGIN TRY
	INSERT INTO Incidents (
    client_id, 
    product_id, 
    account_number, 
    category_id, 
    channel, 
    incident_priority, 
    incident_status, 
    incident_description
    )
    VALUES (
    @client_id, 
    @product_id, 
    @account_number, 
    @category_id, 
    @channel, 
    @priority, 
    'new', 
    @description
    );
    --Получаем ID созданного инцидента
    SET @new_incident_id = SCOPE_IDENTITY(); 
    -- Назначаем случайного активного специалиста
    SELECT TOP 1 @random_specialist_id = specialist_id 
    FROM Specialists 
    WHERE is_active = 1 
    ORDER BY NEWID();

    --Первая запись в истории
    INSERT INTO Incident_history (
    incident_id, 
    specialist_id, 
    action_type, 
    previous_status, 
    new_status, 
    ih_comment
    )
    VALUES (
    @new_incident_id, 
    @random_specialist_id, 
    'Создан инцидент', 
    NULL, 
    'new', 
    'Инцидент зафиксирован в системе'
    );
    --Фиксация транзакции
    COMMIT TRANSACTION;
    --Получаем и выводим инфу про создание инцидента
    SELECT 
    @new_incident_id AS new_incident_id,
    'Success' AS result,
    'Инцидент успешно создан' AS message;
    END TRY
    BEGIN CATCH
    -- Откат транзакции при ошибке
    ROLLBACK TRANSACTION;
    PRINT('Ошибка при транзакции');
    END CATCH
END;

 
 /*

 --Код для проверки процедуры
DECLARE @test_client INT = 2;
DECLARE @test_product INT = 1;
DECLARE @test_account VARCHAR(30);
SELECT TOP 1 @test_account = account_number 
FROM Client_products 
WHERE client_id = @test_client AND product_id = @test_product;
EXEC sp_create_incident 
    @client_id = @test_client,
    @product_id = @test_product,
    @account_number = @test_account,
    @category_id = 6,
    @channel = 'phone',
    @priority = 'medium',
    @description = 'Тестовый инцидент для проверки процедуры';
SELECT TOP 1 * FROM Incident_history ORDER BY incident_id DESC;
SELECT TOP 1 * FROM Incidents ORDER BY incident_id DESC;

*/