CREATE   PROCEDURE dim.sp_Varer
    AS
    BEGIN

        /* Script used to create this

        EXEC utility.sp_create_T1_dimension_view_based_proc
            @Target_Schema = 'dim',
            @Target_Table_Name = 'Varer',
            @Source_View_Schema = 'stg',
            @Source_View_Name = 'v_Varer',
            @Switch_Schema = 'switch',
            @BKs = '[NO],[Company]',
            @Include_DW_ValidFrom = 0
        */

        SET NOCOUNT ON;

        DECLARE @sql_chk_dupl NVARCHAR(MAX);
        DECLARE @cnt_dupl INT = 0;
        DECLARE @err_msg NVARCHAR(MAX);
        DECLARE @StartOfUniverse datetime2(7)= '1900-01-01'
        DECLARE @EndOfUniverse datetime2(7) = '9999-12-31 23:59:59.9999999'

        -- Duplicate check based on bk columns
        SET @sql_chk_dupl = '
        ;WITH cte AS (
            SELECT *,
                COUNT(0) OVER(PARTITION BY [NO],[Company]) AS cnt_1
            FROM [stg].[v_Varer]
        )
        SELECT @cnt_dupl_out = COUNT(0)
        FROM cte
        WHERE cnt_1 > 1;';


        -- Execute the dynamic SQL and use @cnt_dupl as an output parameter
        EXEC sp_executesql @sql_chk_dupl, N'@cnt_dupl_out INT OUTPUT', @cnt_dupl_out = @cnt_dupl OUTPUT;

        -- Check for duplicates and raise an error if any are found
        IF @cnt_dupl > 0
        BEGIN
            SET @err_msg = 'Duplicate entry based on BK columns. Please use: ' + @sql_chk_dupl;
            RAISERROR (@err_msg, 16, 1);
            RETURN;
        END

        DROP TABLE IF EXISTS temp.Varer;
        SELECT *
        INTO temp.Varer
        FROM [stg].[v_Varer];
        


        INSERT INTO KeyVault.SurrogateKeys (
            
            SourceSchema,
            SourceTable,
            [BK_Col1],[BK_Col2]
        )
        SELECT 
            
            'dim',
            'Varer',
            dd.[NO],dd.[Company]
        FROM temp.Varer dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'Varer'
            AND	sk.[BK_Col1] = CAST(dd.[NO] as nvarchar(255))AND	sk.[BK_Col2] = CAST(dd.[Company] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NULL;

        DROP TABLE IF EXISTS switch.[Varer]

        SELECT 
            sk.Surrogate_key Varer_Key
            ,dd.[No],dd.[Description],dd.[Description_2],dd.[Type],dd.[InventoryField],dd.[Created_From_Nonstock_Item],dd.[Substitutes_Exist],dd.[Stockkeeping_Unit_Exists],dd.[Assembly_BOM],dd.[Production_BOM_No],dd.[Routing_No],dd.[Base_Unit_of_Measure],dd.[Shelf_No],dd.[Costing_Method],dd.[Cost_is_Adjusted],dd.[Standard_Cost],dd.[Unit_Cost],dd.[Last_Direct_Cost],dd.[Price_Profit_Calculation],dd.[Profit_Percent],dd.[Unit_Price],dd.[Inventory_Posting_Group],dd.[Gen_Prod_Posting_Group],dd.[VAT_Prod_Posting_Group],dd.[Item_Disc_Group],dd.[Vendor_No],dd.[Vendor_Item_No],dd.[Tariff_No],dd.[Search_Description],dd.[Overhead_Rate],dd.[Indirect_Cost_Percent],dd.[Item_Category_Code],dd.[Blocked],dd.[Last_Date_Modified],dd.[Sales_Unit_of_Measure],dd.[Replenishment_System],dd.[Purch_Unit_of_Measure],dd.[Lead_Time_Calculation],dd.[Manufacturing_Policy],dd.[Flushing_Method],dd.[Assembly_Policy],dd.[Item_Tracking_Code],dd.[Default_Deferral_Template_Code],dd.[Coupled_to_CRM],dd.[Coupled_to_Dataverse],dd.[GTIN],dd.[Global_Dimension_1_Filter],dd.[Global_Dimension_2_Filter],dd.[Location_Filter],dd.[Drop_Shipment_Filter],dd.[Variant_Filter],dd.[Lot_No_Filter],dd.[Serial_No_Filter],dd.[Unit_of_Measure_Filter],dd.[Package_No_Filter],dd.[Company]
        into switch.[Varer]
        FROM temp.Varer dd
        LEFT JOIN KeyVault.SurrogateKeys sk
            ON sk.SourceSchema = 'dim'
            AND sk.SourceTable = 'Varer'
            AND	sk.[BK_Col1] = CAST(dd.[NO] as nvarchar(255))AND	sk.[BK_Col2] = CAST(dd.[Company] as nvarchar(255))
            
        WHERE sk.Surrogate_Key IS NOT NULL;


        INSERT INTO switch.[Varer] 
        (
            Varer_Key
            ,[No],[Description],[Description_2],[Type],[InventoryField],[Created_From_Nonstock_Item],[Substitutes_Exist],[Stockkeeping_Unit_Exists],[Assembly_BOM],[Production_BOM_No],[Routing_No],[Base_Unit_of_Measure],[Shelf_No],[Costing_Method],[Cost_is_Adjusted],[Standard_Cost],[Unit_Cost],[Last_Direct_Cost],[Price_Profit_Calculation],[Profit_Percent],[Unit_Price],[Inventory_Posting_Group],[Gen_Prod_Posting_Group],[VAT_Prod_Posting_Group],[Item_Disc_Group],[Vendor_No],[Vendor_Item_No],[Tariff_No],[Search_Description],[Overhead_Rate],[Indirect_Cost_Percent],[Item_Category_Code],[Blocked],[Last_Date_Modified],[Sales_Unit_of_Measure],[Replenishment_System],[Purch_Unit_of_Measure],[Lead_Time_Calculation],[Manufacturing_Policy],[Flushing_Method],[Assembly_Policy],[Item_Tracking_Code],[Default_Deferral_Template_Code],[Coupled_to_CRM],[Coupled_to_Dataverse],[GTIN],[Global_Dimension_1_Filter],[Global_Dimension_2_Filter],[Location_Filter],[Drop_Shipment_Filter],[Variant_Filter],[Lot_No_Filter],[Serial_No_Filter],[Unit_of_Measure_Filter],[Package_No_Filter],[Company]
        )
        SELECT 
            -1
,'UNKNOWN' AS [No]
,'UNKNOWN' AS [Description]
,'UNKNOWN' AS [Description_2]
,'UNKNOWN' AS [Type]
,0.0 AS [InventoryField]
,0 AS [Created_From_Nonstock_Item]
,0 AS [Substitutes_Exist]
,0 AS [Stockkeeping_Unit_Exists]
,0 AS [Assembly_BOM]
,'UNKNOWN' AS [Production_BOM_No]
,'UNKNOWN' AS [Routing_No]
,'UNKNOWN' AS [Base_Unit_of_Measure]
,'UNKNOWN' AS [Shelf_No]
,'UNKNOWN' AS [Costing_Method]
,0 AS [Cost_is_Adjusted]
,0.0 AS [Standard_Cost]
,0.0 AS [Unit_Cost]
,0.0 AS [Last_Direct_Cost]
,'UNKNOWN' AS [Price_Profit_Calculation]
,0.0 AS [Profit_Percent]
,0.0 AS [Unit_Price]
,'UNKNOWN' AS [Inventory_Posting_Group]
,'UNKNOWN' AS [Gen_Prod_Posting_Group]
,'UNKNOWN' AS [VAT_Prod_Posting_Group]
,'UNKNOWN' AS [Item_Disc_Group]
,'UNKNOWN' AS [Vendor_No]
,'UNKNOWN' AS [Vendor_Item_No]
,'UNKNOWN' AS [Tariff_No]
,'UNKNOWN' AS [Search_Description]
,0.0 AS [Overhead_Rate]
,0.0 AS [Indirect_Cost_Percent]
,'UNKNOWN' AS [Item_Category_Code]
,0 AS [Blocked]
,'UNKNOWN' AS [Last_Date_Modified]
,'UNKNOWN' AS [Sales_Unit_of_Measure]
,'UNKNOWN' AS [Replenishment_System]
,'UNKNOWN' AS [Purch_Unit_of_Measure]
,'UNKNOWN' AS [Lead_Time_Calculation]
,'UNKNOWN' AS [Manufacturing_Policy]
,'UNKNOWN' AS [Flushing_Method]
,'UNKNOWN' AS [Assembly_Policy]
,'UNKNOWN' AS [Item_Tracking_Code]
,'UNKNOWN' AS [Default_Deferral_Template_Code]
,0 AS [Coupled_to_CRM]
,0 AS [Coupled_to_Dataverse]
,'UNKNOWN' AS [GTIN]
,'UNKNOWN' AS [Global_Dimension_1_Filter]
,'UNKNOWN' AS [Global_Dimension_2_Filter]
,'UNKNOWN' AS [Location_Filter]
,'UNKNOWN' AS [Drop_Shipment_Filter]
,'UNKNOWN' AS [Variant_Filter]
,'UNKNOWN' AS [Lot_No_Filter]
,'UNKNOWN' AS [Serial_No_Filter]
,'UNKNOWN' AS [Unit_of_Measure_Filter]
,'UNKNOWN' AS [Package_No_Filter]
,'UNKNOWN' AS [Company]

        DROP TABLE IF EXISTS temp.Varer

        EXEC utility.SwitchTableProcedure 
            @Switch_Schema = 'switch'
            ,@switch_table_name='Varer'
            ,@Target_Schema='dim'
            ,@Target_Table_Name = 'Varer'
            ,@force_switch = 0
            ,@accepted_pct = 95.00


    END
GO
