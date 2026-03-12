CREATE TABLE [fact].[salg]
(
    [Calendar_Key] INT NULL,
    [Debitorer_key] BIGINT NULL,
    [Varer_key] BIGINT NULL,
    [Valutakurser_key] BIGINT NULL,
    [Ressourcer_key] BIGINT NULL,
    [Accounts_key] BIGINT NULL,
    [Company_key] BIGINT NULL,
    [Lokationer_key] BIGINT NULL,
    [Line_Amount] FLOAT NULL,
    [Line_Amount_DKK] FLOAT NULL,
    [Line_Discount_Amount] FLOAT NULL,
    [Line_Discount_Amount_DKK] FLOAT NULL,
    [Quantity] FLOAT NULL,
    [Cost_Amount_Actual] FLOAT NULL
);
GO
