create view [stg].[v_GLAccounts] as
SELECT [No]
      ,[Name]
      ,[Income_Balance]
      ,[Account_Category]
      ,[Account_Subcategory_Descript]
      ,[Account_Type]
      ,[Direct_Posting]
      ,[Totaling]
      ,[Gen_Posting_Type]
      ,[Company]
  FROM [stg].[GLAccounts]
GO
