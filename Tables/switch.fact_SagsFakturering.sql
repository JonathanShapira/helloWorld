CREATE TABLE [switch].[fact_SagsFakturering]
(
    [Entry_No] BIGINT NULL,
    [Calendar_Key] INT NULL,
    [Posting_Date] NVARCHAR(MAX) NULL,
    [Sagsopgavelinjer_key] BIGINT NULL,
    [Sager_key] BIGINT NULL,
    [Debitorer_key] BIGINT NULL,
    [Ressourcer_Key] BIGINT NULL,
    [Company_key] BIGINT NULL,
    [Line_Amount_LCY] FLOAT NULL,
    [Total_Cost_LCY] FLOAT NULL,
    [Quantity] FLOAT NULL
);
GO
