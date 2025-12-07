/*
    STEP 03.6b – Dim_Date (2015 only) + Synthetic Admission/Discharge Dates

    Context:
    - Source table: dbo.LI_SPARCS_2015_25_Inpatient
    - Original time field: [Discharge Year] (year only, 2015 in this extract)
    - Goal:
        1) Generate realistic synthetic Discharge and Admission dates.
        2) Build a daily Dim_Date for 2015 only.
        3) Link fact rows to Dim_Date via surrogate keys.

    IMPORTANT:
    - Synthetic fields are clearly named:
        * Discharge_Date_Sim
        * Admission_Date_Sim
        * LOS_Sim
    - They are used for calendar and LOS analysis in the portfolio,
      not as real clinical timestamps.
*/

------------------------------------------------------------
-- 1) Add synthetic date and LOS columns if they do not exist
------------------------------------------------------------
IF COL_LENGTH('dbo.LI_SPARCS_2015_25_Inpatient', 'Discharge_Date_Sim') IS NULL
BEGIN
    ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD Discharge_Date_Sim DATE NULL;
END;

IF COL_LENGTH('dbo.LI_SPARCS_2015_25_Inpatient', 'Admission_Date_Sim') IS NULL
BEGIN
    ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD Admission_Date_Sim DATE NULL;
END;

IF COL_LENGTH('dbo.LI_SPARCS_2015_25_Inpatient', 'LOS_Sim') IS NULL
BEGIN
    ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD LOS_Sim INT NULL;
END;
GO

------------------------------------------------------------
-- 2) Generate a random Discharge_Date_Sim within the Discharge Year
--    (for this dataset, Discharge Year is 2015)
------------------------------------------------------------
UPDATE f
SET Discharge_Date_Sim =
    DATEADD(
        DAY,
        ABS(CHECKSUM(NEWID())) %
            CASE 
                -- Leap-year-aware day count
                WHEN (TRY_CONVERT(INT, f.[Discharge_Year]) % 400 = 0)
                  OR (TRY_CONVERT(INT, f.[Discharge_Year]) % 4 = 0 
                      AND TRY_CONVERT(INT, f.[Discharge_Year]) % 100 <> 0)
                THEN 366
                ELSE 365
            END,
        DATEFROMPARTS(TRY_CONVERT(INT, f.[Discharge_Year]), 1, 1)
    )
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f;
GO

------------------------------------------------------------
-- 3) Generate LOS_Sim with a skew toward short stays
--    Distribution (approx):
--      - 0–2 days: 60%
--      - 3–7 days: 30%
--      - 8–21 days: 9%
--      - 22–60 days: 1%
------------------------------------------------------------
UPDATE f
SET LOS_Sim = v.LOS_Sim
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
CROSS APPLY (
    SELECT ABS(CHECKSUM(NEWID())) AS baseRand
) r
CROSS APPLY (
    SELECT 
        CASE 
            WHEN (r.baseRand % 100) < 60 
                THEN r.baseRand % 3                      -- 0 to 2
            WHEN (r.baseRand % 100) < 90 
                THEN 3 + (r.baseRand % 5)                -- 3 to 7
            WHEN (r.baseRand % 100) < 99 
                THEN 8 + (r.baseRand % 14)               -- 8 to 21
            ELSE 22 + (r.baseRand % 39)                  -- 22 to 60
        END AS LOS_Sim
) v;
GO

------------------------------------------------------------
-- 4) Compute Admission_Date_Sim = Discharge_Date_Sim - LOS_Sim
--    Clamp extremely early admissions to project start (2015-01-01)
------------------------------------------------------------
UPDATE dbo.LI_SPARCS_2015_25_Inpatient
SET Admission_Date_Sim = DATEADD(DAY, -LOS_Sim, Discharge_Date_Sim);
GO

UPDATE dbo.LI_SPARCS_2015_25_Inpatient
SET Admission_Date_Sim = '2015-01-01'
WHERE Admission_Date_Sim < '2015-01-01';
GO

------------------------------------------------------------
-- 5) Create Dim_Date for 2015 only (daily grain, Monday-first)
------------------------------------------------------------
IF OBJECT_ID('dbo.Dim_Date', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Dim_Date;
END;
GO

CREATE TABLE dbo.Dim_Date
(
    Date_Key            INT          NOT NULL,   -- e.g. 20150131
    Full_Date           DATE         NOT NULL,

    [Year]              INT          NOT NULL,
    Quarter             TINYINT      NOT NULL,
    Month_Number        TINYINT      NOT NULL,
    Month_Name          NVARCHAR(20) NOT NULL,
    Day_Of_Month        TINYINT      NOT NULL,

    -- Monday-first weekday numbering
    Day_Of_Week_Number  TINYINT      NOT NULL,   -- Monday = 1 ... Sunday = 7
    Day_Of_Week_Name    NVARCHAR(20) NOT NULL,

    Is_Weekend          BIT          NOT NULL,

    CONSTRAINT PK_Dim_Date PRIMARY KEY CLUSTERED (Date_Key)
);
GO

SET DATEFIRST 1; -- Monday = 1

DECLARE @MinDate DATE = '2015-01-01';
DECLARE @MaxDate DATE = '2015-12-31';

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
    Is_Weekend
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
    CASE WHEN DATENAME(WEEKDAY, TheDate) IN ('Saturday','Sunday') THEN 1 ELSE 0 END AS Is_Weekend
FROM DateSeries
OPTION (MAXRECURSION 400);
GO

------------------------------------------------------------
-- 6) Add date keys for synthetic dates on the fact table
------------------------------------------------------------
IF COL_LENGTH('dbo.LI_SPARCS_2015_25_Inpatient', 'Admission_Date_Key') IS NULL
BEGIN
    ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD Admission_Date_Key INT NULL;
