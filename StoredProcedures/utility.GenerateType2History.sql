CREATE   proc utility.GenerateType2History 
    @BK_Cols nvarchar(max) = NULL
    ,@Cols nvarchar(max) = NULL
    ,@SourceSchema nvarchar(255) = NULL
    ,@SourceTable nvarchar(255) = NULL
    ,@TargetSchema nvarchar(255) = NULL
    ,@TargetTable nvarchar(255) = NULL
as 
BEGIN

DECLARE @HowTo nvarchar(max) = '
    EXEC utility.GenerateType2History
    @BK_Cols = ''id''
    ,@Cols = ''col1,col2,col3''
    ,@SourceSchema = ''stg''
    ,@SourceTable = ''testtable''
    ,@TargetSchema = ''arc''
    ,@TargetTable = ''testtable''
'

    IF (
        @BK_Cols IS NULL 
        OR @Cols IS NULL
        OR @SourceTable IS NULL
        OR @SourceSchema IS NULL
        )
    BEGIN
            print @HowTo
            return 0
    END
    
DECLARE @Cols_With_Brackets nvarchar(max) = ''
DECLARE @Cols_Without_Brackets nvarchar(max) = ''
DECLARE @Src_Cols_With_Brackets nvarchar(max) = ''
DECLARE @BK_Cols_With_Brackets nvarchar(max) = ''
DECLARE @BK_Cols_Without_Brackets nvarchar(max) = ''
DECLARE @BK_tgt_IsNulls NVARCHAR(max) = ''
DECLARE @BK_Src_IsNulls nvarchar(max) = ''
DECLARE @BK_IsNotNull NVARCHAR(max) = ''
DECLARE @Join_Cols_src_left nvarchar(max) = ''
DECLARE @Join_Cols_tgt_left nvarchar(max) = ''
DECLARE @BK_Src_Cols nvarchar(max) = ''

;with cols as (
    SELECT PARSENAME(c.[value],1) cols
    ,ROW_NUMBER() OVER(order by (select 1)) rwn
    FROM string_split(@Cols,',') c
)
,BK as (

    SELECT PARSENAME(bk.[value],1) bks
    FROM string_split(@BK_Cols,',') bk

)
,colsclean as (
    select c.cols,rwn
    from cols c
    left join BK on c.cols = bk.bks
    where bk.bks is null
)
SELECT 
    @Cols_With_Brackets += QUOTENAME(cols) + ','
    ,@Cols_Without_Brackets += cols + ','
    ,@Src_Cols_With_Brackets += 'src.' + QUOTENAME(cols) + ','
FROM colsclean
order by rwn,cols

