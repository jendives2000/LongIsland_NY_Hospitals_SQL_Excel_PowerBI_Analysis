--------------------------------------------------------------------------------
-- STEP 05.06 - KPI: Mortality Rate (In-Hospital)
-- File: 05_06_Mortality_Rate.sql
--
-- WHAT:
--   Measure in-hospital mortality using standardized discharge disposition.
--   Provide:
--     (1) Encounter-level export for Excel validation
--     (2) Facility-Year mortality counts and rate (primary KPI output)
--     (3) Facility-Month mortality counts and rate (within-year trend)
--
-- WHY:
--   Mortality is a high-signal outcome indicator. In this model it is identified
--   through standardized discharge disposition groupings (e.g., 'Expired').
--
-- DEPENDENCIES:
--   Fact: dbo.Fact_Encounter (Encounter_ID, Facility_Key, Discharge_Date_Key, Disposition_Key)
--   Dims: dbo.Dim_Facility (Facility_Key, Facility_Name)
--         dbo.Dim_Date (Date_Key, Year, Month_Number, Month_Name)
--         dbo.Dim_Disposition (Disposition_Key, Disposition_Grouped)
--------------------------------------------------------------------------------

SET NOCOUNT ON;

--------------------------------------------------------------------------------
-- STEP 05.06.00 - Build encounter-grain mortality base (temp table)
--------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#Encounter_Mortality') IS NOT NULL
BEGIN
    DROP TABLE #Encounter_Mortality;
END;

SELECT
    fe.Encounter_ID,
    fe.Facility_Key,
    df.Facility_Name,

    dd.[Year]        AS Discharge_Year,
    dd.Month_Number  AS Discharge_Month_Number,
    dd.Month_Name    AS Discharge_Month_Name,

    -- Standardized disposition category (executive-safe)
    ISNULL(ddisp.Disposition_Grouped, 'Unknown') AS Standardized_Disposition_Category,

    -- Mortality flag (in-hospital)
    -- Adjust the label list if your Disposition_Grouped uses different wording.
    CASE
        WHEN ddisp.Disposition_Grouped = 'Death' THEN 1
        ELSE 0
    END AS Mortality_Flag

INTO #Encounter_Mortality
FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Facility AS df
    ON fe.Facility_Key = df.Facility_Key
INNER JOIN dbo.Dim_Date AS dd
    ON fe.Discharge_Date_Key = dd.Date_Key
LEFT JOIN dbo.Dim_Disposition AS ddisp
    ON fe.Disposition_Key = ddisp.Disposition_Key;

--------------------------------------------------------------------------------
-- STEP 05.06.01 - OUTPUT (Granular): Encounter-level export for Excel validation
--
-- Pivot suggestion:
--   Rows   : Facility_Name
--   Values : Count of Encounter_ID (Total), Sum of Mortality_Flag (Deaths)
--   Calc   : Deaths / Total = Mortality Rate
--------------------------------------------------------------------------------
SELECT
    Encounter_ID,
    Facility_Name,
    Discharge_Year,
    Discharge_Month_Number,
    Discharge_Month_Name,
    Standardized_Disposition_Category,
    Mortality_Flag
FROM #Encounter_Mortality
ORDER BY
    Facility_Name,
    Discharge_Year,
    Discharge_Month_Number,
    Encounter_ID;
GO

--------------------------------------------------------------------------------
-- STEP 05.06.02 - KPI OUTPUT (Primary): Facility-Year Mortality Counts & Rate
--------------------------------------------------------------------------------
SELECT
    Facility_Key,
    Facility_Name,
    Discharge_Year,

    COUNT(*) AS Total_Encounter_Count,
    SUM(Mortality_Flag) AS Mortality_Encounter_Count,

    CAST(
        SUM(Mortality_Flag) * 1.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    ) AS Mortality_Rate
FROM #Encounter_Mortality
GROUP BY
    Facility_Key,
    Facility_Name,
    Discharge_Year
ORDER BY
    Facility_Name,
    Discharge_Year;
GO

--------------------------------------------------------------------------------
-- STEP 05.06.03 - KPI OUTPUT (Within-year trend): Facility-Month Mortality
--------------------------------------------------------------------------------
SELECT
    Facility_Key,
    Facility_Name,
    Discharge_Year,
    Discharge_Month_Number,
    Discharge_Month_Name,

    COUNT(*) AS Total_Encounter_Count,
    SUM(Mortality_Flag) AS Mortality_Encounter_Count,

    CAST(
        SUM(Mortality_Flag) * 1.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    ) AS Mortality_Rate
FROM #Encounter_Mortality
GROUP BY
    Facility_Key,
    Facility_Name,
    Discharge_Year,
    Discharge_Month_Number,
    Discharge_Month_Name
ORDER BY
    Facility_Name,
    Discharge_Year,
    Discharge_Month_Number;
GO

--------------------------------------------------------------------------------
-- STEP 05.06.04 - OPTIONAL: Domain transparency (disposition labels vs mortality)
--------------------------------------------------------------------------------
SELECT
    Standardized_Disposition_Category,
    COUNT(*) AS Encounter_Count,
    SUM(Mortality_Flag) AS Mortality_Count
FROM #Encounter_Mortality
GROUP BY Standardized_Disposition_Category
ORDER BY Encounter_Count DESC;
GO
