CREATE   PROC [fact].[sp_salg] AS
BEGIN

    DROP TABLE IF EXISTS temp.fact_salg
    ;with cte1 as (
    SELECT 
        coalesce(c.Calendar_Key,-1) Calendar_Key
        ,coalesce(deb.Debitorer_key,-1) Debitorer_key
        ,coalesce(v.Varer_key,-1) Varer_key
        ,coalesce(vk.Valutakurser_key,-1) Valutakurser_key
        ,coalesce(r.Ressourcer_key,-1) Ressourcer_key
        ,coalesce(a.Accounts_key,-1) Accounts_key
        ,coalesce(co.Company_key,-1) Company_key
        ,coalesce(l.Lokationer_key,-1) Lokationer_key
        ,bsfl.Line_Amount
        ,coalesce(bsfl.Line_Amount*vk.Relational_Exch_Rate_Amount/Exchange_Rate_Amount,bsfl.Line_Amount) Line_Amount_DKK
        ,Line_Discount_Amount
        ,coalesce(bsfl.Line_Discount_Amount*vk.Relational_Exch_Rate_Amount/Exchange_Rate_Amount,bsfl.Line_Discount_Amount) Line_Discount_Amount_DKK
        ,bsfl.Unit_Cost_LCY*bsfl.Quantity as Cost_Amount_Actual
        ,Quantity
        ,bsf.[No]
        ,bsfl.Line_No
        ,bsf.Company
--        ,bsf.*
--        ,bsfl.*
    FROM [stg].[BogførteSalgsfakturaer] bsf
    left join dim.Debitorer deb 
        on bsf.Sell_to_Customer_No = deb.[NO]
        and bsf.Company = deb.Company
    left join dim.calendar c
        on bsf.Posting_Date = c.[Date]
    left join stg.BogførteSalgsfakturaLinjer bsfl
        on bsf.[No] = bsfl.Document_No
        and bsf.Company = bsfl.Company
    left join dim.Varer v 
        on bsfl.no = v.[No] and bsfl.type = 'Item'
        and bsfl.Company = v.Company
    left join dim.valutakurser vk
        on bsf.Currency_Code = vk.currency_code
        AND bsf.posting_date >= vk.DW_ValidFrom
        AND bsf.posting_date < vk.DW_ValidTo
        and bsf.Company = vk.Company
    left join dim.Ressourcer r 
        on bsfl.no = r.[No] and bsfl.type = 'Resource'
        and bsfl.Company = r.Company
    left join dim.accounts a   
        on bsfl.[No] = a.[No] and bsfl.type = 'G/L Account'
        and bsfl.Company = a.Company
    left join dim.company co
        on bsf.Company = co.[Company]
    left join dim.Lokationer l
        on bsfl.Location_Code = l.[Code]
        and bsfl.Company = l.Company
    -- WHERE Debitorer_key = 20501460
    -- ORDER BY bsf.Posting_Date desc
    )

    ,cte2 as (
        SELECT 
            coalesce(c.Calendar_Key,-1) Calendar_Key
            ,coalesce(deb.Debitorer_key,-1) Debitorer_key
            ,coalesce(v.Varer_key,-1) Varer_key
            ,coalesce(vk.Valutakurser_key,-1) Valutakurser_key
            ,coalesce(r.Ressourcer_key,-1) Ressourcer_key
            ,coalesce(a.Accounts_key,-1) Accounts_key
            ,coalesce(co.Company_key,-1) Company_key
            ,-1 Lokationer_key
            ,-1*bsfl.Line_Amount Line_Amount
            ,coalesce(-1*bsfl.Line_Amount*vk.Relational_Exch_Rate_Amount/Exchange_Rate_Amount,-1*bsfl.Line_Amount) Line_Amount_DKK
            ,-1*Line_Discount_Amount Line_Discount_Amount
            ,coalesce(-1*bsfl.Line_Discount_Amount*vk.Relational_Exch_Rate_Amount/Exchange_Rate_Amount,-1*bsfl.Line_Discount_Amount) Line_Discount_Amount_DKK
            ,-1*bsfl.Unit_Cost_LCY*bsfl.Quantity as Cost_Amount_Actual
            ,Quantity
            ,bsf.[No]
            ,bsfl.Line_No
            ,bsf.Company
    --        ,bsf.*
    --        ,bsfl.*
    -- SELECT * 
    FROM [stg].[BogførteKreditNotaer] bsf
    LEFT JOIN stg.debitorposter dp
        on bsf.[no] = dp.Document_No
        and dp.document_type = 'Credit Memo'
        and dp.company = bsf.Company
    left join dim.Debitorer deb 
        on dp.Customer_NO = deb.[NO]
        and bsf.Company = deb.Company
    left join dim.calendar c
        on bsf.Posting_Date = c.[Date]
    left join stg.BogførteKreditNotaLinjer bsfl
        on bsf.[No] = bsfl.Document_No
        and bsf.Company = bsfl.Company
    left join dim.Varer v 
        on bsfl.no = v.[No]
        and bsfl.Company = v.Company
    left join dim.valutakurser vk
        on bsf.Sell_to_Country_Region_Code = vk.currency_code
        AND bsf.posting_date >= vk.DW_ValidFrom
        AND bsf.posting_date < vk.DW_ValidTo
        and bsf.Company = vk.Company         
    left join dim.accounts a   
        on bsfl.[No] = a.[No] and bsfl.type = 'G/L Account'
        and bsfl.Company = a.Company
    left join dim.Ressourcer r 
        on bsfl.no = r.[No] and bsfl.type = 'Resource'
        and bsfl.Company = r.Company
    left join dim.company co
        on bsf.Company = co.[Company]

    )
    ,cte3 as (
        SELECT * FROM cte1
        union
        SELECT * FROM cte2
    )
    SELECT 
        c.*
        --,vp.Cost_Amount_Actual 
    into temp.fact_salg
    FROM cte3 c

    DROP TABLE IF EXISTS switch.fact_salg
    SELECT 
        Calendar_Key
        ,Debitorer_key
        ,Varer_key
        ,Valutakurser_key
        ,Ressourcer_key
        ,Accounts_key
        ,Company_key
        ,Lokationer_key
        ,Line_Amount
        ,Line_Amount_DKK
        ,Line_Discount_Amount
        ,Line_Discount_Amount_DKK
        ,Quantity
        ,coalesce(vp.Cost_Amount_Actual, 0) Cost_Amount_Actual
    into switch.fact_salg
    FROM temp.fact_salg fs
    left join stg.VærdiPoster vp
        on fs.[No] = vp.Document_No
        and fs.Line_No = vp.Document_Line_No
        and fs.Company = vp.Company

    

        EXEC utility.SwitchTableProcedure 
            @Switch_Schema = 'switch'
            ,@switch_table_name='fact_salg'
            ,@Target_Schema='fact'
            ,@Target_Table_Name = 'salg'
            ,@force_switch = 1
            ,@accepted_pct = 0



    DROP TABLE IF EXISTS temp.fact_salg



END

GO
