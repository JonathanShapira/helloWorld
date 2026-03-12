
CREATE PROCEDURE [Utility].[SwitchTableProcedure]
    @switch_schema NVARCHAR(128),
    @switch_table_name NVARCHAR(128),
    @target_schema NVARCHAR(128),
    @target_table_name NVARCHAR(128),
    @force_switch BIT = 0, -- Default to not force switch
    @Accepted_Pct FLOAT = 95.00 -- Default to 95%
AS
BEGIN
    DECLARE @switch_table NVARCHAR(256) = QUOTENAME(@switch_schema) + '.' + QUOTENAME(@switch_table_name);
    DECLARE @target_table NVARCHAR(256) = QUOTENAME(@target_schema) + '.' + QUOTENAME(@target_table_name);
    DECLARE @error_message NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @switch_count INT;
    DECLARE @target_count INT;
    DECLARE @columns_match BIT = 1;
    DECLARE @indexes_match BIT = 1;

    BEGIN TRY
        -- Validate @Accepted_Pct range
        IF @Accepted_Pct < 0 OR @Accepted_Pct > 100
        BEGIN
            RAISERROR('@Accepted_Pct must be between 0 and 100.', 16, 1);
            RETURN;
        END

        -- Start the transaction
        BEGIN TRANSACTION InnerTrans;
        SAVE TRANSACTION InnerTrans;

        -- Step 1: Count the rows in both tables
        SET @sql = 'SELECT @switch_count_out = COUNT(*) FROM ' + @switch_table;
        PRINT @sql;  -- Print the SQL
        EXEC sp_executesql @sql, N'@switch_count_out INT OUTPUT', @switch_count_out = @switch_count OUTPUT;

        SET @sql = 'SELECT @target_count_out = COUNT(*) FROM ' + @target_table;
        PRINT @sql;  -- Print the SQL
        EXEC sp_executesql @sql, N'@target_count_out INT OUTPUT', @target_count_out = @target_count OUTPUT;

        -- Step 2: Validate row counts
        IF @switch_count < (@target_count * @Accepted_Pct / 100.0)
        BEGIN
            DECLARE @row_cnt_msg nvarchar(max) = 'Switch table has less than '+CAST(@Accepted_Pct as nvarchar(100))+' of the data in the target table. Switch aborted.'
            RAISERROR(@row_cnt_msg, 16, 1);
            ROLLBACK TRANSACTION InnerTrans;
            RETURN;
        END

        -- Step 3: Compare table definitions (columns)
        IF EXISTS (
            SELECT 1
            FROM (
                SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = @switch_schema AND TABLE_NAME = @switch_table_name
            ) AS switch_columns
            FULL OUTER JOIN (
                SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = @target_schema AND TABLE_NAME = @target_table_name
            ) AS target_columns
            ON switch_columns.COLUMN_NAME = target_columns.COLUMN_NAME
            AND switch_columns.DATA_TYPE = target_columns.DATA_TYPE
            AND ISNULL(switch_columns.CHARACTER_MAXIMUM_LENGTH, 0) = ISNULL(target_columns.CHARACTER_MAXIMUM_LENGTH, 0)
            AND switch_columns.IS_NULLABLE = target_columns.IS_NULLABLE
            WHERE switch_columns.COLUMN_NAME IS NULL OR target_columns.COLUMN_NAME IS NULL
        )
        BEGIN
            -- If there are differences in column definitions
            SET @columns_match = 0;
        END

        -- Step 4: Compare indexes
        IF EXISTS (
            SELECT 1
            FROM (
                SELECT i.name AS index_name, i.type_desc, i.is_unique,
                    STRING_AGG(c.name, ',') WITHIN GROUP (ORDER BY ic.index_column_id) AS index_columns
                FROM sys.indexes i
                JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
                JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                WHERE OBJECT_SCHEMA_NAME(i.object_id) = @switch_schema AND OBJECT_NAME(i.object_id) = @switch_table_name
                GROUP BY i.name, i.type_desc, i.is_unique
            ) AS switch_indexes
            FULL OUTER JOIN (
                SELECT i.name AS index_name, i.type_desc, i.is_unique,
                    STRING_AGG(c.name, ',') WITHIN GROUP (ORDER BY ic.index_column_id) AS index_columns
                FROM sys.indexes i
                JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
                JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                WHERE OBJECT_SCHEMA_NAME(i.object_id) = @target_schema AND OBJECT_NAME(i.object_id) = @target_table_name
                GROUP BY i.name, i.type_desc, i.is_unique
            ) AS target_indexes
            ON switch_indexes.index_name = target_indexes.index_name
            AND switch_indexes.type_desc = target_indexes.type_desc
            AND switch_indexes.is_unique = target_indexes.is_unique
            AND switch_indexes.index_columns = target_indexes.index_columns
            WHERE switch_indexes.index_name IS NULL OR target_indexes.index_name IS NULL
        )
        BEGIN
            -- If there are differences in index definitions
            SET @indexes_match = 0;
        END

        -- Step 5: If either columns or indexes don't match, check force switch
        IF @columns_match = 0 OR @indexes_match = 0
        BEGIN
            IF @force_switch = 1
            BEGIN
                PRINT 'Forcing target table to adopt the switch table definition.';
                -- Drop target table and recreate it with the structure of the switch table
                SET @sql = 'DROP TABLE IF EXISTS ' + @target_table + '; SELECT * INTO ' + @target_table + ' FROM ' + @switch_table + ' WHERE 1 = 0;';
                PRINT @sql;  -- Print the SQL for dropping and recreating the table
                EXEC sp_executesql @sql;

                -- Step 6: Copy indexes from switch table to target table (code omitted for brevity)
            END
            ELSE
            BEGIN
                -- If not forcing, raise an error and exit
                RAISERROR('The structures of the switch table and the target table do not match. Switch aborted.', 16, 1);
                ROLLBACK TRANSACTION InnerTrans;
                RETURN;
            END
        END
        ELSE
        BEGIN
            PRINT 'Table definitions and indexes match. Proceeding with the switch operation.';
        END

        -- Step 7: Truncate the target table
        SET @sql = 'TRUNCATE TABLE ' + @target_table + ';';
        PRINT @sql;  -- Print the truncate statement
        EXEC sp_executesql @sql;

        -- Step 8: Perform the switch operation
        SET @sql = 'ALTER TABLE ' + @switch_table + ' SWITCH TO ' + @target_table + ';';
        PRINT @sql;  -- Print the SQL for the switch operation
        EXEC sp_executesql @sql;

        -- Commit the transaction if everything succeeded
        COMMIT TRANSACTION InnerTrans;
        PRINT 'Table switch completed successfully.';
    END TRY
    BEGIN CATCH
        SET @error_message = ERROR_MESSAGE();
        PRINT 'An error occurred: ' + @error_message;

        -- Rollback the transaction in case of an error
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION InnerTrans;
            RAISERROR('Transaction rolled back.', 16, 1);
        END
    END CATCH
END;
GO