END;

IF COL_LENGTH('dbo.LI_SPARCS_2015_25_Inpatient', 'Discharge_Date_Key') IS NULL
BEGIN
    ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD Discharge_Date_Key INT NULL;
END;
GO

------------------------------------------------------------
-- 7) Populate date keys using synthetic dates and Dim_Date
------------------------------------------------------------
UPDATE f
SET f.Admission_Date_Key = d.Date_Key
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
INNER JOIN dbo.Dim_Date AS d
    ON f.Admission_Date_Sim = d.Full_Date;

UPDATE f
SET f.Discharge_Date_Key = d.Date_Key
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
INNER JOIN dbo.Dim_Date AS d
    ON f.Discharge_Date_Sim = d.Full_Date;
GO

------------------------------------------------------------
-- 8) Sanity checks
------------------------------------------------------------

-- 8a) LOS bucket distribution
SELECT 
    CASE 
        WHEN LOS_Sim BETWEEN 0 AND 2  THEN '0-2 days'
        WHEN LOS_Sim BETWEEN 3 AND 7  THEN '3-7 days'
        WHEN LOS_Sim BETWEEN 8 AND 21 THEN '8-21 days'
        WHEN LOS_Sim BETWEEN 22 AND 60 THEN '22-60 days'
        ELSE '61+ days'
    END AS LOS_Bucket,
    COUNT(*) AS Encounter_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient
GROUP BY 
    CASE 
        WHEN LOS_Sim BETWEEN 0 AND 2  THEN '0-2 days'
        WHEN LOS_Sim BETWEEN 3 AND 7  THEN '3-7 days'
        WHEN LOS_Sim BETWEEN 8 AND 21 THEN '8-21 days'
        WHEN LOS_Sim BETWEEN 22 AND 60 THEN '22-60 days'
        ELSE '61+ days'
    END
ORDER BY Encounter_Count DESC;
GO

-- 8b) Synthetic date ranges
SELECT 
    MIN(Admission_Date_Sim) AS Min_Admission_Date_Sim,
    MAX(Admission_Date_Sim) AS Max_Admission_Date_Sim,
    MIN(Discharge_Date_Sim) AS Min_Discharge_Date_Sim,
    MAX(Discharge_Date_Sim) AS Max_Discharge_Date_Sim
FROM dbo.LI_SPARCS_2015_25_Inpatient;
GO

-- 8c) How many rows are missing date keys?
SELECT
    COUNT(*) AS Total_Rows,
    SUM(CASE WHEN Admission_Date_Key IS NULL THEN 1 ELSE 0 END) AS Rows_Without_Admission_Date_Key,
    SUM(CASE WHEN Discharge_Date_Key IS NULL THEN 1 ELSE 0 END) AS Rows_Without_Discharge_Date_Key
FROM dbo.LI_SPARCS_2015_25_Inpatient;
GO

-- 8d) Quick distribution of encounters by Year (via Dim_Date)
SELECT
    d.[Year],
    COUNT(*) AS Encounter_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
INNER JOIN dbo.Dim_Date AS d
    ON f.Discharge_Date_Key = d.Date_Key
GROUP BY d.[Year]
ORDER BY d.[Year];
GO

-- 8e) Quick distribution of encounters by Month for 2015 (via Dim_Date)
SELECT
    d.[Year],
    d.Month_Number,
    d.Month_Name,
    COUNT(*) AS Encounter_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
INNER JOIN dbo.Dim_Date AS d
    ON f.Discharge_Date_Key = d.Date_Key   -- or Admission_Date_Key if you prefer
WHERE d.[Year] = 2015
GROUP BY
    d.[Year],
    d.Month_Number,
    d.Month_Name
ORDER BY
    d.[Year],
    d.Month_Number;
GO

-- 8f) Admissions vs Discharges by Month (to ensure both keys populated correctly)
SELECT
    d.Month_Number,
    d.Month_Name,
    COUNT(*) AS Admissions
FROM dbo.LI_SPARCS_2015_25_Inpatient f
JOIN dbo.Dim_Date d ON f.Admission_Date_Key = d.Date_Key
GROUP BY d.Month_Number, d.Month_Name
ORDER BY d.Month_Number;
GO

-- 8g) Weekend vs Weekday discharges
SELECT
    d.Day_Of_Week_Name,
    COUNT(*) AS Encounter_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient f
JOIN dbo.Dim_Date d ON f.Discharge_Date_Key = d.Date_Key
GROUP BY d.Day_Of_Week_Name
ORDER BY MIN(d.Day_Of_Week_Number);
GO
