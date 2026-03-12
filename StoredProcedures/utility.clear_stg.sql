CREATE     proc [utility].[clear_stg] as 
begin

	declare @schema nvarchar(max) = 'stg'
	declare @table nvarchar(max)
	declare @sql_base nvarchar(max) = 'TRUNCATE TABLE <schema>.<table>'
	declare @sql nvarchar(max)

	declare @i int = 1
	declare @maxi int 

	DROP TABLE IF EXISTS #tmp
	SELECT 
		*,ROW_NUMBER() OVER(ORDER BY (SELECT 0)) rwn
	into #tmp
	FROM INFORMATION_SCHEMA.TABLES 
    where TABLE_SCHEMA = @schema
    AND TABLE_TYPE = 'BASE TABLE'


	
	SELECT @maxi = MAX(rwn) FROM #tmp
	
	while @i <= @maxi
	BEGIN

		SELECT @sql = @sql_base
		SELECT 
			@table = TABLE_NAME
			,@schema=TABLE_SCHEMA 
		from #tmp where rwn = @i

		SELECT @sql = REPLACE(@sql,'<schema>',@schema)
		SELECT @sql = REPLACE(@sql,'<table>',@table)

		EXEC sp_executesql @sql

		SELECT @i = @i + 1
	END


end
GO
