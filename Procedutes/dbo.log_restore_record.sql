
-- =============================================
-- Author:      
-- Release:     
-- Description: Процедура восстанавливает запись из лога
-- =============================================

CREATE PROCEDURE [logs].[restore_record]
    @change_id int = NULL
    , @restore_previous bit = 0 -- для отката на предыдущее состояние - пока не реализовано
    , @confirm bit = 0
WITH EXECUTE AS OWNER
AS
BEGIN

BEGIN -- Change data --

SET NOCOUNT ON

DECLARE @message nvarchar(max)

IF @change_id IS NULL
    BEGIN
    SET @message = N'Уточните @change_id'
    RAISERROR(@message, 11, 0)
    RETURN
    END

IF @restore_previous IS NULL
    BEGIN
    SET @message = N'Уточните @restore_previous'
    RAISERROR(@message, 11, 0)
    RETURN
    END


DECLARE @source_schema nvarchar(128)
DECLARE @source_name nvarchar(128)
DECLARE @obj int
DECLARE @table_id int

SET @table_id = (select Table_ID from logs.TableLoggingData where id = @change_id)
SET @obj = (select Table_ID from logs.TableLoggingData where id = @change_id)
SET @source_schema =  (select sys.schemas.name from sys.tables inner join sys.schemas on sys.tables.schema_id = sys.schemas.schema_id where sys.tables.object_id = @table_id)
SET @source_name = (select [name] from sys.tables where sys.tables.object_id = @table_id)
    
-- PRINT CAST(@s1 AS nvarchar(max))

IF @obj IS NULL
    BEGIN
    SET @message = N'change_id %i не найден'
    RAISERROR(@message, 11, 0, @change_id)
    RETURN
    END

END

BEGIN -- Object data --

EXECUTE AS CALLER

DECLARE @obj_schema nvarchar(128)
DECLARE @obj_name nvarchar(128)

SELECT @obj_schema = SCHEMA_NAME([schema_id]), @obj_name = name FROM sys.objects WHERE [object_id] = @obj

IF @obj_name IS NULL
    BEGIN
    SELECT @obj_schema = SCHEMA_NAME([schema_id]), @obj_name = name, @obj = [object_id] FROM sys.objects
        WHERE name = @source_name AND [schema_id] = SCHEMA_ID(@source_schema)
    END

IF @obj_name IS NULL
    BEGIN
    SET @message = N'Table ''%s.%s'' not found'
    RAISERROR(@message, 11, 0, @source_schema, @source_name)
    RETURN
    END

IF HAS_PERMS_BY_NAME(QUOTENAME(@obj_schema) + '.' + QUOTENAME(@obj_name), 'OBJECT', 'UPDATE') = 0
    BEGIN
    SET @message = N'Нет прав UPDATE  на ''%s.%s'''
    RAISERROR(@message, 11, 0, @obj_schema, @obj_name)
    RETURN
    END

END

BEGIN -- SQL --

DECLARE @set nvarchar(max) = ''
DECLARE @where nvarchar(max) = ''
DECLARE @obj_names nvarchar(max) = ''
DECLARE @values nvarchar(max) = ''
DECLARE @is_identity int =0

declare @json varchar(max)
set @json =  (select REPLACE( REPLACE( str_json, '[{','{'),'}]','}') from logs.TableLoggingData where id = @change_id)

SELECT
    @set = @set + CASE WHEN is_pk = 1 THEN '' ELSE ', ' + t.name + ' = ' + t.value END
    , @where = @where + CASE WHEN is_pk = 0 THEN '' ELSE ' AND ' + t.name + ' = ' + t.value END
    , @obj_names = @obj_names + ', ' + t.name
    , @values = @values + ', ' + t.value
    , @is_identity = @is_identity + is_identity
