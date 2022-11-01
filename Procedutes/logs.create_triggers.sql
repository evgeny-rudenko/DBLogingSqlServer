create PROCEDURE [logs].[create_trigger]
    @schema nvarchar(128) = NULL
    , @name nvarchar(128) = NULL
    , @execute_script bit = 0
    
WITH EXECUTE AS CALLER
AS
BEGIN

DECLARE @message nvarchar(max)
DECLARE @shema_id nvarchar(100)
DECLARE @table_id nvarchar(100)
DECLARE @db_id nvarchar(100)

IF @schema IS NULL AND @name IS NOT NULL AND CHARINDEX('.', @name) > 1
    BEGIN
    SET @schema = LEFT(@name, CHARINDEX('.', @name) - 1)
    SET @name = SUBSTRING(@name, CHARINDEX('.', @name) + 1, LEN(@name))
    END

IF @schema IS NULL OR @name IS NULL
    BEGIN
    SET @message = N'Не все параметры'
    RAISERROR(@message, 11, 0);
    RETURN
    END


IF LEFT(@schema, 1) = '[' AND RIGHT(@schema, 1) = ']'
    SET @schema = REPLACE(SUBSTRING(@schema, 2, LEN(@schema) - 2), ']]', ']')

IF LEFT(@name, 1) = '[' AND RIGHT(@name, 1) = ']'
    SET @name = REPLACE(SUBSTRING(@name, 2, LEN(@name) - 2), ']]', ']')

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = @schema)
    BEGIN
    SET @message = 'Нет такой схемы'
    RAISERROR(@message, 11, 0);
    RETURN
    END
SET @shema_id = (SELECT schema_id FROM sys.schemas WHERE name = @schema)

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @name)
    BEGIN
    SET @message = 'Нет такой таблицы'
    RAISERROR(@message, 11, 0);
    RETURN
    END

SET @table_id = (SELECT object_id FROM sys.tables WHERE name = @name)

SET @db_id = (SELECT DB_ID())

SET NOCOUNT ON

DECLARE @sql1 nvarchar(MAX), @sql2 nvarchar(MAX), @sql3 nvarchar(MAX),
        @sql4 nvarchar(MAX), @sql5 nvarchar(MAX), @sql6 nvarchar(MAX),
        @sql7 nvarchar(MAX), @sql8 nvarchar(MAX), @sql9 nvarchar(MAX),
        @sql10 nvarchar(MAX)

SELECT 
    @sql1 ='
IF OBJECT_ID(N'''  + REPLACE(QUOTENAME(@schema) + '.' + QUOTENAME('trigger_' + @name + '_log_insert'), '''', '''''') + ''') IS NOT NULL
    DROP TRIGGER ' +         QUOTENAME(@schema) + '.' + QUOTENAME('trigger_' + @name + '_log_insert')
    , @sql2 = '
IF OBJECT_ID(N'''  + REPLACE(QUOTENAME(@schema) + '.' + QUOTENAME('trigger_' + @name + '_log_update'), '''', '''''') + ''') IS NOT NULL
    DROP TRIGGER ' +         QUOTENAME(@schema) + '.' + QUOTENAME('trigger_' + @name + '_log_update')
    , @sql3 = '
IF OBJECT_ID(N'''  + REPLACE(QUOTENAME(@schema) + '.' + QUOTENAME('trigger_' + @name + '_log_delete'), '''', '''''') + ''') IS NOT NULL
    DROP TRIGGER ' +         QUOTENAME(@schema) + '.' + QUOTENAME('trigger_' + @name + '_log_delete')
    , @sql4 = '
CREATE' + ' TRIGGER ' + QUOTENAME(@schema) + '.' + QUOTENAME('trigger_' + @name + '_log_insert') + '
    ON ' + QUOTENAME(@schema) + '.' + QUOTENAME(@name) + '
    AFTER INSERT
AS
BEGIN

SET NOCOUNT ON

DECLARE @username nvarchar(max)

EXECUTE AS CALLER

SELECT @username = USER_NAME()

REVERT

INSERT INTO logs.TableLoggingData 
						(
						Base_ID, 
						Table_ID,
						[DateAdd],
						is_type,
						HostName,
						ProgramName,
						Proc_ID,
						SystemUser,
						Str_json)
SELECT
      ' + CAST(@db_id AS nvarchar) + '
    , ' + CAST(@table_id AS nvarchar) + '
    , GETDATE ()
    , 1
    ,HOST_NAME()
	,PROGRAM_NAME()
	,@@PROCID
	,SYSTEM_USER
	,(SELECT I.* FOR JSON PATH)
