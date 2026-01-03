--------------------------------------------------------------------------------
-- STEP 05.01B - KPI Fact: Severity Mix by Severity Level (APR) - Enterprise Strict
-- File: 05_01B_Fact_KPI_SeverityMix_BySeverity.sql
--
-- WHAT:
--   Create a KPI fact view at Facility-Date-Severity grain with keys required
--   for a strict star schema in Power BI:
--     - Discharge_Date_Key (Dim_Date relationship)
--     - ClinicalClass_Key (Dim_ClinicalClass relationship)
--
-- WHY:
--   Enables consistent date slicing (Year/Month/Quarter) and consistent use of
--   clinical classification attributes across the semantic model.
--
-- GRAIN:
--   One row per:
--     Facility_Key × Discharge_Date_Key × ClinicalClass_Key
--   (with filters ensuring APR severity levels 1–4 only)
--
-- OUTPUT (to Power BI):
--   Facility_Key, Discharge_Date_Key, ClinicalClass_Key
--   Encounter_Year (derived from Dim_Date for convenience)
--   APR_Severity_Code, APR_Severity_Description
--   Encounter_Count (additive)
--   Encounter_Share (within Facility-Year, sums to 1.0000 per Facility-Year)
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
WITH Base AS (
    SELECT
        fe.Encounter_ID,                 -- keep encounter grain for accurate counting
        fe.Facility_Key,
        fe.Discharge_Date_Key,
        fe.ClinicalClass_Key,

        -- Bring the severity attributes for convenience (still keep the key)
        cc.APR_Severity_Code,
        cc.APR_Severity_Description,

        -- Convenience attribute: year derived from the discharge date key
        d.Year AS Encounter_Year
    FROM dbo.Fact_Encounter AS fe
    INNER JOIN dbo.Dim_ClinicalClass AS cc
        ON fe.ClinicalClass_Key = cc.ClinicalClass_Key
    INNER JOIN dbo.Dim_Date AS d
        ON fe.Discharge_Date_Key = d.Date_Key
    WHERE
        -- Keep only valid APR Severity buckets for the official distribution
        cc.APR_Severity_Code IN (1,2,3,4)
),
Agg AS (
    SELECT
        b.Facility_Key,
        b.Discharge_Date_Key,
        b.ClinicalClass_Key,
        b.Encounter_Year,
        b.APR_Severity_Code,
        b.APR_Severity_Description,

        -- OUTPUT METRIC: Encounter count at the strict grain
        COUNT_BIG(*) AS Encounter_Count
    FROM Base AS b
    GROUP BY
        b.Facility_Key,
        b.Discharge_Date_Key,
        b.ClinicalClass_Key,
        b.Encounter_Year,
        b.APR_Severity_Code,
        b.APR_Severity_Description
),
Agg_FacilityYear AS (
    -- Denominator needed to compute shares per Facility-Year
    SELECT
        a.Facility_Key,
        a.Encounter_Year,
        SUM(a.Encounter_Count) AS FacilityYear_Encounter_Total
    FROM Agg AS a
    GROUP BY
        a.Facility_Key,
        a.Encounter_Year
)
SELECT
    f.Facility_Key,
    f.Facility_Name,

    -- Keys for strict star schema relationships
    a.Discharge_Date_Key,
    a.ClinicalClass_Key,

    -- Convenience time attribute (optional but helpful)
    a.Encounter_Year,

    -- Severity attributes (also available via Dim_ClinicalClass)
    a.APR_Severity_Code,
    a.APR_Severity_Description,

    -- Additive fact
    a.Encounter_Count,

    -- KPI share within Facility-Year (sums to 1.0000 per Facility-Year)
    CAST(
        a.Encounter_Count * 1.0
        / NULLIF(afy.FacilityYear_Encounter_Total, 0)
        AS DECIMAL(10,4)
    ) AS Encounter_Share
FROM Agg AS a
INNER JOIN Agg_FacilityYear AS afy
    ON a.Facility_Key = afy.Facility_Key
   AND a.Encounter_Year = afy.Encounter_Year
INNER JOIN dbo.Dim_Facility AS f
    ON a.Facility_Key = f.Facility_Key;
GO



-- Check with top 5. rows
SELECT TOP (50)
    Facility_Name,
    Encounter_Year,
    Discharge_Date_Key,
    ClinicalClass_Key,
    APR_Severity_Code,
    APR_Severity_Description,
    Encounter_Count,
    Encounter_Share
FROM dbo.vw_Fact_KPI_SeverityMix_BySeverity
ORDER BY Facility_Name, Encounter_Year, Discharge_Date_Key, APR_Severity_Code;


-- check: uniqueness at the strict grain
-- Expected: 0 rows
SELECT
    Facility_Key,
    Discharge_Date_Key,
    ClinicalClass_Key,
    COUNT(*) AS Row_Count
FROM dbo.vw_Fact_KPI_SeverityMix_BySeverity
GROUP BY
    Facility_Key,
    Discharge_Date_Key,
    ClinicalClass_Key
HAVING COUNT(*) > 1
ORDER BY Row_Count DESC;


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

-- check: shares must sum to 1 per Facility-Day
-- Expected result: 0 rows
SELECT
    f.Facility_Name,
    fe.Discharge_Date_Key,
    d.Year AS Encounter_Year,

    COUNT_BIG(*) AS Fact_Encounter_Count,
    ISNULL(v.View_Encounter_Count, 0) AS View_Encounter_Count,
    COUNT_BIG(*) - ISNULL(v.View_Encounter_Count, 0) AS Encounter_Difference
FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Facility AS f
    ON fe.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS d
    ON fe.Discharge_Date_Key = d.Date_Key
LEFT JOIN (
    SELECT
        Facility_Key,
        Discharge_Date_Key,
        SUM(Encounter_Count) AS View_Encounter_Count
    FROM dbo.vw_Fact_KPI_SeverityMix_BySeverity
GROUP BY
        Facility_Key,
        Discharge_Date_Key
) AS v
    ON v.Facility_Key = fe.Facility_Key
   AND v.Discharge_Date_Key = fe.Discharge_Date_Key
WHERE
    d.Year = 2015
GROUP BY
    f.Facility_Name,
    fe.Discharge_Date_Key,
    d.Year,
    v.View_Encounter_Count
HAVING COUNT_BIG(*) - ISNULL(v.View_Encounter_Count, 0) <> 0
ORDER BY
    f.Facility_Name,
    fe.Discharge_Date_Key;

