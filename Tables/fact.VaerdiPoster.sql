CREATE TABLE [fact].[VaerdiPoster]
(
    [Calendar_Key] INT NULL,
    [Varer_key] BIGINT NULL,
    [lokationer_key] BIGINT NULL,
    [Debitorer_key] BIGINT NULL,
    [Company_key] BIGINT NULL,
    [Document_Type] NVARCHAR(MAX) NULL,
    [Sales_Amount_Actual] FLOAT NULL,
    [Cost_Amount_Actual] FLOAT NULL,
    [Source_Type] NVARCHAR(MAX) NULL,
    [Dimension_Set_ID] BIGINT NULL,
    [Invoiced_Quantity] FLOAT NULL,
    [DaysSinceFirstPurchase] INT NULL
);
GO