SELECT @Cols_With_Brackets = LEFT(@Cols_With_Brackets,LEN(@Cols_With_Brackets)-1)
SELECT @Cols_Without_Brackets = LEFT(@Cols_Without_Brackets,LEN(@Cols_Without_Brackets)-1)
SELECT @Src_Cols_With_Brackets = LEFT(@Src_Cols_With_Brackets,LEN(@Src_Cols_With_Brackets)-1)


    ;WITH BK as (

        SELECT PARSENAME(bk.[value],1) bks
        FROM string_split(@BK_Cols,',') bk

    )
    SELECT 
        @BK_Cols_With_Brackets += QUOTENAME(bks) + ',' 
        ,@BK_Cols_Without_Brackets += bks + ','
        ,@BK_Src_Cols += 'src.' + QUOTENAME(bks) + ','
        ,@Join_Cols_src_left += CHAR(13) + 'AND src.' + QUOTENAME(bks) + ' = tgt.' + QUOTENAME(bks)
        ,@Join_Cols_tgt_left += CHAR(13) + 'AND tgt.' + QUOTENAME(bks) + ' = src.' + QUOTENAME(bks)
        ,@BK_tgt_IsNulls += CHAR(13) + 'AND tgt.' + QUOTENAME(bks) + ' IS NULL'
        ,@BK_src_IsNulls += CHAR(13) + 'AND src.' + QUOTENAME(bks) + ' IS NULL'
        ,@BK_IsNotNull += CHAR(13) + 'AND ' + QUOTENAME(bks) + ' IS NOT NULL'
    from BK
    
    SELECT @BK_Cols_With_Brackets = LEFT(@BK_Cols_With_Brackets,LEN(@BK_Cols_With_Brackets)-1)
    SELECT @BK_Cols_Without_Brackets = LEFT(@BK_Cols_Without_Brackets,LEN(@BK_Cols_Without_Brackets)-1)
    SELECT @BK_Src_Cols = LEFT(@BK_Src_Cols,LEN(@BK_Src_Cols)-1)





    DECLARE @SQL nvarchar(max)
    DECLARE @SQL_chk_stg_table_base nvarchar(max) = '
        
        DECLARE @Cnt int
        SELECT @Cnt = COUNT(0)
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE 1=1
            AND TABLE_SCHEMA = ''<SourceSchema>''
            AND TABLE_NAME = ''<SourceTable>''
            AND COLUMN_NAME = ''DW_CreatedOn''

        IF (@cnt = 0)
        BEGIN
            ALTER TABLE  <SourceSchema>.<SourceTable> ADD DW_CreatedOn DATETIME2(7) DEFAULT GETDATE() NOT NULL
        END
        '
    
    -- SELECT * FROM INFORMATION_SCHEMA.TABLES

    DECLARE @SQL_chk_arc_table_base nvarchar(max) = '

    DECLARE @CntTable int 
    DECLARE @DW_CreatedOn int
    DECLARE @DW_Deleted int
    DECLARE @DW_ValidFrom int
    DECLARE @DW_ValidTo int
    DECLARE @DW_CheckSum int


    SELECT 
        @CntTable = COUNT(0)
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE 1=1
        AND TABLE_SCHEMA = ''<TargetSchema>''
        AND TABLE_NAME = ''<TargetTable>''
        AND TABLE_TYPE = ''BASE TABLE''

    IF (@CntTable = 0)
    BEGIN
        SELECT top 0 <BK_Cols>,<Cols> INTO <TargetSchema>.<TargetTable> FROM <SourceSchema>.<SourceTable>
        
        ALTER TABLE <TargetSchema>.<TargetTable> ADD DW_CreatedOn DATETIME2(7) DEFAULT GETDATE()
        ALTER TABLE <TargetSchema>.<TargetTable> ADD DW_Deleted bit default 0
        ALTER TABLE <TargetSchema>.<TargetTable> ADD DW_ValidFrom DATETIME2(7) NOT NULL
        ALTER TABLE <TargetSchema>.<TargetTable> ADD DW_ValidTo DATETIME2(7)
        ALTER TABLE <TargetSchema>.<TargetTable> ADD DW_CheckSum int

    END
    IF (@CntTable > 0)
    BEGIN
        SELECT 
            @DW_CreatedOn = SUM(CASE WHEN COLUMN_NAME = ''DW_CreatedOn'' THEN 1 ELSE 0 END)
            ,@DW_Deleted = SUM(CASE WHEN COLUMN_NAME = ''DW_Deleted'' THEN 1 ELSE 0 END)
            ,@DW_ValidFrom = SUM(CASE WHEN COLUMN_NAME = ''DW_ValidFrom'' THEN 1 ELSE 0 END)
            ,@DW_ValidTo = SUM(CASE WHEN COLUMN_NAME = ''DW_ValidTo'' THEN 1 ELSE 0 END)
            ,@DW_CheckSum = SUM(CASE WHEN COLUMN_NAME = ''DW_CheckSum'' THEN 1 ELSE 0 END)
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE 1=1
            AND TABLE_SCHEMA = ''<TargetSchema>''
            AND TABLE_NAME = ''<TargetTable>''

            IF @DW_CreatedOn = 0 EXEC  (''ALTER TABLE <TargetSchema>.<TargetTable> ADD DW_CreatedOn DATETIME2(7) DEFAULT GETDATE() NOT NULL'')
            IF @DW_Deleted = 0 EXEC  (''ALTER TABLE <TargetSchema>.<TargetTable> ADD DW_Deleted bit default 0'')
            IF @DW_ValidFrom = 0 EXEC  (''ALTER TABLE <TargetSchema>.<TargetTable> ADD DW_ValidFrom DATETIME2(7) NOT NULL'')
            IF @DW_ValidTo = 0 EXEC  (''ALTER TABLE <TargetSchema>.<TargetTable> ADD DW_ValidTo DATETIME2(7)'')
            IF @DW_CheckSum = 0 EXEC  (''ALTER TABLE <TargetSchema>.<TargetTable> ADD DW_CheckSum int'')

    END
    '

    DECLARE @SQL_Base nvarchar(max) = '
 DECLARE @currentDateTime DATETIME2(7) = GETDATE();

