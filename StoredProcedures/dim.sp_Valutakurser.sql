
    CREATE   PROCEDURE dim.sp_Valutakurser
    AS
    BEGIN

        /* Script used to create this

        EXEC utility.sp_create_T1_dimension_view_based_proc
            @Target_Schema = 'dim',
            @Target_Table_Name = 'Valutakurser',
            @Source_View_Schema = 'stg',
            @Source_View_Name = 'v_ValutaKurser',
            @Switch_Schema = 'switch',
            @BKs = '[Currency_Code],[DW_ValidFrom],[Company]',
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
                COUNT(0) OVER(PARTITION BY [Currency_Code],[DW_ValidFrom],[Company]) AS cnt_1
            FROM [stg].[v_ValutaKurser]
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

        DROP TABLE IF EXISTS temp.Valutakurser;
        SELECT *
        INTO temp.Valutakurser
        FROM [stg].[v_ValutaKurser];
        


        INSERT INTO KeyVault.SurrogateKeys (
            
            SourceSchema,
            SourceTable,
            [BK_Col1],[BK_Col2],[BK_Col3]
        )
        SELECT 
            
            'dim',
            'Valutakurser',
            dd.[Currency_Code],dd.[DW_ValidFrom],dd.[Company]
        FROM temp.Valutakurser dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'Valutakurser'
            AND	sk.[BK_Col1] = CAST(dd.[Currency_Code] as nvarchar(255))AND	sk.[BK_Col2] = CAST(dd.[DW_ValidFrom] as nvarchar(255))AND	sk.[BK_Col3] = CAST(dd.[Company] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NULL;

        DROP TABLE IF EXISTS switch.[Valutakurser]

        SELECT 
            sk.Surrogate_key Valutakurser_Key
            ,dd.[Currency_Code],dd.[Exchange_Rate_Amount],dd.[Relational_Exch_Rate_Amount],dd.[DW_ValidFrom],dd.[DW_ValidTo],dd.[Company]
        into switch.[Valutakurser]
        FROM temp.Valutakurser dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'Valutakurser'
            AND	sk.[BK_Col1] = CAST(dd.[Currency_Code] as nvarchar(255))AND	sk.[BK_Col2] = CAST(dd.[DW_ValidFrom] as nvarchar(255))AND	sk.[BK_Col3] = CAST(dd.[Company] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NOT NULL;


        INSERT INTO switch.[Valutakurser] 
        (
            Valutakurser_Key
            ,[Currency_Code],[Exchange_Rate_Amount],[Relational_Exch_Rate_Amount],[DW_ValidFrom],[DW_ValidTo],[Company]
        )
        SELECT 
            -1
,'UNKNOWN' AS [Currency_Code]
,0.0 AS [Exchange_Rate_Amount]
,0.0 AS [Relational_Exch_Rate_Amount]
,'UNKNOWN' AS [DW_ValidFrom]
,'UNKNOWN' AS [DW_ValidTo]
,'UNKNOWN' AS [Company]

        DROP TABLE IF EXISTS temp.Valutakurser

        EXEC utility.SwitchTableProcedure 
            @Switch_Schema = 'switch'
            ,@switch_table_name='Valutakurser'
            ,@Target_Schema='dim'
            ,@Target_Table_Name = 'Valutakurser'
            ,@force_switch = 0
            ,@accepted_pct = 95.00


    END
GO
