create view stg.v_DimensionGroups as
SELECT distinct [Dimension_Set_ID]
      ,[Company]
  FROM [stg].[DimensionGroups]
GO
