CREATE   PROCEDURE dim.sp_CashflowLayout
    AS
    BEGIN

        /* Script used to create this

        EXEC utility.sp_create_T1_dimension_view_based_proc
            @Target_Schema = 'dim',
            @Target_Table_Name = 'CashflowLayout',
            @Source_View_Schema = 'stg',
            @Source_View_Name = 'v_CashflowLayout',
            @Switch_Schema = 'switch',
            @BKs = '[SortOrder]',
            @Include_DW_ValidFrom = 0
        */

        SET NOCOUNT ON;

        DECLARE @sql_chk_dupl NVARCHAR(MAX);
        DECLARE @cnt_dupl INT = 0;
        DECLARE @err_msg NVARCHAR(MAX);
        DECLARE @StartOfUniverse datetime2(7)= '1900-01-01'
        DECLARE @EndOfUniverse datetime2(7) = '9999-12-31 23:59:59.9999999'

        -- Duplicate check based on bk columns
        SET @sql_chk_dupl = '
        ;WITH cte AS (
            SELECT *,
                COUNT(0) OVER(PARTITION BY [SortOrder]) AS cnt_1
            FROM [stg].[v_CashflowLayout]
        )
        SELECT @cnt_dupl_out = COUNT(0)
        FROM cte
        WHERE cnt_1 > 1;';


        -- Execute the dynamic SQL and use @cnt_dupl as an output parameter
        EXEC sp_executesql @sql_chk_dupl, N'@cnt_dupl_out INT OUTPUT', @cnt_dupl_out = @cnt_dupl OUTPUT;

        -- Check for duplicates and raise an error if any are found
        IF @cnt_dupl > 0
        BEGIN
            SET @err_msg = 'Duplicate entry based on BK columns. Please use: ' + @sql_chk_dupl;
            RAISERROR (@err_msg, 16, 1);
            RETURN;
        END

        DROP TABLE IF EXISTS temp.CashflowLayout;
        SELECT *
        INTO temp.CashflowLayout
        FROM [stg].[v_CashflowLayout];
        


        INSERT INTO KeyVault.SurrogateKeys (
            
            SourceSchema,
            SourceTable,
            [BK_Col1]
        )
        SELECT 
            
            'dim',
            'CashflowLayout',
            dd.[SortOrder]
        FROM temp.CashflowLayout dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'CashflowLayout'
            AND	sk.[BK_Col1] = CAST(dd.[SortOrder] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NULL;

        DROP TABLE IF EXISTS switch.[CashflowLayout]

        SELECT 
            sk.Surrogate_key CashflowLayout_Key
            ,dd.[KPIGroup],dd.[KPI],dd.[SortOrder],dd.[GroupSortOrder],dd.[BackgroundColor],dd.[InvertSign],dd.[Type]
        into switch.[CashflowLayout]
        FROM temp.CashflowLayout dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'CashflowLayout'
            AND	sk.[BK_Col1] = CAST(dd.[SortOrder] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NOT NULL;


        INSERT INTO switch.[CashflowLayout] 
        (
            CashflowLayout_Key
            ,[KPIGroup],[KPI],[SortOrder],[GroupSortOrder],[BackgroundColor],[InvertSign],[Type]
        )
        SELECT 
            -1
,'UNKNOWN' AS [KPIGroup]
,'UNKNOWN' AS [KPI]
,'UNKNOWN' AS [SortOrder]
,'UNKNOWN' AS [GroupSortOrder]
,'UNKNOWN' AS [BackgroundColor]
,'UNKNOWN' AS [InvertSign]
,'UNKNOWN' AS [Type]

        DROP TABLE IF EXISTS temp.CashflowLayout

        EXEC utility.SwitchTableProcedure 
            @Switch_Schema = 'switch'
            ,@switch_table_name='CashflowLayout'
            ,@Target_Schema='dim'
            ,@Target_Table_Name = 'CashflowLayout'
            ,@force_switch = 1
            ,@accepted_pct = 0


    END
GO
