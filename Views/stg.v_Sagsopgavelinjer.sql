CREATE VIEW [stg].[v_Sagsopgavelinjer] as
SELECT  

      [Job_No]
      ,[Job_Task_No]
      ,[Description]
      ,[Job_Task_Type]
      ,[Totaling]
      ,[Job_Posting_Group]
      ,[Location_Code]
      ,[Bin_Code]
      ,[WIP_Total]
      ,[WIP_Method]
      ,[Schedule_Total_Cost]
      ,[Schedule_Total_Price]
      ,[Usage_Total_Cost]
      ,[Usage_Total_Price]
      ,[Contract_Total_Cost]
      ,[Contract_Total_Price]
      ,[Contract_Invoiced_Cost]
      ,[Contract_Invoiced_Price]
      ,[Remaining_Total_Cost]
      ,[Remaining_Total_Price]
      ,[EAC_Total_Cost]
      ,[EAC_Total_Price]
      ,[Global_Dimension_1_Code]
      ,[Global_Dimension_2_Code]
      ,[Outstanding_Orders]
      ,[Amt_Rcd_Not_Invoiced]
      ,[Coupled_to_Dataverse]
      ,[Planning_Date_Filter]
      ,[Posting_Date_Filter]
      ,Company

        ,CAST(REPLACE(Start_Date,'0001-01-01','1900-01-01') as date) Start_Date
        ,CAST(REPLACE(End_Date,'0001-01-01','1900-01-01') as date) End_Date
FROM stg.Sagsopgavelinjer
GO
