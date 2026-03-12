CREATE PROC [utility].[sp_create_keyvault] as 
begin
-- Drop the KeyVault.SurrogateKeys table if it already exists
DROP TABLE IF EXISTS KeyVault.SurrogateKeys;

-- Create the KeyVault.SurrogateKeys table
CREATE TABLE KeyVault.SurrogateKeys (
    Surrogate_Key BIGINT IDENTITY(1,1) PRIMARY KEY,
    DW_ValidFrom DATETIME2(7) NULL,
    SourceSchema NVARCHAR(255) NOT NULL,
    SourceTable NVARCHAR(255) NOT NULL,
    BK_Col1 NVARCHAR(255),
    BK_Col2 NVARCHAR(255),
    BK_Col3 NVARCHAR(255),
    BK_Col4 NVARCHAR(255),
    BK_Col5 NVARCHAR(255),
    BK_Col6 NVARCHAR(255),
    -- Create a hash column for uniqueness, ensuring all inputs have fixed lengths
    DataHash AS HASHBYTES('SHA2_256', 
        CONCAT(
            CONVERT(NVARCHAR(50), DW_ValidFrom, 126), -- Convert date to ISO format
            RIGHT('0000' + SourceSchema, 255),
            RIGHT('0000' + SourceTable, 255),
            RIGHT('0000' + BK_Col1, 255),
            RIGHT('0000' + BK_Col2, 255),
            RIGHT('0000' + BK_Col3, 255),
            RIGHT('0000' + BK_Col4, 255),
            RIGHT('0000' + BK_Col5, 255),
            RIGHT('0000' + BK_Col6, 255)
        )
    ) PERSISTED,
    -- Define a unique constraint on the hash column
    CONSTRAINT UQ_SurrogateKeys_DataHash UNIQUE (DataHash)
);
end
GO
