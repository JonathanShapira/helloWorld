CREATE VIEW [stg].[v_CashflowLayout] AS
SELECT 
    COALESCE([KPIGroup], KPI, ds.[Skipped lines]) AS KPIGroup,
    COALESCE([KPI], ds.[Skipped lines]) AS KPI,
    [SortOrder],
    [GroupSortOrder],
    CASE WHEN [Highlight] = 'TRUE' THEN ds.[Highlight background color] ELSE ds.[Background color] END AS BackgroundColor,
    COALESCE([InvertSign], ds.[Invert sign]) AS InvertSign
    ,coalesce(c.Type,ds.[Type]) as [Type]
FROM [stg].[Cashflow] c
LEFT JOIN [stg].[DefaultSettings] ds ON 1=1
GO
