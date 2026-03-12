CREATE view [stg].[v_KPIMapping] as
SELECT distinct [Virksomhed] Company,
      [KPI]
  FROM [stg].[KPIMapping]


GO
