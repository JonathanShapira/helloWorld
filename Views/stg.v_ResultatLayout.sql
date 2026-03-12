CREATE VIEW [stg].[v_ResultatLayout] AS
SELECT 
    COALESCE([KPIGroup], KPI, ds.[Skipped Lines]) AS KPIGroup,
    COALESCE([KPI], ds.[Skipped Lines]) AS KPI,
    [SortOrder],
    GroupSortOrder,
    Case when Highlight='TRUE' then ds.[Highlight background color] else ds.[Background Color] end as BackgroundColor,
    COALESCE([InvertSign],ds.[Invert Sign]) AS InvertSign
    ,coalesce(r.Type,ds.[Type]) as [Type]
FROM [stg].[Resultat] r
LEFT JOIN [stg].[DefaultSettings] ds on 1=1

GO