FROM
    (
    SELECT
        QUOTENAME(c.name) AS name
        , CASE WHEN t1.[value] IS NULL THEN 'NULL'
            WHEN tp.name IN ('nvarchar', 'nchar', 'ntext', 'varchar', 'char', 'varbinary', 'binary', 'text', 'uniqueidentifier', 'xml', 'timestamp')
                THEN 'N''' + REPLACE(CAST(t1.value AS nvarchar), '''', '''''') + ''''
            WHEN tp.name IN ('datetime', 'datetime2', 'smalldatetime', 'date', 'time', 'datetimeoffset') THEN '''' + CAST(t1.[value] AS nvarchar) + ''''
            ELSE CAST(t1.[value] AS nvarchar)
            END AS value
        , CASE WHEN ic.column_id IS NOT NULL THEN 1 ELSE 0 END AS is_pk
        , c.is_identity
    FROM
        sys.columns c
        LEFT OUTER JOIN (
            SELECT
                logs.get_unescaped_parameter_name(t2.[key]) AS name
                , t1.[value]
            FROM
                OpenJson(@json) t1
                INNER JOIN OpenJson(@json) t2 ON t2.[key] = t1.[key]
            --WHERE
              --  t2.nodetype = 2
        ) t1 ON t1.name = c.name
        LEFT OUTER JOIN sys.indexes i ON i.[object_id] = c.[object_id] AND i.is_primary_key = 1
        LEFT OUTER JOIN sys.index_columns ic ON ic.[object_id] = c.[object_id] AND ic.column_id = c.column_id AND ic.index_id = i.index_id
        INNER JOIN sys.types tp ON tp.user_type_id = c.user_type_id
    WHERE
        c.[object_id] = @table_id 
    ) t




SET @set = SUBSTRING(@set, 3, LEN(@set))
SET @where = SUBSTRING(@where, 6, LEN(@where))
SET @obj_names = SUBSTRING(@obj_names, 3, LEN(@obj_names))
SET @values = SUBSTRING(@values, 3, LEN(@values))

DECLARE @sql nvarchar(max)

print '@is_identity'
print @is_identity

SET @sql =
      'UPDATE ' + QUOTENAME(@obj_schema) + '.' + QUOTENAME(@obj_name) + CHAR(13) + CHAR(10)
    + 'SET' + CHAR(13) + CHAR(10)
    + '    ' + @set + CHAR(13) + CHAR(10)
    + 'WHERE ' + CHAR(13) + CHAR(10)
    + '    ' + @where + CHAR(13) + CHAR(10)
    + CHAR(13) + CHAR(10)
    + 'IF @@ROWCOUNT = 0' + CHAR(13) + CHAR(10)
    + CASE WHEN @is_identity = 0 THEN '' ELSE
      '    BEGIN' + CHAR(13) + CHAR(10)
    + '    SET IDENTITY_INSERT ' + QUOTENAME(@obj_schema) + '.' + QUOTENAME(@obj_name) + ' ON' + CHAR(13) + CHAR(10)
        END
    + '    INSERT INTO ' + QUOTENAME(@obj_schema) + '.' + QUOTENAME(@obj_name) + CHAR(13) + CHAR(10)
    + '       (' + @obj_names + ')' + CHAR(13) + CHAR(10)
    + '    VALUES ' + CHAR(13) + CHAR(10)
    + '       (' + @values + ')' + CHAR(13) + CHAR(10)
    + CASE WHEN @is_identity = 0 THEN '' ELSE
      '    SET IDENTITY_INSERT ' + QUOTENAME(@obj_schema) + '.' + QUOTENAME(@obj_name) + ' OFF' + CHAR(13) + CHAR(10)
    + '    END' + CHAR(13) + CHAR(10)
        END

END

BEGIN -- EXEC --

IF @confirm = 1
    BEGIN
    EXEC (@sql)

    REVERT
    END
ELSE
    BEGIN
    SET @message = N'Установите @confirm = 1 для восстановления записи.' + CHAR(13) + CHAR(10)
    + CHAR(13) + CHAR(10)
    + N'SQL код для восстановления' + CHAR(13) + CHAR(10)
    + CHAR(13) + CHAR(10)
    PRINT @message + @sql
    END

END

END


