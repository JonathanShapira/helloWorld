CREATE TABLE [dim].[calendar]
(
    [Calendar_Key] INT NOT NULL,
    [Date] DATE NULL,
    [Year] INT NOT NULL,
    [Quarter] INT NOT NULL,
    [Month] INT NOT NULL,
    [Day] INT NOT NULL,
    [WeekNumber] INT NOT NULL,
    [Weekday] INT NOT NULL,
    [DayName] VARCHAR(20) NOT NULL,
    [MonthName] VARCHAR(20) NOT NULL,
    [QuarterName] VARCHAR(20) NOT NULL,
    [YearMonth_int] INT NOT NULL,
    [YearWeek_int] INT NOT NULL,
    [FirstDayOfMonth] DATE NULL,
    [LastDayOfMonth] DATE NULL,
    [IsLastDayOfMonth] BIT NOT NULL,
    [YearMonth_Str] NVARCHAR(8) NULL,
    [IsWeekday] BIT NOT NULL,
    CONSTRAINT [PK__calendar__3C52D19447A5E83A] PRIMARY KEY (Calendar_Key)
);
GO
