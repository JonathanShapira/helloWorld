CREATE   PROCEDURE dim.sp_DimensionGroupKeys
    AS
    BEGIN

        /* Script used to create this

        EXEC utility.sp_create_T1_dimension_view_based_proc
            @Target_Schema = 'dim',
            @Target_Table_Name = 'DimensionGroupKeys',
            @Source_View_Schema = 'stg',
            @Source_View_Name = 'v_DimensionGroups',
            @Switch_Schema = 'switch',
            @BKs = '[Dimension_Set_ID],[Company]',
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
                COUNT(0) OVER(PARTITION BY [Dimension_Set_ID],[Company]) AS cnt_1
            FROM [stg].[v_DimensionGroups]
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

        DROP TABLE IF EXISTS temp.DimensionGroupKeys;
        SELECT *
        INTO temp.DimensionGroupKeys
        FROM [stg].[v_DimensionGroups];
        


        INSERT INTO KeyVault.SurrogateKeys (
            
            SourceSchema,
            SourceTable,
            [BK_Col1],[BK_Col2]
        )
        SELECT 
            
            'dim',
            'DimensionGroupKeys',
            dd.[Dimension_Set_ID],dd.[Company]
        FROM temp.DimensionGroupKeys dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'DimensionGroupKeys'
            AND	sk.[BK_Col1] = CAST(dd.[Dimension_Set_ID] as nvarchar(255))AND	sk.[BK_Col2] = CAST(dd.[Company] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NULL;

        DROP TABLE IF EXISTS switch.[DimensionGroupKeys]

        SELECT 
            sk.Surrogate_key DimensionGroupKeys_Key
            ,dd.[Dimension_Set_ID],dd.[Company]
        into switch.[DimensionGroupKeys]
        FROM temp.DimensionGroupKeys dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'DimensionGroupKeys'
            AND	sk.[BK_Col1] = CAST(dd.[Dimension_Set_ID] as nvarchar(255))AND	sk.[BK_Col2] = CAST(dd.[Company] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NOT NULL;


        INSERT INTO switch.[DimensionGroupKeys] 
        (
            DimensionGroupKeys_Key
            ,[Dimension_Set_ID],[Company]
        )
        SELECT 
            -1
,0.0 AS [Dimension_Set_ID]
,'UNKNOWN' AS [Company]

        DROP TABLE IF EXISTS temp.DimensionGroupKeys

        EXEC utility.SwitchTableProcedure 
            @Switch_Schema = 'switch'
            ,@switch_table_name='DimensionGroupKeys'
            ,@Target_Schema='dim'
            ,@Target_Table_Name = 'DimensionGroupKeys'
            ,@force_switch = 0
            ,@accepted_pct = 95.00


    END
GO
