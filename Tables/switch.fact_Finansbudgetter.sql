CREATE TABLE [switch].[fact_Finansbudgetter]
(
    [BudgetNames_key] BIGINT NULL,
    [Calendar_Key] INT NULL,
    [Accounts_key] BIGINT NULL,
    [Amount] FLOAT NULL,
    [DimensionGroupKeys_key] BIGINT NULL,
    [Company_key] BIGINT NULL
);
GO
