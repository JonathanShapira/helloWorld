CREATE   VIEW [stg].[v_ValutaKurser] AS
SELECT 
    Currency_Code
    ,Exchange_Rate_Amount
    ,Relational_Exch_Rate_Amount
    ,Starting_Date DW_ValidFrom
    ,ISNULL(LEAD(Starting_Date) OVER(PARTITION BY Currency_Code order by Starting_Date),'9999-12-31') DW_ValidTo
    ,Company
FROM stg.Valutakurser
GO
