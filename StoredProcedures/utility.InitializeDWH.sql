CREATE PROC [utility].[InitializeDWH] AS
BEGIN
    EXEC utility.sp_create_keyvault
    EXEC dim.sp_calendar
END
GO
