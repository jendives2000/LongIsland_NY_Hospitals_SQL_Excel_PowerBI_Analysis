--------------------------------------------------------------------------------
-- STEP 05.05 - KPI: Length of Stay (LOS)
-- File: 05_05_Length_of_Stay.sql
--
-- WHAT:
--   Produce executive and analytic Length of Stay (LOS) metrics that describe
--   how long inpatient encounters remain hospitalized.
--
--   Outputs include:
--     (1) Encounter-level LOS data (one row per stay) for Excel validation
--     (2) Facility-Year LOS summary statistics (Avg / Min / Max)
--     (3) LOS distribution by standardized duration buckets
--     (4) LOS stratified by APR Severity of Illness (1–4)
--
-- WHY:
--   Length of Stay is a foundational efficiency and resource utilization metric.
--   It reflects a combination of patient severity, care processes, and discharge
--   constraints. Tracking LOS alongside admissions and disposition outcomes
--   enables a complete view of patient flow through the system.
--
-- IMPORTANT MODELING NOTE:
--   LOS is sourced directly from dbo.Fact_Encounter.Length_of_Stay_Int.
--   This value is already standardized upstream and aligned with operational
--   and financial reporting. Recomputing LOS from dates would introduce
--   inconsistency and is intentionally avoided.
--
-- DEPENDENCIES (per project Inputs & Dependencies):
--   Fact:
--     - dbo.Fact_Encounter
--       * Encounter_ID
--       * Facility_Key
--       * Discharge_Date_Key
--       * ClinicalClass_Key
--       * Length_of_Stay_Int
--   Dimensions:
--     - dbo.Dim_Facility
--       * Facility_Key, Facility_Name
--     - dbo.Dim_Date
--       * Date_Key, Year
--     - dbo.Dim_ClinicalClass
--       * ClinicalClass_Key
--       * APR_Severity_Code
--       * APR_Severity_Description
--------------------------------------------------------------------------------

SET NOCOUNT ON;

--------------------------------------------------------------------------------
-- STEP 05.05.00 - Build encounter-grain LOS base table
--
-- WHAT:
--   Create a temporary encounter-level table with authoritative LOS,
--   discharge year, facility, and severity attributes.
--
-- WHY:
--   All downstream LOS KPIs (averages, distributions, severity views)
--   must reconcile exactly to encounter-level data for Excel validation
--   and auditability.
--------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#Encounter_LOS') IS NOT NULL
BEGIN
    DROP TABLE #Encounter_LOS;
END;

SELECT
    fe.Encounter_ID,
    fe.Facility_Key,
    f.Facility_Name,

    -- Anchor reporting period to discharge year
    dd.[Year] AS Discharge_Year,

    fe.ClinicalClass_Key,
    cc.APR_Severity_Code,
    cc.APR_Severity_Description,

    -- WHAT:
    --   Length of Stay in days for the encounter.
    --
    -- WHY:
    --   LOS is sourced directly from the fact table to ensure consistency
    --   with operational and financial reporting. This avoids off-by-one
    --   errors and reconciliation issues that arise when recomputing from dates.
    fe.Length_of_Stay_Int AS LOS_Days,

    -- WHAT:
    --   Executive-friendly LOS buckets for distribution analysis.
    --
    -- WHY:
    --   Bucketing highlights short-stay dominance and long-stay tail behavior
    --   without exposing unnecessary day-level noise to executive users.
    CASE
        WHEN fe.Length_of_Stay_Int < 0 THEN 'Invalid (<0)'
        WHEN fe.Length_of_Stay_Int = 0 THEN '0 days'
        WHEN fe.Length_of_Stay_Int = 1 THEN '1 day'
        WHEN fe.Length_of_Stay_Int = 2 THEN '2 days'
        WHEN fe.Length_of_Stay_Int BETWEEN 3 AND 4 THEN '3–4 days'
        WHEN fe.Length_of_Stay_Int BETWEEN 5 AND 7 THEN '5–7 days'
        WHEN fe.Length_of_Stay_Int BETWEEN 8 AND 14 THEN '8–14 days'
        WHEN fe.Length_of_Stay_Int BETWEEN 15 AND 30 THEN '15–30 days'
        ELSE '31+ days'
    END AS LOS_Bucket

INTO #Encounter_LOS
FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Facility AS f
    ON fe.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS dd
    ON fe.Discharge_Date_Key = dd.Date_Key
LEFT JOIN dbo.Dim_ClinicalClass AS cc
    ON fe.ClinicalClass_Key = cc.ClinicalClass_Key;

