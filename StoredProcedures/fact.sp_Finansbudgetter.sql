CREATE proc [fact].[sp_Finansbudgetter] as
DROP TABLE IF EXISTS switch.fact_Finansbudgetter
SELECT
      coalesce(bn.BudgetNames_key, -1) AS BudgetNames_key
      ,coalesce(c.Calendar_Key, -1) AS Calendar_Key
      ,coalesce(gla.Accounts_key, -1) AS Accounts_key
      ,[Amount]
      ,coalesce(dgk.DimensionGroupKeys_key, -1) AS DimensionGroupKeys_key
      ,coalesce(co.Company_key, -1) AS Company_key

    into switch.fact_Finansbudgetter
  FROM [stg].[Finansbudgetter] fb
  left join dim.Accounts gla on gla.Company = fb.Company and gla.No = fb.G_L_Account_No
  left join dim.calendar c on c.Date = fb.Date
  left join dim.Company co on co.Company = fb.Company
  left join dim.BudgetNames bn on bn.Budget_Name = fb.Budget_Name and bn.Company = fb.Company
  left join dim.DimensionGroupKeys dgk on dgk.Dimension_Set_ID = fb.Dimension_Set_ID and dgk.Company = fb.Company


exec utility.SwitchTableProcedure
  @Switch_Schema = 'switch',
  @switch_table_name = 'fact_Finansbudgetter',
  @Target_Schema = 'fact',
  @Target_Table_Name = 'Finansbudgetter',
  @force_switch = 1,
  @accepted_pct = 0
GO
