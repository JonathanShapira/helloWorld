CREATE VIEW [stg].[v_Sager] as
SELECT       [No]
      ,[Description]
      ,[Bill_to_Customer_No]
      ,[Status]
      ,[Person_Responsible]
      ,[Next_Invoice_Date]
      ,[Job_Posting_Group]
      ,[Search_Description]
      ,[Percent_of_Overdue_Planning_Lines]
      ,[Percent_Completed]
      ,[Percent_Invoiced]
      ,[Project_Manager]
      ,[External_Document_No]
      ,[Your_Reference]
      ,Company 
      FROM stg.Sager
GO
