-- This stored procedure takes an SQL SELECT statement, creates a table from its result, and generates a stored procedure to insert data into that table.

CREATE  PROCEDURE [utility].[sp_create_T1_dimension_view_based_proc]
    @Target_Schema SYSNAME = NULL, -- SYSNAME is equivalent to NVARCHAR(128), used for SQL Server identifiers like schema names
    @Target_Table_Name SYSNAME = NULL, -- SYSNAME is equivalent to NVARCHAR(128), used for SQL Server identifiers like table names
    @Source_View_Schema SYSNAME = NULL, -- SYSNAME is equivalent to NVARCHAR(128), used for SQL Server identifiers like schema names
    @Source_View_Name SYSNAME = NULL, -- SYSNAME is equivalent to NVARCHAR(128), used for SQL Server identifiers like view names
    @Switch_Schema SYSNAME = NULL, -- SYSNAME is equivalent to NVARCHAR(128), used for SQL Server identifiers like schema names
    @BKs NVARCHAR(MAX) = NULL, -- Comma-separated value like 'BK1,BK2'
    @Include_DW_ValidFrom bit = 1,
    @DeleteObjects bit = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartOfUniverse datetime2(7)= '1900-01-01'
    DECLARE @EndOfUniverse datetime2(7) = '9999-12-31 23:59:59.9999999'

    SELECT @Target_Schema = PARSENAME(@Target_Schema,1)
    SELECT @Target_Table_Name = PARSENAME(@Target_Table_Name,1)
    SELECT @Source_View_Schema = PARSENAME(@Source_View_Schema,1)
    SELECT @Source_View_Name = PARSENAME(@Source_View_Name,1)
    SELECT @Switch_Schema = PARSENAME(@Switch_Schema,1)

    -- Step 1: Prepare variables for use in SQL statements
    DECLARE @createTableSql NVARCHAR(MAX);
    DECLARE @insertProcSql NVARCHAR(MAX);
    DECLARE @DropObj NVARCHAR(MAX);
    DECLARE @Target_Schema_bracket SYSNAME = QUOTENAME(@Target_Schema);
    DECLARE @Target_Table_Name_bracket SYSNAME = QUOTENAME(@Target_Table_Name);
    DECLARE @Source_View_Schema_bracket SYSNAME = QUOTENAME(@Source_View_Schema);
    DECLARE @Source_View_Name_bracket SYSNAME = QUOTENAME(@Source_View_Name);
    DECLARE @Switch_Schema_bracket SYSNAME = QUOTENAME(@Switch_Schema);
    DECLARE @Switch_Table_Name_bracket SYSNAME = @Target_Table_Name_bracket;
    DECLARE @BK_Cols_With_Brackets NVARCHAR(MAX) = '';
    DECLARE @KeyVault_BK_Cols_With_Brackets NVARCHAR(MAX)= ''
    DECLARE @KeyVault_BK_Join NVARCHAR(MAX) = ''
    DECLARE @Cols_With_Brackets nvarchar(max) = ''
    DECLARE @Unkown_Member_Insert nvarchar(max) = '-1'

    DECLARE @HowTo NVARCHAR(MAX) = '
EXEC utility.sp_create_T1_dimension_view_based_proc
    @Target_Schema = ''dim'',
    @Target_Table_Name = ''NewTable'',
    @Source_View_Schema = ''stg'',
    @Source_View_Name = ''SomeView'',
    @Switch_Schema = ''switch'',
    @BKs = ''BK1,BK2'',
    @Include_DW_ValidFrom = 1
