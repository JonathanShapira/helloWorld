
    CREATE   PROCEDURE dim.sp_BalanceLayout
    AS
    BEGIN

        /* Script used to create this

        EXEC utility.sp_create_T1_dimension_view_based_proc
            @Target_Schema = 'dim',
            @Target_Table_Name = 'BalanceLayout',
            @Source_View_Schema = 'stg',
            @Source_View_Name = 'v_BalanceLayout',
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
            FROM [stg].[v_BalanceLayout]
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

        DROP TABLE IF EXISTS temp.BalanceLayout;
        SELECT *
        INTO temp.BalanceLayout
        FROM [stg].[v_BalanceLayout];
        


        INSERT INTO KeyVault.SurrogateKeys (
            
            SourceSchema,
            SourceTable,
            [BK_Col1]
        )
        SELECT 
            
            'dim',
            'BalanceLayout',
            dd.[SortOrder]
        FROM temp.BalanceLayout dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'BalanceLayout'
            AND	sk.[BK_Col1] = CAST(dd.[SortOrder] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NULL;

        DROP TABLE IF EXISTS switch.[BalanceLayout]

        SELECT 
            sk.Surrogate_key BalanceLayout_Key
            ,dd.[KPIGroup],dd.[KPI],dd.[SortOrder],dd.[GroupSortOrder],dd.[BackgroundColor],dd.[InvertSign],dd.[Type]
        into switch.[BalanceLayout]
        FROM temp.BalanceLayout dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'BalanceLayout'
            AND	sk.[BK_Col1] = CAST(dd.[SortOrder] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NOT NULL;


        INSERT INTO switch.[BalanceLayout] 
        (
            BalanceLayout_Key
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

        DROP TABLE IF EXISTS temp.BalanceLayout

        EXEC utility.SwitchTableProcedure 
            @Switch_Schema = 'switch'
            ,@switch_table_name='BalanceLayout'
            ,@Target_Schema='dim'
            ,@Target_Table_Name = 'BalanceLayout'
            ,@force_switch = 1
            ,@accepted_pct = 0


    END
GO
