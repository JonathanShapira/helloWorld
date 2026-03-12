
    CREATE   PROCEDURE dim.sp_Accounts
    AS
    BEGIN

        /* Script used to create this

        EXEC utility.sp_create_T1_dimension_view_based_proc
            @Target_Schema = 'dim',
            @Target_Table_Name = 'Accounts',
            @Source_View_Schema = 'stg',
            @Source_View_Name = 'v_GLAccounts',
            @Switch_Schema = 'switch',
            @BKs = '[Company],[No]',
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
                COUNT(0) OVER(PARTITION BY [Company],[No]) AS cnt_1
            FROM [stg].[v_GLAccounts]
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

        DROP TABLE IF EXISTS temp.Accounts;
        SELECT *
        INTO temp.Accounts
        FROM [stg].[v_GLAccounts];
        


        INSERT INTO KeyVault.SurrogateKeys (
            
            SourceSchema,
            SourceTable,
            [BK_Col1],[BK_Col2]
        )
        SELECT 
            
            'dim',
            'Accounts',
            dd.[Company],dd.[No]
        FROM temp.Accounts dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'Accounts'
            AND	sk.[BK_Col1] = CAST(dd.[Company] as nvarchar(255))AND	sk.[BK_Col2] = CAST(dd.[No] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NULL;

        DROP TABLE IF EXISTS switch.[Accounts]

        SELECT 
            sk.Surrogate_key Accounts_Key
            ,dd.[No],dd.[Name],dd.[Income_Balance],dd.[Account_Category],dd.[Account_Subcategory_Descript],dd.[Account_Type],dd.[Direct_Posting],dd.[Totaling],dd.[Gen_Posting_Type],dd.[Company]
        into switch.[Accounts]
        FROM temp.Accounts dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'Accounts'
            AND	sk.[BK_Col1] = CAST(dd.[Company] as nvarchar(255))AND	sk.[BK_Col2] = CAST(dd.[No] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NOT NULL;


        INSERT INTO switch.[Accounts] 
        (
            Accounts_Key
            ,[No],[Name],[Income_Balance],[Account_Category],[Account_Subcategory_Descript],[Account_Type],[Direct_Posting],[Totaling],[Gen_Posting_Type],[Company]
        )
        SELECT 
            -1
,'UNKNOWN' AS [No]
,'UNKNOWN' AS [Name]
,'UNKNOWN' AS [Income_Balance]
,'UNKNOWN' AS [Account_Category]
,'UNKNOWN' AS [Account_Subcategory_Descript]
,'UNKNOWN' AS [Account_Type]
,0 AS [Direct_Posting]
,'UNKNOWN' AS [Totaling]
,'UNKNOWN' AS [Gen_Posting_Type]
,'UNKNOWN' AS [Company]

        DROP TABLE IF EXISTS temp.Accounts

        EXEC utility.SwitchTableProcedure 
            @Switch_Schema = 'switch'
            ,@switch_table_name='Accounts'
            ,@Target_Schema='dim'
            ,@Target_Table_Name = 'Accounts'
            ,@force_switch = 0
            ,@accepted_pct = 95.00


    END
GO