'

    IF (
        @Target_Schema IS NULL
        OR @Target_Table_Name IS NULL
        OR @Source_View_Schema IS NULL 
        OR @Source_View_Name IS NULL
        OR @Switch_Schema IS NULL
        OR @BKs IS NULL 
    )
    BEGIN
        PRINT @HowTo;
        RETURN 0;
    END


    -- Use a CTE to parse and add brackets to BK columns
    ;WITH BK AS (
        SELECT 
            PARSENAME(bk.[value], 1) AS bks,
            ROW_NUMBER() OVER(ORDER BY (select 0)) rwn
        FROM STRING_SPLIT(@BKs, ',') bk
    )
    SELECT @BK_Cols_With_Brackets += QUOTENAME(bks) + ','
    ,@KeyVault_BK_Cols_With_Brackets += '[BK_Col' + CAST(rwn as varchar(10)) +'],'
    ,@KeyVault_BK_Join += 'AND' + char(9) + 'sk.[BK_Col' + CAST(rwn as varchar(10)) + '] = CAST(dd.' + QUOTENAME(bks) + ' as nvarchar(255))'
    FROM BK;



    ;with cols as (
        SELECT 
            COLUMN_NAME col
            ,DATA_TYPE
            ,CHARACTER_MAXIMUM_LENGTH
            ,IS_NULLABLE
            ,NUMERIC_PRECISION
            ,DATETIME_PRECISION
        FROM INFORMATION_SCHEMA.COLUMNS c
        where TABLE_SCHEMA = @Source_View_Schema
        AND TABLE_NAME = @Source_View_Name
        
    )
    SELECT 
        @Cols_With_Brackets += ',dd.' + QUOTENAME(col)
        ,@Unkown_Member_Insert += char(10) + ',' +
        CASE 
            WHEN CHARACTER_MAXIMUM_LENGTH IS NOT NULL THEN 
                CASE WHEN CHARACTER_MAXIMUM_LENGTH > 7 OR CHARACTER_MAXIMUM_LENGTH = -1 THEN '''UNKNOWN'''
                     WHEN CHARACTER_MAXIMUM_LENGTH BETWEEN 2 AND 7 THEN 'NA'
                END
            WHEN CHARACTER_MAXIMUM_LENGTH IS NULL AND DATETIME_PRECISION IS NOT NULL THEN 
                CASE WHEN DATA_TYPE LIKE '%date%' THEN ''''+ CAST(@StartOfUniverse as varchar(255)) +''''
                     WHEN DATA_TYPE = 'time' then '''' + CAST('00:00:00' as varchar(255)) + ''''
                END
            WHEN CHARACTER_MAXIMUM_LENGTH IS NULL AND DATETIME_PRECISION IS NULL THEN
                CASE WHEN NUMERIC_PRECISION IS NULL THEN CAST(0 as nvarchar(5)) ELSE CAST(0.0 as nvarchar(5)) END
            else '' END
        + ' AS ' +  QUOTENAME(col)
    FROM cols




