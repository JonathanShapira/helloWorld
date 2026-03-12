CREATE   PROCEDURE dim.sp_Sagsopgavelinjer
    AS
    BEGIN

        /* Script used to create this

        EXEC utility.sp_create_T1_dimension_view_based_proc
            @Target_Schema = 'dim',
            @Target_Table_Name = 'Sagsopgavelinjer',
            @Source_View_Schema = 'stg',
            @Source_View_Name = 'v_Sagsopgavelinjer',
            @Switch_Schema = 'switch',
            @BKs = '[Job_No],[Job_Task_No],[Company]',
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
                COUNT(0) OVER(PARTITION BY [Job_No],[Job_Task_No],[Company]) AS cnt_1
            FROM [stg].[v_Sagsopgavelinjer]
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

        DROP TABLE IF EXISTS temp.Sagsopgavelinjer;
        SELECT *
        INTO temp.Sagsopgavelinjer
        FROM [stg].[v_Sagsopgavelinjer];
        


        INSERT INTO KeyVault.SurrogateKeys (
            
            SourceSchema,
            SourceTable,
            [BK_Col1],[BK_Col2],[BK_Col3]
        )
        SELECT 
            
            'dim',
            'Sagsopgavelinjer',
            dd.[Job_No],dd.[Job_Task_No],dd.[Company]
        FROM temp.Sagsopgavelinjer dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'Sagsopgavelinjer'
            AND	sk.[BK_Col1] = CAST(dd.[Job_No] as nvarchar(255))AND	sk.[BK_Col2] = CAST(dd.[Job_Task_No] as nvarchar(255))AND	sk.[BK_Col3] = CAST(dd.[Company] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NULL;

        DROP TABLE IF EXISTS switch.[Sagsopgavelinjer]

        SELECT 
            sk.Surrogate_key Sagsopgavelinjer_Key
            ,dd.[Job_No],dd.[Job_Task_No],dd.[Description],dd.[Job_Task_Type],dd.[Totaling],dd.[Job_Posting_Group],dd.[Location_Code],dd.[Bin_Code],dd.[WIP_Total],dd.[WIP_Method],dd.[Schedule_Total_Cost],dd.[Schedule_Total_Price],dd.[Usage_Total_Cost],dd.[Usage_Total_Price],dd.[Contract_Total_Cost],dd.[Contract_Total_Price],dd.[Contract_Invoiced_Cost],dd.[Contract_Invoiced_Price],dd.[Remaining_Total_Cost],dd.[Remaining_Total_Price],dd.[EAC_Total_Cost],dd.[EAC_Total_Price],dd.[Global_Dimension_1_Code],dd.[Global_Dimension_2_Code],dd.[Outstanding_Orders],dd.[Amt_Rcd_Not_Invoiced],dd.[Coupled_to_Dataverse],dd.[Planning_Date_Filter],dd.[Posting_Date_Filter],dd.[Company],dd.[Start_Date],dd.[End_Date]
        into switch.[Sagsopgavelinjer]
        FROM temp.Sagsopgavelinjer dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'Sagsopgavelinjer'
            AND	sk.[BK_Col1] = CAST(dd.[Job_No] as nvarchar(255))AND	sk.[BK_Col2] = CAST(dd.[Job_Task_No] as nvarchar(255))AND	sk.[BK_Col3] = CAST(dd.[Company] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NOT NULL;


        INSERT INTO switch.[Sagsopgavelinjer] 
        (
            Sagsopgavelinjer_Key
            ,[Job_No],[Job_Task_No],[Description],[Job_Task_Type],[Totaling],[Job_Posting_Group],[Location_Code],[Bin_Code],[WIP_Total],[WIP_Method],[Schedule_Total_Cost],[Schedule_Total_Price],[Usage_Total_Cost],[Usage_Total_Price],[Contract_Total_Cost],[Contract_Total_Price],[Contract_Invoiced_Cost],[Contract_Invoiced_Price],[Remaining_Total_Cost],[Remaining_Total_Price],[EAC_Total_Cost],[EAC_Total_Price],[Global_Dimension_1_Code],[Global_Dimension_2_Code],[Outstanding_Orders],[Amt_Rcd_Not_Invoiced],[Coupled_to_Dataverse],[Planning_Date_Filter],[Posting_Date_Filter],[Company],[Start_Date],[End_Date]
        )
        SELECT 
            -1
,'UNKNOWN' AS [Job_No]
,'UNKNOWN' AS [Job_Task_No]
,'UNKNOWN' AS [Description]
,'UNKNOWN' AS [Job_Task_Type]
,'UNKNOWN' AS [Totaling]
,'UNKNOWN' AS [Job_Posting_Group]
,'UNKNOWN' AS [Location_Code]
,'UNKNOWN' AS [Bin_Code]
,'UNKNOWN' AS [WIP_Total]
,'UNKNOWN' AS [WIP_Method]
,0.0 AS [Schedule_Total_Cost]
,0.0 AS [Schedule_Total_Price]
,0.0 AS [Usage_Total_Cost]
,0.0 AS [Usage_Total_Price]
,0.0 AS [Contract_Total_Cost]
,0.0 AS [Contract_Total_Price]
,0.0 AS [Contract_Invoiced_Cost]
,0.0 AS [Contract_Invoiced_Price]
,0.0 AS [Remaining_Total_Cost]
,0.0 AS [Remaining_Total_Price]
,0.0 AS [EAC_Total_Cost]
,0.0 AS [EAC_Total_Price]
,'UNKNOWN' AS [Global_Dimension_1_Code]
,'UNKNOWN' AS [Global_Dimension_2_Code]
,0.0 AS [Outstanding_Orders]
,0.0 AS [Amt_Rcd_Not_Invoiced]
,0 AS [Coupled_to_Dataverse]
,'UNKNOWN' AS [Planning_Date_Filter]
,'UNKNOWN' AS [Posting_Date_Filter]
,'UNKNOWN' AS [Company]
,'1900-01-01 00:00:00.0000000' AS [Start_Date]
,'1900-01-01 00:00:00.0000000' AS [End_Date]

        DROP TABLE IF EXISTS temp.Sagsopgavelinjer

        EXEC utility.SwitchTableProcedure 
            @Switch_Schema = 'switch'
            ,@switch_table_name='Sagsopgavelinjer'
            ,@Target_Schema='dim'
            ,@Target_Table_Name = 'Sagsopgavelinjer'
            ,@force_switch = 0
            ,@accepted_pct = 95.00


    END
GO
