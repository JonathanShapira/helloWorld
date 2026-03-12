CREATE TABLE [switch].[Valutakurser]
(
    [Valutakurser_Key] BIGINT NULL,
    [Currency_Code] NVARCHAR(MAX) NULL,
    [Exchange_Rate_Amount] FLOAT NULL,
    [Relational_Exch_Rate_Amount] FLOAT NULL,
    [DW_ValidFrom] NVARCHAR(MAX) NULL,
    [DW_ValidTo] NVARCHAR(MAX) NOT NULL,
    [Company] VARCHAR(100) NULL
);
GO
