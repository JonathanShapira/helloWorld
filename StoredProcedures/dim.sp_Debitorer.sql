CREATE   PROCEDURE dim.sp_Debitorer
    AS
    BEGIN

        /* Script used to create this

        EXEC utility.sp_create_T1_dimension_view_based_proc
            @Target_Schema = 'dim',
            @Target_Table_Name = 'Debitorer',
            @Source_View_Schema = 'stg',
            @Source_View_Name = 'v_Debitorer',
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
            FROM [stg].[v_Debitorer]
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

        DROP TABLE IF EXISTS temp.Debitorer;
        SELECT *
        INTO temp.Debitorer
        FROM [stg].[v_Debitorer];
        


        INSERT INTO KeyVault.SurrogateKeys (
            
            SourceSchema,
            SourceTable,
            [BK_Col1],[BK_Col2]
        )
        SELECT 
            
            'dim',
            'Debitorer',
            dd.[NO],dd.[Company]
        FROM temp.Debitorer dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'Debitorer'
            AND	sk.[BK_Col1] = CAST(dd.[NO] as nvarchar(255))AND	sk.[BK_Col2] = CAST(dd.[Company] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NULL;

        DROP TABLE IF EXISTS switch.[Debitorer]

        SELECT 
            sk.Surrogate_key Debitorer_Key
            ,dd.[No],dd.[Name],dd.[Name_2],dd.[Responsibility_Center],dd.[Location_Code],dd.[Post_Code],dd.[Country_Region_Code],dd.[Phone_No],dd.[IC_Partner_Code],dd.[Contact],dd.[Salesperson_Code],dd.[Customer_Posting_Group],dd.[Allow_Multiple_Posting_Groups],dd.[Gen_Bus_Posting_Group],dd.[VAT_Bus_Posting_Group],dd.[Customer_Price_Group],dd.[Customer_Disc_Group],dd.[Payment_Terms_Code],dd.[Reminder_Terms_Code],dd.[Fin_Charge_Terms_Code],dd.[Currency_Code],dd.[Language_Code],dd.[Search_Name],dd.[Credit_Limit_LCY],dd.[Blocked],dd.[Privacy_Blocked],dd.[Application_Method],dd.[Combine_Shipments],dd.[Reserve],dd.[Ship_to_Code],dd.[Shipping_Advice],dd.[Shipping_Agent_Code],dd.[Base_Calendar_Code],dd.[Balance_LCY],dd.[Balance_Due_LCY],dd.[Sales_LCY],dd.[Payments_LCY],dd.[Coupled_to_CRM],dd.[Coupled_to_Dataverse],dd.[Global_Dimension_1_Filter],dd.[Global_Dimension_2_Filter],dd.[Currency_Filter],dd.[Date_Filter],dd.[Company],dd.[Last_Date_Modified],dd.[FirstPurchaseDate]
        into switch.[Debitorer]
        FROM temp.Debitorer dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'Debitorer'
            AND	sk.[BK_Col1] = CAST(dd.[NO] as nvarchar(255))AND	sk.[BK_Col2] = CAST(dd.[Company] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NOT NULL;


        INSERT INTO switch.[Debitorer] 
        (
            Debitorer_Key
            ,[No],[Name],[Name_2],[Responsibility_Center],[Location_Code],[Post_Code],[Country_Region_Code],[Phone_No],[IC_Partner_Code],[Contact],[Salesperson_Code],[Customer_Posting_Group],[Allow_Multiple_Posting_Groups],[Gen_Bus_Posting_Group],[VAT_Bus_Posting_Group],[Customer_Price_Group],[Customer_Disc_Group],[Payment_Terms_Code],[Reminder_Terms_Code],[Fin_Charge_Terms_Code],[Currency_Code],[Language_Code],[Search_Name],[Credit_Limit_LCY],[Blocked],[Privacy_Blocked],[Application_Method],[Combine_Shipments],[Reserve],[Ship_to_Code],[Shipping_Advice],[Shipping_Agent_Code],[Base_Calendar_Code],[Balance_LCY],[Balance_Due_LCY],[Sales_LCY],[Payments_LCY],[Coupled_to_CRM],[Coupled_to_Dataverse],[Global_Dimension_1_Filter],[Global_Dimension_2_Filter],[Currency_Filter],[Date_Filter],[Company],[Last_Date_Modified],[FirstPurchaseDate]
        )
        SELECT 
            -1
,'UNKNOWN' AS [No]
,'UNKNOWN' AS [Name]
,'UNKNOWN' AS [Name_2]
,'UNKNOWN' AS [Responsibility_Center]
,'UNKNOWN' AS [Location_Code]
,'UNKNOWN' AS [Post_Code]
,'UNKNOWN' AS [Country_Region_Code]
,'UNKNOWN' AS [Phone_No]
,'UNKNOWN' AS [IC_Partner_Code]
,'UNKNOWN' AS [Contact]
,'UNKNOWN' AS [Salesperson_Code]
,'UNKNOWN' AS [Customer_Posting_Group]
,0 AS [Allow_Multiple_Posting_Groups]
,'UNKNOWN' AS [Gen_Bus_Posting_Group]
,'UNKNOWN' AS [VAT_Bus_Posting_Group]
,'UNKNOWN' AS [Customer_Price_Group]
,'UNKNOWN' AS [Customer_Disc_Group]
,'UNKNOWN' AS [Payment_Terms_Code]
,'UNKNOWN' AS [Reminder_Terms_Code]
,'UNKNOWN' AS [Fin_Charge_Terms_Code]
,'UNKNOWN' AS [Currency_Code]
,'UNKNOWN' AS [Language_Code]
,'UNKNOWN' AS [Search_Name]
,0.0 AS [Credit_Limit_LCY]
,'UNKNOWN' AS [Blocked]
,0 AS [Privacy_Blocked]
,'UNKNOWN' AS [Application_Method]
,0 AS [Combine_Shipments]
,'UNKNOWN' AS [Reserve]
,'UNKNOWN' AS [Ship_to_Code]
,'UNKNOWN' AS [Shipping_Advice]
,'UNKNOWN' AS [Shipping_Agent_Code]
,'UNKNOWN' AS [Base_Calendar_Code]
,0.0 AS [Balance_LCY]
,0.0 AS [Balance_Due_LCY]
,0.0 AS [Sales_LCY]
,0.0 AS [Payments_LCY]
,0 AS [Coupled_to_CRM]
,0 AS [Coupled_to_Dataverse]
,'UNKNOWN' AS [Global_Dimension_1_Filter]
,'UNKNOWN' AS [Global_Dimension_2_Filter]
,'UNKNOWN' AS [Currency_Filter]
,'UNKNOWN' AS [Date_Filter]
,'UNKNOWN' AS [Company]
,'1900-01-01 00:00:00.0000000' AS [Last_Date_Modified]
,'1900-01-01 00:00:00.0000000' AS [FirstPurchaseDate]

        DROP TABLE IF EXISTS temp.Debitorer

        EXEC utility.SwitchTableProcedure 
            @Switch_Schema = 'switch'
            ,@switch_table_name='Debitorer'
            ,@Target_Schema='dim'
            ,@Target_Table_Name = 'Debitorer'
            ,@force_switch = 0
            ,@accepted_pct = 95.00


    END
GO
