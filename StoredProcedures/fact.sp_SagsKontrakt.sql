CREATE  PROC [fact].[sp_SagsKontrakt] AS
BEGIN
    DROP TABLE IF EXISTS switch.fact_SagsKontrakt

    SELECT
         coalesce(c.Calendar_Key,-1) Calendar_Key
         ,coalesce(sol.Sagsopgavelinjer_key,-1) Sagsopgavelinjer_key
         ,coalesce(s.Sager_key,-1) Sager_key
         ,coalesce(d.Debitorer_key,-1) Debitorer_key
         ,coalesce(r.ressourcer_key,-1) Ressourcer_key
         ,coalesce(co.Company_key,-1) Company_key
         ,Line_Amount_LCY
         ,Total_Cost_LCY
         ,Quantity
    into switch.fact_SagsKontrakt
    FROM stg.Sagsplanlægningslinjer sp
    left join dim.calendar c
        on sp.Planning_Date = c.[Date]
    left join dim.Sagsopgavelinjer sol
        on sp.Job_Task_No = sol.Job_Task_No
            and sp.Job_No = SOL.Job_No
            and sp.Company = SOL.Company
    left join dim.Sager s
        on s.[NO] = sp.Job_No
        AND s.Company = sp.Company
    left join dim.Debitorer d
        on s.Bill_to_Customer_No = d.[NO]
        and s.Company = d.Company
    left join dim.ressourcer r
        on sp.[No] = r.NO
        and sp.Company = r.Company
    left join dim.company co
        on sp.Company = co.[Company]
    where Line_Type in ('Billable','Both Budget and Billable')

/*
DROP TABLE IF EXISTS fact.SagsKontrakt
SELECT * into fact.SagsKontrakt FROM switch.fact_SagsKontrakt
*/

    EXEC utility.SwitchTableProcedure 
    @Switch_Schema = 'switch'
    ,@switch_table_name='fact_SagsKontrakt'
    ,@Target_Schema='fact'
    ,@Target_Table_Name = 'SagsKontrakt'
    ,@force_switch = 1
    ,@accepted_pct = 0        

END

GO
