CREATE   PROC [fact].[sp_VaerdiPoster]
AS
BEGIN
    

    DROP TABLE IF EXISTS switch.fact_VaerdiPoster
    SELECT 
        COALESCE(c.Calendar_Key,-1) Calendar_Key
        ,COALESCE(v.Varer_key,-1) Varer_key
        ,COALESCE(l.lokationer_key,-1) lokationer_key
        ,COALESCE(d.Debitorer_key,-1) Debitorer_key
        ,COALESCE(co.Company_key,-1) Company_key
        --,Job_No
        --,jobtask
        ,Document_Type
        ,Sales_Amount_Actual
        ,Cost_Amount_Actual
        ,Source_Type
        ,Dimension_Set_ID
        ,Invoiced_Quantity
        ,DATEDIFF(dd,FirstPurchaseDate,Posting_Date) DaysSinceFirstPurchase
    into switch.fact_VaerdiPoster
    FROM stg.værdiposter vp
    LEFT join dim.Varer v
        on vp.Item_No = v.[No]
        and vp.Company = v.Company
    LEFT JOIN dim.calendar c
        on vp.Posting_Date = c.[Date]
    LEFT JOIN dim.Lokationer l
        on vp.Location_Code = l.Code
        and vp.Company = l.Company
    LEFT JOIN dim.Debitorer d
        on vp.Source_No = d.[No]
        and vp.Company = d.Company
    left join dim.company co
        on vp.Company = co.[Company]

/*
DROP TABLE IF EXISTS fact.VaerdiPoster
SELECT * into fact.VaerdiPoster FROM switch.fact_VaerdiPoster 
*/

    EXEC utility.SwitchTableProcedure 
    @Switch_Schema = 'switch'
    ,@switch_table_name='fact_VaerdiPoster'
    ,@Target_Schema='fact'
    ,@Target_Table_Name = 'VaerdiPoster'
    ,@force_switch = 1
    ,@accepted_pct = 0





END

GO
