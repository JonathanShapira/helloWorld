CREATE   PROCEDURE dim.sp_Sager
    AS
    BEGIN

        /* Script used to create this

        EXEC utility.sp_create_T1_dimension_view_based_proc
            @Target_Schema = 'dim',
            @Target_Table_Name = 'Sager',
            @Source_View_Schema = 'stg',
            @Source_View_Name = 'v_Sager',
            @Switch_Schema = 'switch',
            @BKs = '[NO],[Company]',
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
                COUNT(0) OVER(PARTITION BY [NO],[Company]) AS cnt_1
            FROM [stg].[v_Sager]
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

        DROP TABLE IF EXISTS temp.Sager;
        SELECT *
        INTO temp.Sager
        FROM [stg].[v_Sager];
        


        INSERT INTO KeyVault.SurrogateKeys (
            
            SourceSchema,
            SourceTable,
            [BK_Col1],[BK_Col2]
        )
        SELECT 
            
            'dim',
            'Sager',
            dd.[NO],dd.[Company]
        FROM temp.Sager dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'Sager'
            AND	sk.[BK_Col1] = CAST(dd.[NO] as nvarchar(255))AND	sk.[BK_Col2] = CAST(dd.[Company] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NULL;

        DROP TABLE IF EXISTS switch.[Sager]

        SELECT 
            sk.Surrogate_key Sager_Key
            ,dd.[No],dd.[Description],dd.[Bill_to_Customer_No],dd.[Status],dd.[Person_Responsible],dd.[Next_Invoice_Date],dd.[Job_Posting_Group],dd.[Search_Description],dd.[Percent_of_Overdue_Planning_Lines],dd.[Percent_Completed],dd.[Percent_Invoiced],dd.[Project_Manager],dd.[External_Document_No],dd.[Your_Reference],dd.[Company]
        into switch.[Sager]
        FROM temp.Sager dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'Sager'
            AND	sk.[BK_Col1] = CAST(dd.[NO] as nvarchar(255))AND	sk.[BK_Col2] = CAST(dd.[Company] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NOT NULL;


        INSERT INTO switch.[Sager] 
        (
            Sager_Key
            ,[No],[Description],[Bill_to_Customer_No],[Status],[Person_Responsible],[Next_Invoice_Date],[Job_Posting_Group],[Search_Description],[Percent_of_Overdue_Planning_Lines],[Percent_Completed],[Percent_Invoiced],[Project_Manager],[External_Document_No],[Your_Reference],[Company]
        )
        SELECT 
            -1
,'UNKNOWN' AS [No]
,'UNKNOWN' AS [Description]
,'UNKNOWN' AS [Bill_to_Customer_No]
,'UNKNOWN' AS [Status]
,'UNKNOWN' AS [Person_Responsible]
,'UNKNOWN' AS [Next_Invoice_Date]
,'UNKNOWN' AS [Job_Posting_Group]
,'UNKNOWN' AS [Search_Description]
,0.0 AS [Percent_of_Overdue_Planning_Lines]
,0.0 AS [Percent_Completed]
,0.0 AS [Percent_Invoiced]
,'UNKNOWN' AS [Project_Manager]
,'UNKNOWN' AS [External_Document_No]
,'UNKNOWN' AS [Your_Reference]
,'UNKNOWN' AS [Company]

        DROP TABLE IF EXISTS temp.Sager

        EXEC utility.SwitchTableProcedure 
            @Switch_Schema = 'switch'
            ,@switch_table_name='Sager'
            ,@Target_Schema='dim'
            ,@Target_Table_Name = 'Sager'
            ,@force_switch = 0
            ,@accepted_pct = 95.00


    END
GO
