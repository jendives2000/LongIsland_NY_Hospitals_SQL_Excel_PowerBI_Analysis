--------------------------------------------------------------------------------
-- STEP 05.01B - KPI Fact: Severity Mix by Severity Level (APR)
-- File: 05_01B_Fact_KPI_SeverityMix_BySeverity.sql
--
-- WHAT:
--   Create a KPI fact view at Facility-Year-Severity grain:
--     - Encounter_Count per APR severity level (1–4)
--     - Optional Encounter_Share (within Facility-Year)
--
-- WHY:
--   Power BI visuals (100% stacked distributions) require a fact grain that
--   can be segmented by severity without importing encounter-level rows.
--   This keeps the semantic model fast, stable, and audit-friendly.
--
-- GRAIN:
--   One row per:
--     Facility_Key × Encounter_Year × APR_Severity_Code
--
-- OUTPUT (to Power BI):
--   Facility_Key, Facility_Name
--   Encounter_Year
--   APR_Severity_Code, APR_Severity_Description
--   Encounter_Count
--   Encounter_Share (sums to 1.0000 per Facility-Year)
--
-- DEPENDENCIES:
--   dbo.Fact_Encounter: Encounter_ID, Discharge_Date_Key, Facility_Key, ClinicalClass_Key
--   dbo.Dim_Date: Date_Key, Year
--   dbo.Dim_Facility: Facility_Key, Facility_Name
--   dbo.Dim_ClinicalClass: ClinicalClass_Key, APR_Severity_Code, APR_Severity_Description
--------------------------------------------------------------------------------

IF OBJECT_ID('dbo.vw_Fact_KPI_SeverityMix_BySeverity', 'V') IS NOT NULL
BEGIN
    DROP VIEW dbo.vw_Fact_KPI_SeverityMix_BySeverity;
END;
GO

CREATE VIEW dbo.vw_Fact_KPI_SeverityMix_BySeverity
AS
WITH Severity_Base AS (
    SELECT
        fe.Encounter_ID,                  -- WHAT: Keep encounter grain for accurate counting
        fe.Facility_Key,
        fe.Discharge_Date_Key,
        fe.ClinicalClass_Key,

        -- WHAT: Severity code (1–4) used for distribution visuals.
        -- WHY: Power BI needs a categorical field to segment encounter counts.
        cc.APR_Severity_Code,

        -- WHAT: Friendly label (Minor/Moderate/Major/Extreme).
        -- WHY: Executive readability in legends and tooltips.
        cc.APR_Severity_Description
    FROM dbo.Fact_Encounter AS fe
    INNER JOIN dbo.Dim_ClinicalClass AS cc
        ON fe.ClinicalClass_Key = cc.ClinicalClass_Key
    WHERE
        -- WHAT: Keep only valid APR Severity buckets for the official distribution.
        -- WHY: Prevents NULL/Unknown from producing misleading stacked shares.
        cc.APR_Severity_Code IN (1,2,3,4)
),
Agg AS (
    SELECT
        sb.Facility_Key,
        d.Year AS Encounter_Year,
        sb.APR_Severity_Code,
        sb.APR_Severity_Description,

        -- KPI OUTPUT METRIC: Count of encounters in this severity level.
        COUNT_BIG(*) AS Encounter_Count
    FROM Severity_Base AS sb
    INNER JOIN dbo.Dim_Date AS d
        ON sb.Discharge_Date_Key = d.Date_Key
    GROUP BY
        sb.Facility_Key,
        d.Year,
        sb.APR_Severity_Code,
        sb.APR_Severity_Description
)
SELECT
    f.Facility_Key,
    f.Facility_Name,
    a.Encounter_Year,
    a.APR_Severity_Code,
    a.APR_Severity_Description,

    -- OUTPUT METRIC: Encounter count (additive, safe for aggregation).
    a.Encounter_Count,

    -- OUTPUT KPI: Share within Facility-Year (drives 100% stacked visuals).
    CAST(
        a.Encounter_Count * 1.0
        / NULLIF(SUM(a.Encounter_Count) OVER (PARTITION BY a.Facility_Key, a.Encounter_Year), 0)
        AS DECIMAL(10,4)
    ) AS Encounter_Share
