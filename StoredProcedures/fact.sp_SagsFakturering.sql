CREATE   PROC [fact].[sp_SagsFakturering] AS
BEGIN
    DROP TABLE IF EXISTS switch.fact_SagsFakturering
    SELECT 
         Entry_No
         ,coalesce(c.Calendar_Key,-1) Calendar_Key
         ,Posting_Date
         ,coalesce(sol.Sagsopgavelinjer_key,-1) Sagsopgavelinjer_key
         ,coalesce(s.Sager_key,-1) Sager_key
         ,coalesce(d.Debitorer_key,-1) Debitorer_key
         ,coalesce(r.Ressourcer_Key,-1) Ressourcer_Key
         ,coalesce(co.Company_key,-1) Company_key
         ,Line_Amount_LCY
         ,Total_Cost_LCY
         ,Quantity
    into switch.fact_SagsFakturering
    FROM stg.Sagsposter sp
    left join dim.calendar c
        on sp.Posting_Date = c.[Date]
    left join dim.Sagsopgavelinjer sol
        on sp.Job_Task_No = sol.Job_Task_No
            and sp.Job_No = SOL.Job_No
            and SP.Company = SOL.Company
    left join dim.Sager s
        on s.[NO] = sp.Job_No
            and s.Company = sp.Company
    left join dim.Debitorer d
        on s.Bill_to_Customer_No = d.[NO]
            and s.Company = d.Company
    left join dim.ressourcer r
        on sp.[No] = r.NO
            and sp.Company = r.Company
    left join dim.company co
        on sp.Company = co.[Company]
    where sp.Entry_Type = 'Sale'


/*
DROP TABLE IF EXISTS fact.SagsFakturering
SELECT * into fact.SagsFakturering FROM switch.fact_SagsFakturering 
*/

    EXEC utility.SwitchTableProcedure 
    @Switch_Schema = 'switch'
    ,@switch_table_name='fact_SagsFakturering'
    ,@Target_Schema='fact'
    ,@Target_Table_Name = 'SagsFakturering'
    ,@force_switch = 1
    ,@accepted_pct = 0


END
GO