INSERT <TargetSchema>.<TargetTable> (<BK_Cols>,<Cols>,DW_CreatedOn,DW_Deleted, DW_ValidFrom, DW_ValidTo, DW_CheckSum)
SELECT <BK_Cols>,<Cols>, DW_CreatedOn,0,DW_CreatedOn, NULL, CHECKSUM(<Cols>)
FROM (
    MERGE INTO <TargetSchema>.<TargetTable> AS tgt
    USING  <SourceSchema>.<SourceTable> AS src
    ON 1=1<join_Cols_tgt_left>
    AND tgt.DW_ValidTo IS NULL

    WHEN MATCHED AND (
            tgt.DW_CheckSum <> CHECKSUM(<SourceCols>) -- Detect changes
        )
        THEN
            -- Step 1: Close existing record by setting DW_ValidTo
            UPDATE SET DW_ValidTo = @currentDateTime

    WHEN NOT MATCHED BY 
    TARGET THEN
        INSERT (<BK_Cols>,<Cols>,DW_CreatedOn,DW_Deleted, DW_ValidFrom, DW_ValidTo, DW_CheckSum)
        VALUES (<BK_Src_Cols>,<SourceCols>, src.DW_CreatedOn,0,@currentDateTime, NULL, CHECKSUM(<SourceCols>))
    WHEN NOT MATCHED BY SOURCE 
    AND tgt.DW_ValidTo IS NULL
    THEN
        UPDATE SET 
            tgt.DW_ValidTo = @currentDateTime,
            tgt.DW_Deleted = 1
    OUTPUT $action,
            <BK_Src_Cols>,<SourceCols>, @currentDateTime,0,@currentDateTime, NULL, CHECKSUM(<SourceCols>)
) AS [changes] (action, <BK_Cols>,<Cols>,DW_CreatedOn,DW_Deleted, DW_ValidFrom, DW_ValidTo, DW_CheckSum)
WHERE action = ''UPDATE'' <BK_IsNotNull>;

'

SELECT @sql = @SQL_chk_stg_table_base
SELECT @sql = REPLACE(@SQL,'<SourceSchema>',@SourceSchema)
SELECT @sql = REPLACE(@SQL,'<SourceTable>',@SourceTable)

--PRINT @sql
EXEC sp_executesql @sql


SELECT @sql = @SQL_chk_arc_table_base
SELECT @sql = REPLACE(@SQL,'<SourceSchema>',@SourceSchema)
SELECT @sql = REPLACE(@SQL,'<SourceTable>',@SourceTable)
SELECT @sql = REPLACE(@SQL,'<TargetSchema>',@TargetSchema)
SELECT @sql = REPLACE(@SQL,'<TargetTable>',@TargetTable)
SELECT @sql = REPLACE(@SQL,'<Cols>',@Cols_With_Brackets)
SELECT @sql = REPLACE(@SQL,'<BK_Cols>',@BK_Cols)


-- PRINT @sql
EXEC sp_executesql @sql


SELECT @sql = @SQL_Base
SELECT @sql = REPLACE(@SQL,'<SourceSchema>',@SourceSchema)
SELECT @sql = REPLACE(@SQL,'<SourceTable>',@SourceTable)
SELECT @sql = REPLACE(@SQL,'<TargetSchema>',@TargetSchema)
SELECT @sql = REPLACE(@SQL,'<TargetTable>',@TargetTable)
SELECT @sql = REPLACE(@SQL,'<BK_Cols>',@BK_Cols)
SELECT @sql = REPLACE(@SQL,'<BK_Src_Cols>',@BK_Src_Cols)
SELECT @sql = REPLACE(@SQL,'<Cols>',@Cols_With_Brackets)
SELECT @sql = REPLACE(@SQL,'<SourceCols>',@Src_Cols_With_Brackets)
SELECT @sql = REPLACE(@SQL,'<join_Cols_src_left>',@Join_Cols_src_left)
SELECT @sql = REPLACE(@SQL,'<BK_tgt_IsNulls>',@BK_tgt_IsNulls)
SELECT @sql = REPLACE(@SQL,'<BK_src_IsNulls>',@BK_src_IsNulls)
SELECT @sql = REPLACE(@SQL,'<Join_Cols_src_left>',@Join_Cols_src_left)
SELECT @sql = REPLACE(@SQL,'<join_Cols_tgt_left>',@Join_Cols_tgt_left)
SELECT @sql = REPLACE(@SQL,'<BK_IsNotNull>',@BK_IsNotNull)

/*
DECLARE @Cols_With_Brackets nvarchar(max) = ''
DECLARE @Cols_Without_Brackets nvarchar(max) = ''
DECLARE @BK_Cols_With_Brackets nvarchar(max) = ''
DECLARE @BK_Cols_Without_Brackets nvarchar(max) = ''
DECLARE @Join_Cols_src_left nvarchar(max) = ''
DECLARE @Join_Cols_tgt_left nvarchar(max) = ''

*/
 print @sql
 EXEC sp_executesql @sql

END
GO
