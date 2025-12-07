/*
    STEP 03.6 – Build Dim_Date (2015–2025) and link it to Discharge_Year

    Assumptions:
        - Fact table: dbo.LI_SPARCS_2015_25_Inpatient
        - Year-only column: [Discharge_Year]
          (if your actual name is Discharge_Year, rename in the script).

    Design:
        - Dim_Date has daily grain (one row per calendar date).
        - Monday is treated as the first day of the week.
        - We introduce Is_Year_Anchor = 1 on a single canonical date
          per year (here: 1st January).
        - Fact rows link via Discharge_Year_Key to that anchor date.
*/

------------------------------------------------------------
-- 1) Drop and recreate Dim_Date
------------------------------------------------------------
IF OBJECT_ID('dbo.Dim_Date', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Dim_Date;
END;
GO

CREATE TABLE dbo.Dim_Date
(
    Date_Key            INT         NOT NULL,   -- e.g. 20150101
    Full_Date           DATE        NOT NULL,

    [Year]              INT         NOT NULL,
    Quarter             TINYINT     NOT NULL,
    Month_Number        TINYINT     NOT NULL,
    Month_Name          NVARCHAR(20) NOT NULL,
    Day_Of_Month        TINYINT     NOT NULL,

    -- Monday-first weekday numbering
    Day_Of_Week_Number  TINYINT     NOT NULL,   -- Monday = 1 ... Sunday = 7
    Day_Of_Week_Name    NVARCHAR(20) NOT NULL,

    Is_Weekend          BIT         NOT NULL,
    Is_Year_Anchor      BIT         NOT NULL    -- 1 row per year (here: Jan 1st)

    CONSTRAINT PK_Dim_Date PRIMARY KEY CLUSTERED (Date_Key)
);
GO

------------------------------------------------------------
-- 2) Generate the calendar from 2015-01-01 to 2025-12-31
--    Monday as first day of week
------------------------------------------------------------
SET DATEFIRST 1; -- Monday = 1

DECLARE @MinDate DATE = '2015-01-01';
DECLARE @MaxDate DATE = '2025-12-31';

;WITH DateSeries AS
(
    SELECT @MinDate AS TheDate
    UNION ALL
    SELECT DATEADD(DAY, 1, TheDate)
    FROM DateSeries
    WHERE TheDate < @MaxDate
)
INSERT INTO dbo.Dim_Date
(
    Date_Key,
    Full_Date,
    [Year],
    Quarter,
    Month_Number,
    Month_Name,
    Day_Of_Month,
    Day_Of_Week_Number,
    Day_Of_Week_Name,
    Is_Weekend,
    Is_Year_Anchor
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), TheDate, 112)) AS Date_Key,
    TheDate                                      AS Full_Date,
    DATEPART(YEAR, TheDate)                      AS [Year],
    DATEPART(QUARTER, TheDate)                   AS Quarter,
    DATEPART(MONTH, TheDate)                     AS Month_Number,
    DATENAME(MONTH, TheDate)                     AS Month_Name,
    DATEPART(DAY, TheDate)                       AS Day_Of_Month,
    DATEPART(WEEKDAY, TheDate)                   AS Day_Of_Week_Number, -- Monday=1..Sunday=7
    DATENAME(WEEKDAY, TheDate)                   AS Day_Of_Week_Name,
    CASE WHEN DATENAME(WEEKDAY, TheDate) IN ('Saturday','Sunday') THEN 1 ELSE 0 END AS Is_Weekend,
    CASE
        -- choose 1st January as the canonical anchor for the year
        WHEN DATEPART(MONTH, TheDate) = 1 AND DATEPART(DAY, TheDate) = 1 THEN 1
        ELSE 0
    END AS Is_Year_Anchor
FROM DateSeries
OPTION (MAXRECURSION 32767);
GO

------------------------------------------------------------
-- 3) Add Discharge_Year_Key column to the fact table (if not present)
------------------------------------------------------------
IF COL_LENGTH('dbo.LI_SPARCS_2015_25_Inpatient', 'Discharge_Year_Key') IS NULL
BEGIN
    ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD Discharge_Year_Key INT NULL;
END;
GO

------------------------------------------------------------
-- 4) Populate Discharge_Year_Key using Dim_Date year anchors
--
--    Logic:
--    - Convert [Discharge_Year] to INT (handles text/char/number).
--    - Join to the Dim_Date row where:
--        * Dim_Date.[Year] = Discharge_Year
--        * Dim_Date.Is_Year_Anchor = 1   (i.e. Jan 1st of that year)
------------------------------------------------------------
UPDATE f
SET f.Discharge_Year_Key = d.Date_Key
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
INNER JOIN dbo.Dim_Date AS d
    ON d.[Year] = TRY_CONVERT(INT, f.[Discharge_Year])
   AND d.Is_Year_Anchor = 1;
GO

------------------------------------------------------------
-- 5) Sanity checks
------------------------------------------------------------

-- 5a) Check date range and row count in Dim_Date
SELECT
    MIN(Full_Date) AS Min_Full_Date,
    MAX(Full_Date) AS Max_Full_Date,
    COUNT(*)       AS Total_Dates,
    SUM(CASE WHEN Is_Year_Anchor = 1 THEN 1 ELSE 0 END) AS Year_Anchor_Count
FROM dbo.Dim_Date;
GO

-- 5b) How many fact rows are missing a Discharge_Year_Key?
SELECT
    COUNT(*) AS Total_Rows,
    SUM(CASE WHEN Discharge_Year_Key IS NULL THEN 1 ELSE 0 END) AS Rows_Without_Discharge_Year_Key
FROM dbo.LI_SPARCS_2015_25_Inpatient;
GO

-- 5c) Quick distribution of encounters by Year (via Dim_Date)
SELECT
    d.[Year],
    COUNT(*) AS Encounter_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
INNER JOIN dbo.Dim_Date AS d
    ON f.Discharge_Year_Key = d.Date_Key
GROUP BY d.[Year]
ORDER BY d.[Year];
GO

------------------------------------------------------------
-- 6) Optional: add foreign key once you're happy with the mapping
------------------------------------------------------------
/*
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ADD CONSTRAINT FK_LI_SPARCS_DischargeYear
    FOREIGN KEY (Discharge_Year_Key)
    REFERENCES dbo.Dim_Date (Date_Key);
GO
*/