-- print(@Unkown_Member_Insert)
print (@Cols_With_Brackets)
print @Source_View_Schema
print @Source_View_Name

    -- Remove trailing comma
    SET @BK_Cols_With_Brackets = LEFT(@BK_Cols_With_Brackets, LEN(@BK_Cols_With_Brackets) - 1);
    SET @KeyVault_BK_Cols_With_Brackets = LEFT(@KeyVault_BK_Cols_With_Brackets, LEN(@KeyVault_BK_Cols_With_Brackets) - 1);
    
    -- Base SQL for creating the target and switch tables
    SET @createTableSql = '
                            DROP TABLE IF EXISTS <Target_Schema>.<Target_Table>
                            DROP TABLE IF EXISTS <Switch_Schema>.<Switch_Table>
                            SELECT TOP 0 CAST(0 AS BIGINT) AS <Target_Table_No_Bracket>_key,* INTO <Target_Schema>.<Target_Table> FROM <Source_View_Schema>.<Source_View_Name>;
                            SELECT TOP 0 CAST(0 AS BIGINT) AS <Target_Table_No_Bracket>_key,* INTO <Switch_Schema>.<Switch_Table> FROM <Source_View_Schema>.<Source_View_Name>';
    SET @createTableSql = REPLACE(@createTableSql, '<Target_Schema>', @Target_Schema_bracket);
    SET @createTableSql = REPLACE(@createTableSql, '<Target_Table>', @Target_Table_Name_bracket);
    SET @createTableSql = REPLACE(@createTableSql, '<Switch_Schema>', @Switch_Schema_bracket);
    SET @createTableSql = REPLACE(@createTableSql, '<Switch_Table>', @Switch_Table_Name_bracket);
    SET @createTableSql = REPLACE(@createTableSql, '<Source_View_Schema>', @Source_View_Schema_bracket);
    SET @createTableSql = REPLACE(@createTableSql, '<Source_View_Name>', @Source_View_Name_bracket);
    SET @createTableSql = REPLACE(@createTableSql, '<Target_Table_No_Bracket>', PARSENAME(@Target_Table_Name_bracket,1));
    
    print @createTableSql
    EXEC sp_executesql @createTableSql;
    
    -- Step 2: Generate a stored procedure to insert data into the new table
    -- Base SQL for creating the insert procedure
    SET @insertProcSql = '
    CREATE OR ALTER PROCEDURE <Target_Schema>.sp_<Target_Table>
    AS
    BEGIN

        /* Script used to create this

        EXEC utility.sp_create_T1_dimension_view_based_proc
            @Target_Schema = ''<Target_Schema>'',
            @Target_Table_Name = ''<Target_Table_Name>'',
            @Source_View_Schema = ''<Source_View_Schema_NoBracket>'',
            @Source_View_Name = ''<Source_View_Name_NoBracket>'',
            @Switch_Schema = ''<Switch_Schema>'',
            @BKs = ''<BK_Cols_WithBrackets>'',
            @Include_DW_ValidFrom = <Include_DW_ValidFrom>
        */

        SET NOCOUNT ON;

        DECLARE @sql_chk_dupl NVARCHAR(MAX);
        DECLARE @cnt_dupl INT = 0;
        DECLARE @err_msg NVARCHAR(MAX);
        DECLARE @StartOfUniverse datetime2(7)= ''1900-01-01''
        DECLARE @EndOfUniverse datetime2(7) = ''9999-12-31 23:59:59.9999999''

        -- Duplicate check based on bk columns
        SET @sql_chk_dupl = ''
        ;WITH cte AS (
            SELECT *,
                COUNT(0) OVER(PARTITION BY <BK_Cols_WithBrackets>) AS cnt_1
            FROM <Source_View_Schema>.<Source_View_Name>
        )
        SELECT @cnt_dupl_out = COUNT(0)
        FROM cte
        WHERE cnt_1 > 1;'';


        -- Execute the dynamic SQL and use @cnt_dupl as an output parameter
        EXEC sp_executesql @sql_chk_dupl, N''@cnt_dupl_out INT OUTPUT'', @cnt_dupl_out = @cnt_dupl OUTPUT;

        -- Check for duplicates and raise an error if any are found
        IF @cnt_dupl > 0
        BEGIN
            SET @err_msg = ''Duplicate entry based on BK columns. Please use: '' + @sql_chk_dupl;
            RAISERROR (@err_msg, 16, 1);
            RETURN;
        END

        DROP TABLE IF EXISTS temp.<Target_Table>;
        SELECT *
        INTO temp.<Target_Table>
        FROM <Source_View_Schema>.<Source_View_Name>;
        


        INSERT INTO KeyVault.SurrogateKeys (
            <DW_ValidFrom_Insert>
            SourceSchema,
            SourceTable,
            <KeyVault_BKs>
        )
        SELECT 
            <DW_ValidFrom_Select>
            ''<Target_Schema>'',
            ''<Target_Table_Name>'',
            <KV_BK_Cols_WithBrackets>
        FROM temp.<Target_Table> dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = ''<Target_Schema>''
            AND sk.SourceTable = ''<Target_Table_Name>''
            <KeyVault_Join>
            <DW_ValidFrom_Join>
        WHERE sk.Surrogate_Key IS NULL;

        DROP TABLE IF EXISTS <Switch_Schema>.<Switch_Table>

        SELECT 
            sk.Surrogate_key <Target_Table_Name>_Key
            <Cols_WithBrackets>
        into <Switch_Schema>.<Switch_Table>
        FROM temp.<Target_Table> dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = ''<Target_Schema>''
            AND sk.SourceTable = ''<Target_Table_Name>''
            <KeyVault_Join>
            <DW_ValidFrom_Join>
        WHERE sk.Surrogate_Key IS NOT NULL;


        INSERT INTO <Switch_Schema>.<Switch_Table> 
        (
            <Target_Table_Name>_Key
            <Cols_WithBrackets_Insert>
        )
        SELECT 
            <Unkown_Member_Insert>

        DROP TABLE IF EXISTS temp.<Target_Table>

        EXEC utility.SwitchTableProcedure 
            @Switch_Schema = ''<Switch_Schema_NoBracket>''
            ,@switch_table_name=''<Switch_Table_NoBracket>''
            ,@Target_Schema=''<Target_Schema_NoBracket>''
            ,@Target_Table_Name = ''<Target_Table_Name_NoBracket>''
            ,@force_switch = 1
            ,@accepted_pct = 0


    END';

SET @DropObj = '
    DROP TABLE IF EXISTS <Target_Schema>.<Target_Table>
    DROP TABLE IF EXISTS <Switch_Schema>.<Switch_Table>
    DROP TABLE IF EXISTS temp.<Target_Table>
    DROP PROC  IF EXISTS <Target_Schema>.sp_<Target_Table>
    