FROM
    inserted I

END'
    , @sql5 = '
CREATE' + ' TRIGGER ' + QUOTENAME(@schema) + '.' + QUOTENAME('trigger_' + @name + '_log_update') + '
    ON ' + QUOTENAME(@schema) + '.' + QUOTENAME(@name) + '
    
    AFTER UPDATE
AS
BEGIN

SET NOCOUNT ON

DECLARE @username nvarchar(max)

EXECUTE AS CALLER

SELECT @username = USER_NAME()

REVERT

END'
    , @sql6 = '
CREATE' + ' TRIGGER ' + QUOTENAME(@schema) + '.' + QUOTENAME('trigger_' + @name + '_log_delete') + '
    ON ' + QUOTENAME(@schema) + '.' + QUOTENAME(@name) + '
    
    AFTER DELETE
AS
BEGIN

SET NOCOUNT ON

DECLARE @username nvarchar(max)

EXECUTE AS CALLER

SELECT @username = USER_NAME()

REVERT

INSERT INTO logs.TableLoggingData 
						(
						Base_ID, 
						Table_ID,
						[DateAdd],
						is_type,
						HostName,
						ProgramName,
						Proc_ID,
						SystemUser,
						Str_json)
SELECT
      ' + CAST(@db_id AS nvarchar) + '
    , ' + CAST(@table_id AS nvarchar) + '
    , GETDATE ()
    , 1
    ,HOST_NAME()
	,PROGRAM_NAME()
	,@@PROCID
	,SYSTEM_USER
	,(SELECT D.* FOR JSON PATH)
FROM
    deleted D

END'
DECLARE @br nvarchar(100) = ';' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) + 'GO' + CHAR(13) + CHAR(10)

-- PRINT @sql1 + @br + @sql2 + @br + @sql3 + @br + @sql4 + @br + @sql5 + @br + @sql6 + @br + @sql7 + @br + @sql8 + @br + @sql9 + @br

IF @execute_script = 1
    BEGIN
    EXEC (@sql1)
    EXEC (@sql2)
    EXEC (@sql3)
    EXEC (@sql4)
    EXEC (@sql5)
    EXEC (@sql6)
    EXEC (@sql7)
    EXEC (@sql8)
    EXEC (@sql9)
    EXEC (@sql10)
    END
ELSE
    BEGIN
    RAISERROR(@sql1, 0, 1) WITH NOWAIT
    RAISERROR('GO',  0, 1) WITH NOWAIT
    RAISERROR(@sql2, 0, 1) WITH NOWAIT
    RAISERROR('GO',  0, 1) WITH NOWAIT
    RAISERROR(@sql3, 0, 1) WITH NOWAIT
    RAISERROR('GO',  0, 1) WITH NOWAIT
    RAISERROR(@sql4, 0, 1) WITH NOWAIT
    RAISERROR('GO',  0, 1) WITH NOWAIT
    RAISERROR(@sql5, 0, 1) WITH NOWAIT
    RAISERROR('GO',  0, 1) WITH NOWAIT
    RAISERROR(@sql6, 0, 1) WITH NOWAIT
    RAISERROR('GO',  0, 1) WITH NOWAIT
    RAISERROR(@sql7, 0, 1) WITH NOWAIT
    RAISERROR('GO',  0, 1) WITH NOWAIT
    RAISERROR(@sql8, 0, 1) WITH NOWAIT
    RAISERROR('GO',  0, 1) WITH NOWAIT
    RAISERROR(@sql9, 0, 1) WITH NOWAIT
    RAISERROR('GO',  0, 1) WITH NOWAIT
    RAISERROR(@sql10, 0, 1) WITH NOWAIT
    RAISERROR('GO',  0, 1) WITH NOWAIT
    --PRINT @sql1
    --PRINT 'GO'
    --PRINT @sql2
    --PRINT 'GO'
    --PRINT @sql3
    --PRINT 'GO'
    --PRINT @sql4
    --PRINT 'GO'
    --PRINT @sql5
    --PRINT 'GO'
    --PRINT @sql6
    --PRINT 'GO'
    --PRINT @sql7
    --PRINT 'GO'
    --PRINT @sql8
    --PRINT 'GO'
    --PRINT @sql9
    --PRINT 'GO'
    --PRINT @sql10
    --PRINT 'GO'
    END

END


