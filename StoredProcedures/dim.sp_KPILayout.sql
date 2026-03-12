CREATE   PROCEDURE dim.sp_KPILayout
    AS
    BEGIN

        /* Script used to create this

        EXEC utility.sp_create_T1_dimension_view_based_proc
            @Target_Schema = 'dim',
            @Target_Table_Name = 'KPILayout',
            @Source_View_Schema = 'stg',
            @Source_View_Name = 'v_KPIMapping',
            @Switch_Schema = 'switch',
            @BKs = '[Company],[KPI]',
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
                COUNT(0) OVER(PARTITION BY [Company],[KPI]) AS cnt_1
            FROM [stg].[v_KPIMapping]
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

        DROP TABLE IF EXISTS temp.KPILayout;
        SELECT *
        INTO temp.KPILayout
        FROM [stg].[v_KPIMapping];
        


        INSERT INTO KeyVault.SurrogateKeys (
            
            SourceSchema,
            SourceTable,
            [BK_Col1],[BK_Col2]
        )
        SELECT 
            
            'dim',
            'KPILayout',
            dd.[Company],dd.[KPI]
        FROM temp.KPILayout dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'KPILayout'
            AND	sk.[BK_Col1] = CAST(dd.[Company] as nvarchar(255))AND	sk.[BK_Col2] = CAST(dd.[KPI] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NULL;

        DROP TABLE IF EXISTS switch.[KPILayout]

        SELECT 
            sk.Surrogate_key KPILayout_Key
            ,dd.[Company],dd.[KPI],dd.[Sort order]
        into switch.[KPILayout]
        FROM temp.KPILayout dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'KPILayout'
            AND	sk.[BK_Col1] = CAST(dd.[Company] as nvarchar(255))AND	sk.[BK_Col2] = CAST(dd.[KPI] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NOT NULL;


        INSERT INTO switch.[KPILayout] 
        (
            KPILayout_Key
            ,[Company],[KPI],[Sort order]
        )
        SELECT 
            -1
,'UNKNOWN' AS [Company]
,'UNKNOWN' AS [KPI]
,0.0 AS [Sort order]

        DROP TABLE IF EXISTS temp.KPILayout

        EXEC utility.SwitchTableProcedure 
            @Switch_Schema = 'switch'
            ,@switch_table_name='KPILayout'
            ,@Target_Schema='dim'
            ,@Target_Table_Name = 'KPILayout'
            ,@force_switch = 0
            ,@accepted_pct = 95.00


    END
GO
