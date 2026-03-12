CREATE VIEW [stg].[v_Debitorer] as
select 
      [No]
      ,[Name]
      ,[Name_2]
      ,[Responsibility_Center]
      ,[Location_Code]
      ,[Post_Code]
      ,[Country_Region_Code]
      ,[Phone_No]
      ,[IC_Partner_Code]
      ,[Contact]
      ,[Salesperson_Code]
      ,[Customer_Posting_Group]
      ,[Allow_Multiple_Posting_Groups]
      ,[Gen_Bus_Posting_Group]
      ,[VAT_Bus_Posting_Group]
      ,[Customer_Price_Group]
      ,[Customer_Disc_Group]
      ,[Payment_Terms_Code]
      ,[Reminder_Terms_Code]
      ,[Fin_Charge_Terms_Code]
      ,[Currency_Code]
      ,[Language_Code]
      ,[Search_Name]
      ,[Credit_Limit_LCY]
      ,[Blocked]
      ,[Privacy_Blocked]
      ,[Application_Method]
      ,[Combine_Shipments]
      ,[Reserve]
      ,[Ship_to_Code]
      ,[Shipping_Advice]
      ,[Shipping_Agent_Code]
      ,[Base_Calendar_Code]
      ,[Balance_LCY]
      ,[Balance_Due_LCY]
      ,[Sales_LCY]
      ,[Payments_LCY]
      ,[Coupled_to_CRM]
      ,[Coupled_to_Dataverse]
      ,[Global_Dimension_1_Filter]
      ,[Global_Dimension_2_Filter]
      ,[Currency_Filter]
      ,[Date_Filter]
      ,Company
    ,CAST(Last_Date_Modified as date) Last_Date_Modified
    ,vp.FirstPurchaseDate
from stg.Debitorer d
left join (
    SELECT 
        CAST(MIN(Posting_Date) as date) FirstPurchaseDate
        ,Source_No 
    from  stg.VærdiPoster vp 
    group by Source_No
) vp on d.no = vp.Source_No
GO
