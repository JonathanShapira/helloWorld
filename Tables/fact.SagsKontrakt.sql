CREATE TABLE [fact].[SagsKontrakt]
(
    [Calendar_Key] INT NULL,
    [Sagsopgavelinjer_key] BIGINT NULL,
    [Sager_key] BIGINT NULL,
    [Debitorer_key] BIGINT NULL,
    [Ressourcer_key] BIGINT NULL,
    [Company_key] BIGINT NULL,
    [Line_Amount_LCY] FLOAT NULL,
    [Total_Cost_LCY] FLOAT NULL,
    [Quantity] FLOAT NULL
);
GO
