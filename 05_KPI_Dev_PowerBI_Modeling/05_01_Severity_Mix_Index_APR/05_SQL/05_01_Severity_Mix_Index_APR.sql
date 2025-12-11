--------------------------------------------------------------------------------
-- STEP 05.01 - KPI: Severity Mix Index (APR)
-- View: dbo.vw_KPI_SeverityMix_FacilityYear
--
-- WHAT:
--   One row per Facility + Calendar Year summarizing how many encounters fall
--   into each APR Severity of Illness level (1–4), plus an average severity score.
--
-- WHY:
--   This provides the baseline "how sick are our patients?" context, which is
--   essential for interpreting LOS, mortality, cost, and other KPIs fairly.
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.vw_KPI_SeverityMix_FacilityYear', 'V') IS NOT NULL
BEGIN
    DROP VIEW dbo.vw_KPI_SeverityMix_FacilityYear;
END;
GO

CREATE VIEW dbo.vw_KPI_SeverityMix_FacilityYear
AS
WITH Severity_Clean AS (
    SELECT
        fe.Encounter_ID,                        -- keep encounter grain for counting
        fe.Facility_Key,
        fe.Admission_Date_Key,                  -- anchor for Encounter_Year
        cc.APR_Severity_Code,
        TRY_CAST(cc.APR_Severity_Code AS INT) AS Severity_Int
    FROM dbo.Fact_Encounter      AS fe
    INNER JOIN dbo.Dim_ClinicalClass AS cc
        ON fe.ClinicalClass_Key = cc.ClinicalClass_Key
    WHERE cc.APR_Severity_Code IS NOT NULL
          -- WHAT: Exclude encounters where severity is missing in the clinical class.
          -- WHY: These cannot be classified into the 1–4 scale and would distort the mix.
)
SELECT
    f.Facility_Key,
    f.Facility_Name,
    d.Year                                  AS Encounter_Year,

    COUNT(*)                               AS Encounter_Count_Total,

    -- WHAT: Count encounters for each severity level 1–4.
    -- WHY: Gives a clear distribution of case-mix for each facility-year.
    SUM(CASE WHEN sc.Severity_Int = 1 THEN 1 ELSE 0 END) AS Severity1_Encounter_Count,
    SUM(CASE WHEN sc.Severity_Int = 2 THEN 1 ELSE 0 END) AS Severity2_Encounter_Count,
    SUM(CASE WHEN sc.Severity_Int = 3 THEN 1 ELSE 0 END) AS Severity3_Encounter_Count,
    SUM(CASE WHEN sc.Severity_Int = 4 THEN 1 ELSE 0 END) AS Severity4_Encounter_Count,

    -- WHAT: Average severity score for the facility-year.
    -- WHY: A single index that summarizes how severe the typical case is.
    AVG(CAST(sc.Severity_Int AS DECIMAL(10,2))) AS Avg_Severity_Score

FROM Severity_Clean AS sc
INNER JOIN dbo.Dim_Facility AS f
    ON sc.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS d
    ON sc.Admission_Date_Key = d.Date_Key     -- use admission date to define year
GROUP BY
    f.Facility_Key,
    f.Facility_Name,
    d.Year;
GO


--------------------------------------------------------------------------------
-- SANITY CHECK 1: Severity range in the clinical class dimension
-- WHAT:
--   Confirm that APR_Severity_Code in Dim_ClinicalClass is between
--   1 and 4 once cast to INT, and check how many NULLs we have.
--
-- WHY:
--   Ensures the APR severity field is populated and within expected bounds.
--------------------------------------------------------------------------------
SELECT
    MIN(TRY_CAST(APR_Severity_Code AS INT)) AS Min_Severity_Int,
    MAX(TRY_CAST(APR_Severity_Code AS INT)) AS Max_Severity_Int,
    SUM(CASE WHEN APR_Severity_Code IS NULL THEN 1 ELSE 0 END) AS Null_Severity_Count,
    COUNT(*) AS Total_ClinicalClass_Rows
FROM dbo.Dim_ClinicalClass;



--------------------------------------------------------------------------------
-- SANITY CHECK 2: Compare total encounters in the view vs. fact table per year.
-- WHAT:
--   Aggregate the view by year and compare encounter counts with a direct join
--   between Fact_Encounter and Dim_ClinicalClass (only for rows that have
--   a non-null severity code).
--
-- WHY:
--   Ensures that the view did not accidentally drop/duplicate encounters.
--------------------------------------------------------------------------------

-- a) Counts from the KPI view
SELECT
    Encounter_Year,
    SUM(Encounter_Count_Total) AS View_Encounter_Count
FROM dbo.vw_KPI_SeverityMix_FacilityYear
GROUP BY Encounter_Year
ORDER BY Encounter_Year;


-- b) Counts directly from the fact table + clinical class (same filter as view)
SELECT
    d.Year          AS Encounter_Year,
    COUNT(*)        AS Fact_Encounter_Count
FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_ClinicalClass AS cc
    ON fe.ClinicalClass_Key = cc.ClinicalClass_Key
INNER JOIN dbo.Dim_Date AS d
    ON fe.Admission_Date_Key = d.Date_Key
WHERE cc.APR_Severity_Code IS NOT NULL
GROUP BY d.Year
ORDER BY d.Year;




-- Subset for validation In Excel (one hospital: Peconic Bay Medical Center, year 2015:
SELECT
    f.Facility_Name,
    d.Year AS Encounter_Year,
    cc.APR_Severity_Code
FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Facility AS f 
    ON fe.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS d 
    ON fe.Admission_Date_Key = d.Date_Key
INNER JOIN dbo.Dim_ClinicalClass AS cc
    ON fe.ClinicalClass_Key = cc.ClinicalClass_Key
WHERE
    d.Year = 2015
    AND f.Facility_Name = 'Peconic Bay Medical Center';


-- View to compare with this subset
SELECT
    Facility_Name,
    Encounter_Year,
    Severity1_Encounter_Count,
    Severity2_Encounter_Count,
    Severity3_Encounter_Count,
    Severity4_Encounter_Count,
    Avg_Severity_Score
FROM dbo.vw_KPI_SeverityMix_FacilityYear
WHERE Facility_Name = 'Peconic Bay Medical Center';

