CREATE TABLE [switch].[fact_Sagsplanlægningslinjer]
(
    [Calendar_Key] INT NULL,
    [Sagsopgavelinjer_key] BIGINT NULL,
    [Sager_key] BIGINT NULL,
    [Debitorer_key] BIGINT NULL,
    [ressourcer_key] BIGINT NULL,
    [Line_Amount_LCY] FLOAT NULL,
    [Quantity] FLOAT NULL,
    [Line_Type] NVARCHAR(MAX) NULL
);
GO