'

    IF @DeleteObjects = 1
    BEGIN
        SET @insertProcSql = @DropObj

    END


    SET @insertProcSql = REPLACE(@insertProcSql, '<Target_Schema>', PARSENAME(@Target_Schema_bracket,1));
    SET @insertProcSql = REPLACE(@insertProcSql, '<Target_Table>', @Target_Table_Name);
    SET @insertProcSql = REPLACE(@insertProcSql, '<Source_View_Schema>', @Source_View_Schema_bracket);
    SET @insertProcSql = REPLACE(@insertProcSql, '<Source_View_Schema_NoBracket>', PARSENAME(@Source_View_Schema_bracket,1));
    SET @insertProcSql = REPLACE(@insertProcSql, '<Source_View_Name>', @Source_View_Name_bracket);
    SET @insertProcSql = REPLACE(@insertProcSql, '<Source_View_Name_NoBracket>', PARSENAME(@Source_View_Name_bracket,1));
    SET @insertProcSql = REPLACE(@insertProcSql, '<Switch_Schema>', @Switch_Schema);
    SET @insertProcSql = REPLACE(@insertProcSql, '<Switch_Table>', @Switch_Table_Name_bracket);
 
    SET @insertProcSql = REPLACE(@insertProcSql, '<Target_Schema_NoBracket>', PARSENAME(@Target_Schema_bracket,1));
    SET @insertProcSql = REPLACE(@insertProcSql, '<Target_Table_Name_NoBracket>', PARSENAME(@Target_Table_Name,1));
    SET @insertProcSql = REPLACE(@insertProcSql, '<Switch_Schema_NoBracket>', PARSENAME(@Switch_Schema,1));
    SET @insertProcSql = REPLACE(@insertProcSql, '<Switch_Table_NoBracket>', PARSENAME(@Switch_Table_Name_bracket,1));
 

    
    
    SET @insertProcSql = REPLACE(@insertProcSql, '<KeyVault_BKs>', @KeyVault_BK_Cols_With_Brackets);
    SET @insertProcSql = REPLACE(@insertProcSql, '<BK_Cols_WithBrackets>', @BK_Cols_With_Brackets);
    SET @insertProcSql = REPLACE(@insertProcSql, '<KV_BK_Cols_WithBrackets>', 'dd.' + REPLACE(@BK_Cols_With_Brackets,',',',dd.'));
    

    SET @insertProcSql = REPLACE(@insertProcSql, '<Target_Table_Name>', @Target_Table_Name);
    SET @insertProcSql = REPLACE(@insertProcSql, '<KeyVault_Join>',@KeyVault_BK_Join)
    SET @insertProcSql = REPLACE(@insertProcSql, '<Cols_WithBrackets>',@Cols_With_Brackets)
    SET @insertProcSql = REPLACE(@insertProcSql, '<Cols_WithBrackets_Insert>',REPLACE(@Cols_With_Brackets,'dd.',''))
    SET @insertProcSql = REPLACE(@insertProcSql, '<Unkown_Member_Insert>',@Unkown_Member_Insert)


    IF @Include_DW_ValidFrom = 1
    BEGIN
        SET @insertProcSql = REPLACE(@insertProcSql, '<DW_ValidFrom_Insert>','DW_ValidFrom,')
        SET @insertProcSql = REPLACE(@insertProcSql, '<DW_ValidFrom_Select>','dd.DW_ValidFrom,')
        SET @insertProcSql = REPLACE(@insertProcSql,  '<DW_ValidFrom_Join>','AND sk.DW_ValidFrom = dd.DW_ValidFrom')
        SET @insertProcSql = REPLACE(@insertProcSql,  '<Include_DW_ValidFrom>',1)
        
    END
    ELSE
    BEGIN
        SET @insertProcSql = REPLACE(@insertProcSql, '<DW_ValidFrom_Insert>','')
        SET @insertProcSql = REPLACE(@insertProcSql, '<DW_ValidFrom_Select>','')
        SET @insertProcSql = REPLACE(@insertProcSql,  '<DW_ValidFrom_Join>','')
        SET @insertProcSql = REPLACE(@insertProcSql,  '<Include_DW_ValidFrom>',0)

    END

    -- Execute the generated SQL to create the insert procedure
    EXEC utility.[print] @insertProcSql
    EXEC sp_executesql @insertProcSql;



END;


GO