FROM Agg AS a
INNER JOIN dbo.Dim_Facility AS f
    ON a.Facility_Key = f.Facility_Key;
GO


-- Check with top 5. rows
SELECT TOP (50)
    Facility_Name,
    Encounter_Year,
    APR_Severity_Code,
    APR_Severity_Description,
    Encounter_Count,
    Encounter_Share
FROM dbo.vw_Fact_KPI_SeverityMix_BySeverity
ORDER BY Facility_Name, Encounter_Year, APR_Severity_Code;


-- Pivot Output: one row per facility with columns Minor/Moderate/Major/Extreme.
SELECT
    Facility_Name,
    Encounter_Year,
    ISNULL([Minor], 0)    AS Minor_Encounters,
    ISNULL([Moderate], 0) AS Moderate_Encounters,
    ISNULL([Major], 0)    AS Major_Encounters,
    ISNULL([Extreme], 0)  AS Extreme_Encounters
FROM (
    SELECT
        Facility_Name,
        Encounter_Year,
        APR_Severity_Description,
        CAST(Encounter_Count AS BIGINT) AS Encounter_Count
    FROM dbo.vw_Fact_KPI_SeverityMix_BySeverity
) src
PIVOT (
    SUM(Encounter_Count)
    FOR APR_Severity_Description IN ([Minor],[Moderate],[Major],[Extreme])
) p
ORDER BY Facility_Name, Encounter_Year;

-- same as above, but with shares: 
SELECT
    Facility_Name,
    Encounter_Year,
    ISNULL([Minor], 0.0)    AS Minor_Share,
    ISNULL([Moderate], 0.0) AS Moderate_Share,
    ISNULL([Major], 0.0)    AS Major_Share,
    ISNULL([Extreme], 0.0)  AS Extreme_Share
FROM (
    SELECT
        Facility_Name,
        Encounter_Year,
        APR_Severity_Description,
        CAST(Encounter_Share AS DECIMAL(10,4)) AS Encounter_Share
    FROM dbo.vw_Fact_KPI_SeverityMix_BySeverity
) src
PIVOT (
    SUM(Encounter_Share)
    FOR APR_Severity_Description IN ([Minor],[Moderate],[Major],[Extreme])
) p
ORDER BY Facility_Name, Encounter_Year;

-- check: shares must sum to 1 per Facility-Year
-- Expected result: 0 rows
SELECT
    Facility_Name,
    Encounter_Year,
    SUM(Encounter_Count) AS Total_Encounters_From_View,
    CAST(SUM(Encounter_Share) AS DECIMAL(10,4)) AS Share_Sum_Should_Be_1
FROM dbo.vw_Fact_KPI_SeverityMix_BySeverity
GROUP BY Facility_Name, Encounter_Year
HAVING ABS(SUM(Encounter_Share) - 1.0) > 0.0001
ORDER BY Facility_Name, Encounter_Year;


-- Cross-check against Fact_Encounter totals (2015)
SELECT
    f.Facility_Name,
    d.Year AS Encounter_Year,

    -- Total encounters from raw fact table
    COUNT_BIG(*) AS Total_Inpatient_Encounters_Fact,

    -- Total encounters reconstructed from the KPI severity view
    ISNULL(v.Total_Encounters_From_View, 0) AS Total_Encounters_From_View,

    -- Difference: should be 0 if nothing is lost
    COUNT_BIG(*) - ISNULL(v.Total_Encounters_From_View, 0) AS Encounter_Difference

FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Facility AS f
    ON fe.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS d
    ON fe.Discharge_Date_Key = d.Date_Key
LEFT JOIN (
    SELECT
        Facility_Key,
        Encounter_Year,
        SUM(Encounter_Count) AS Total_Encounters_From_View
    FROM dbo.vw_Fact_KPI_SeverityMix_BySeverity
    GROUP BY
        Facility_Key,
        Encounter_Year
) AS v
    ON v.Facility_Key = fe.Facility_Key
   AND v.Encounter_Year = d.Year
WHERE
    d.Year = 2015
GROUP BY
    f.Facility_Name,
    d.Year,
    v.Total_Encounters_From_View
ORDER BY
    f.Facility_Name;

