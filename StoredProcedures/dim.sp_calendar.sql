CREATE PROCEDURE [dim].[sp_calendar]
AS
BEGIN
    -- Drop the calendar table if it already exists
    DROP TABLE IF EXISTS dim.calendar;

    -- Create the calendar table in the dim schema
    CREATE TABLE dim.calendar (
        Calendar_Key INT PRIMARY KEY,
        Date DATE NULL,
        Year INT NOT NULL,
        Quarter INT NOT NULL,
        Month INT NOT NULL,
        Day INT NOT NULL,
        WeekNumber INT NOT NULL,
        Weekday INT NOT NULL,
        DayName VARCHAR(20) NOT NULL,
        MonthName VARCHAR(20) NOT NULL,
        QuarterName VARCHAR(20) NOT NULL,
        YearMonth_int INT NOT NULL,
        YearWeek_int INT NOT NULL,
        FirstDayOfMonth DATE NULL,
        LastDayOfMonth DATE NULL,
        IsLastDayOfMonth BIT NOT NULL,
        YearMonth_Str NVARCHAR(8), -- Column for year and month in the yyyy-mon format
        IsWeekday BIT NOT NULL -- New column for weekday indicator
    );

    -- Insert rows for each day from 2000 to 2050
    WITH DateSequence AS (
        SELECT
            CAST('2000-01-01' AS DATE) AS DateValue
        UNION ALL
        SELECT
            DATEADD(DAY, 1, DateValue)
        FROM
            DateSequence
        WHERE
            DateValue < '2050-12-31'
    )
    INSERT INTO dim.calendar (
        Calendar_Key, Date, Year, Quarter, Month, Day, WeekNumber, Weekday, DayName, MonthName, QuarterName, 
        YearMonth_int, YearWeek_int, FirstDayOfMonth, LastDayOfMonth, IsLastDayOfMonth, YearMonth_Str, IsWeekday
    )
    SELECT
        CAST(CONVERT(VARCHAR, DateValue, 112) AS INT) AS Calendar_Key, -- Format YYYYMMDD as an integer
        DateValue AS Date,
        YEAR(DateValue) AS Year,
        DATEPART(QUARTER, DateValue) AS Quarter,
        MONTH(DateValue) AS Month,
        DAY(DateValue) AS Day,
        DATEPART(ISO_WEEK, DateValue) AS WeekNumber, -- Danish week numbering (ISO 8601)
        CASE 
            WHEN DATEPART(WEEKDAY, DateValue) = 1 THEN 7 -- Adjust Sunday to 7
            ELSE DATEPART(WEEKDAY, DateValue) - 1 -- Shift other days so Monday becomes 1
        END AS Weekday,
        DATENAME(WEEKDAY, DateValue) AS DayName,
        DATENAME(MONTH, DateValue) AS MonthName,
        CONCAT('Q', DATEPART(QUARTER, DateValue)) AS QuarterName,
        YEAR(DateValue) * 100 + MONTH(DateValue) AS YearMonth_int, -- Year and Month in YYYYMM format
        YEAR(DateValue) * 100 + DATEPART(ISO_WEEK, DateValue) AS YearWeek_int, -- Year and ISO Week number in YYYYWW format
        DATEFROMPARTS(YEAR(DateValue), MONTH(DateValue), 1) AS FirstDayOfMonth, -- First day of the month
        EOMONTH(DateValue) AS LastDayOfMonth, -- Last day of the month
        CASE WHEN DateValue = EOMONTH(DateValue) THEN 1 ELSE 0 END AS IsLastDayOfMonth, -- Flag if it's the last day of the month
        CONVERT(VARCHAR(4), YEAR(DateValue)) + '-' + LEFT(DATENAME(MONTH, DateValue), 3) AS YearMonth_Str, -- YearMonth_Str as yyyy-mon
        CASE 
            WHEN DATEPART(WEEKDAY, DateValue) IN (2, 3, 4, 5, 6) THEN 1 -- Monday to Friday are weekdays
            ELSE 0 -- Saturday and Sunday are not weekdays
        END AS IsWeekday -- Calculate if the date is a weekday
    FROM
        DateSequence
    OPTION (MAXRECURSION 32767);

    -- Delete old surrogate key records for Calendar in KeyVault.SurrogateKeys
    DELETE FROM KeyVault.SurrogateKeys WHERE SourceTable = 'Calendar';

    -- Enable IDENTITY_INSERT on the KeyVault.SurrogateKeys table
    SET IDENTITY_INSERT KeyVault.SurrogateKeys ON;

    -- Insert data based on values from the dim.calendar table
    INSERT INTO KeyVault.SurrogateKeys (
        Surrogate_Key, -- Explicitly specify the identity column
        DW_ValidFrom,
        SourceSchema,
        SourceTable,
        BK_Col1
    )
    SELECT 
        Calendar_Key, -- Explicit value for the identity column
        Date AS DW_ValidFrom,
        'dim' AS SourceSchema,       -- Example static values
        'Calendar' AS SourceTable,       -- Example static values
        CAST(Date AS NVARCHAR(255)) AS BK_Col1 -- Using Calendar_Key as business key column 1
    FROM dim.calendar;

    -- Add an unknown member to the calendar table
    INSERT INTO dim.calendar (
        Calendar_Key,
        Date,
        Year,
        Quarter,
        Month,
        Day,
        WeekNumber,
        Weekday,
        DayName,
        MonthName,
        QuarterName,
        YearMonth_int,
        YearWeek_int,
        FirstDayOfMonth,
        LastDayOfMonth,
        IsLastDayOfMonth,
        YearMonth_Str,
        IsWeekday
    )
    VALUES (
        -1, -- Surrogate Key for unknown date
        NULL, -- Date is unknown
        -1,   -- Year is unknown
        -1,   -- Quarter is unknown
        -1,   -- Month is unknown
        -1,   -- Day is unknown
        -1,   -- WeekNumber is unknown
        -1,   -- Weekday is unknown
        'Unknown', -- DayName is unknown
        'Unknown', -- MonthName is unknown
        'Unknown', -- QuarterName is unknown
        -1,   -- YearMonth_int is unknown
        -1,   -- YearWeek_int is unknown
        NULL, -- FirstDayOfMonth is unknown
        NULL, -- LastDayOfMonth is unknown
        0,     -- IsLastDayOfMonth is false
        'Unknown', -- YearMonth_Str is unknown
        0      -- IsWeekday is false
    );

    -- Disable IDENTITY_INSERT on the KeyVault.SurrogateKeys table
    SET IDENTITY_INSERT KeyVault.SurrogateKeys OFF;
END;
GO
