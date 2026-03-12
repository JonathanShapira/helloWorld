CREATE PROCEDURE [fact].[sp_GLEntries] AS
BEGIN

    -- Drop temp table if it exists
    DROP TABLE IF EXISTS switch.fact_GLEntries;

    -- Select and insert into the switch schema
    SELECT 
        GLE.Amount,
        COALESCE(Acc.Accounts_key, -1) AS Accounts_key,
        COALESCE(d.Debitorer_key, -1) AS Debitorer_key,
        COALESCE(c.Calendar_key, -1) AS Calendar_key,
        COALESCE(s.Sager_key, -1) AS Sager_key,
        COALESCE(dgk.DimensionGroupKeys_key, -1) AS DimensionGroupKeys_key,
        coalesce(co.Company_Key, -1) AS CompanyKey
    INTO switch.fact_GLEntries
    FROM [stg].[GLEntries] GLE
    LEFT JOIN dim.Accounts Acc 
        ON Acc.Company = GLE.Company 
        AND Acc.No = GLE.G_L_Account_No
    LEFT JOIN dim.calendar c 
        ON c.Date = GLE.Posting_Date
    LEFT JOIN dim.Debitorer d 
        ON d.Company = GLE.Company 
        AND d.No = GLE.Source_No 
        AND GLE.Source_Type = 'Customer'
    LEFT JOIN dim.Sager s 
        ON s.Company = GLE.Company 
        AND GLE.Job_No = s.No
    left join dim.DimensionGroupKeys dgk
        on dgk.Dimension_Set_ID = GLE.Dimension_Set_ID
        and dgk.Company = GLE.Company
    left join dim.company CO
        on CO.Company = GLE.Company

    /*
    DROP TABLE IF EXISTS fact.GLEntries
    SELECT * INTO fact.GLEntries FROM switch.fact_GLEntries
    */

    -- Switch the table to the fact schema
    EXEC utility.SwitchTableProcedure 
        @Switch_Schema = 'switch'
        ,@switch_table_name = 'fact_GLEntries'
        ,@Target_Schema = 'fact'
        ,@Target_Table_Name = 'GLEntries'
        ,@force_switch = 1
        ,@accepted_pct = 0

END
GO