--------------------------------------------------------------------------------
-- STEP 05.05.01 - OUTPUT (Granular): Encounter-level export for Excel validation
--
-- WHAT:
--   Provide one row per encounter with LOS, bucket, and severity attributes.
--
-- WHY:
--   This output is the authoritative source for Excel PivotTables used to
--   validate all LOS KPI aggregates.
--------------------------------------------------------------------------------
SELECT
    Encounter_ID,
    Facility_Name,
    Discharge_Year,
    LOS_Days,
    LOS_Bucket,
    APR_Severity_Code,
    APR_Severity_Description
FROM #Encounter_LOS
ORDER BY
    Facility_Name,
    Discharge_Year,
    Encounter_ID;
GO

--------------------------------------------------------------------------------
-- STEP 05.05.02 - KPI: Facility-Year LOS summary statistics
--
-- WHAT:
--   Average, minimum, and maximum LOS per facility and discharge year.
--
-- WHY:
--   These metrics summarize overall efficiency while preserving visibility
--   into extreme short- and long-stay behavior.
--------------------------------------------------------------------------------
SELECT
    Facility_Key,
    Facility_Name,
    Discharge_Year,

    COUNT(*) AS Encounter_Count,

    CAST(AVG(CASE WHEN LOS_Days >= 0 THEN 1.0 * LOS_Days END) AS DECIMAL(10,2))
        AS Avg_LOS_Days,

    MIN(CASE WHEN LOS_Days >= 0 THEN LOS_Days END) AS Min_LOS_Days,
    MAX(CASE WHEN LOS_Days >= 0 THEN LOS_Days END) AS Max_LOS_Days

FROM #Encounter_LOS
GROUP BY
    Facility_Key,
    Facility_Name,
    Discharge_Year
ORDER BY
    Facility_Name,
    Discharge_Year;
GO

--------------------------------------------------------------------------------
-- STEP 05.05.03 - KPI: LOS distribution by Facility and Year
--
-- WHAT:
--   Count and share of encounters by LOS bucket.
--
-- WHY:
--   Distribution analysis reveals whether LOS changes are driven by
--   broad shifts in care patterns or by a long-stay tail.
--------------------------------------------------------------------------------
SELECT
    Facility_Key,
    Facility_Name,
    Discharge_Year,
    LOS_Bucket,

    COUNT(*) AS Bucket_Encounter_Count,

    CAST(
        COUNT(*) * 1.0
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY Facility_Key, Discharge_Year), 0)
        AS DECIMAL(10,4)
    ) AS Bucket_Encounter_Share

FROM #Encounter_LOS
WHERE LOS_Days >= 0
GROUP BY
    Facility_Key,
    Facility_Name,
    Discharge_Year,
    LOS_Bucket
ORDER BY
    Facility_Name,
    Discharge_Year,
    LOS_Bucket;
GO

--------------------------------------------------------------------------------
-- STEP 05.05.04 - KPI: LOS by APR Severity of Illness
--
-- WHAT:
--   LOS statistics stratified by APR Severity (1–4).
--
-- WHY:
--   Severity stratification separates operational inefficiency from
--   clinically appropriate longer stays driven by patient complexity.
--------------------------------------------------------------------------------
SELECT
    Facility_Key,
    Facility_Name,
    Discharge_Year,

    ISNULL(CAST(APR_Severity_Code AS VARCHAR(10)), 'Unknown') AS APR_Severity_Code,
    ISNULL(APR_Severity_Description, 'Unknown') AS APR_Severity_Description,

    COUNT(*) AS Encounter_Count,

    CAST(AVG(CASE WHEN LOS_Days >= 0 THEN 1.0 * LOS_Days END) AS DECIMAL(10,2)) AS Avg_LOS_Days,
    MIN(CASE WHEN LOS_Days >= 0 THEN LOS_Days END) AS Min_LOS_Days,
    MAX(CASE WHEN LOS_Days >= 0 THEN LOS_Days END) AS Max_LOS_Days

FROM #Encounter_LOS
GROUP BY
    Facility_Key,
    Facility_Name,
    Discharge_Year,
    ISNULL(CAST(APR_Severity_Code AS VARCHAR(10)), 'Unknown'),
    ISNULL(APR_Severity_Description, 'Unknown')
ORDER BY
    Facility_Name,
    Discharge_Year,
    CASE
        WHEN ISNULL(CAST(APR_Severity_Code AS VARCHAR(10)), 'Unknown') = 'Unknown' THEN 9
        ELSE TRY_CAST(ISNULL(CAST(APR_Severity_Code AS VARCHAR(10)), 'Unknown') AS INT)
    END;
GO
