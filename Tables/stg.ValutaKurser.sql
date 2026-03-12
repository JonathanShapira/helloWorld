CREATE TABLE [stg].[ValutaKurser]
(
    [@odata.etag] NVARCHAR(MAX) NULL,
    [Currency_Code] NVARCHAR(MAX) NULL,
    [Starting_Date] NVARCHAR(MAX) NULL,
    [Relational_Currency_Code] NVARCHAR(MAX) NULL,
    [Exchange_Rate_Amount] FLOAT NULL,
    [Relational_Exch_Rate_Amount] FLOAT NULL,
    [Adjustment_Exch_Rate_Amount] FLOAT NULL,
    [Relational_Adjmt_Exch_Rate_Amt] FLOAT NULL,
    [Fix_Exchange_Rate_Amount] NVARCHAR(MAX) NULL,
    [@odata.context] NVARCHAR(MAX) NULL,
    [Company] VARCHAR(100) NULL
);
GO
