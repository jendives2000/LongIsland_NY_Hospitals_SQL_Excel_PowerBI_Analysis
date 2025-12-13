--------------------------------------------------------------------------------
-- STEP 05.03.01 - CHECK: Admission Type Coverage & Semantic Consistency
-- File: 05_03_01_Admission_Type_Coverage.sql
--
-- WHAT:
--   1) Validate that all encounters map to a standardized admission type
--      (Dim_AdmissionType.AdmissionType_Std).
--   2) Report BOTH:
--        A) Raw ED/Urgent intake proxy (if AdmissionType_Std contains those values)
--        B) Executive Unplanned category (if AdmissionType_Std uses Planned/Unplanned)
--   3) Flag semantic discrepancies (e.g., zero ED/Urgent but Unplanned present).
--
-- WHY:
--   "Unplanned" is an executive semantic category and is NOT guaranteed to be a
--   1:1 match to raw ED/Urgent intake coding.
--   Older logic: Unplanned admissions as AdmissionType_Std IN ('Emergency','Urgent')
--   Updated logic: treat ED/Urgent as an intake proxy AND separately track Unplanned
--   (if present in the standardized domain).
--
-- DEPENDENCIES:
--   Fact:
--     dbo.Fact_Encounter (Encounter_ID, Facility_Key, AdmissionType_Key, Discharge_Date_Key)
--   Dims:
--     dbo.Dim_AdmissionType (AdmissionType_Key, AdmissionType_Std)
--     dbo.Dim_Date          (Date_Key, Year)
--     dbo.Dim_Facility      (Facility_Key, Facility_Name)
--------------------------------------------------------------------------------

SET NOCOUNT ON;

--------------------------------------------------------------------------------
-- STEP 05.03.01.A - Build encounter-level admission type coverage table
--------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#Encounter_AdmitType') IS NOT NULL
BEGIN
    DROP TABLE #Encounter_AdmitType;
END;

SELECT
    fe.Encounter_ID,
    fe.Facility_Key,
    f.Facility_Name,

    -- Anchor reporting year
    dd.Year AS Encounter_Year,

    fe.AdmissionType_Key,
    dat.AdmissionType_Std,

    -- SIGNAL 1: ED/Urgent intake proxy (only meaningful if your Std domain includes these values)
    CASE WHEN dat.AdmissionType_Std IN ('Emergency','Urgent') THEN 1 ELSE 0 END AS Is_ED_Urgent_Proxy,

    -- SIGNAL 2: Executive Unplanned (only meaningful if your Std domain includes 'Unplanned')
    CASE WHEN dat.AdmissionType_Std = 'Unplanned' THEN 1 ELSE 0 END AS Is_Unplanned_Exec,

    -- Optional convenience flags for common executive domains
    CASE WHEN dat.AdmissionType_Std = 'Planned' THEN 1 ELSE 0 END AS Is_Planned_Exec

INTO #Encounter_AdmitType
FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Facility AS f
    ON fe.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS dd
    ON fe.Discharge_Date_Key = dd.Date_Key
LEFT JOIN dbo.Dim_AdmissionType AS dat
    ON fe.AdmissionType_Key = dat.AdmissionType_Key;

--------------------------------------------------------------------------------
-- STEP 05.03.01.B - KPI/Metric: NULL AdmissionType_Std coverage rate
--------------------------------------------------------------------------------
SELECT
    eat.Facility_Key,
    eat.Facility_Name,
    eat.Encounter_Year,

    COUNT(*) AS Total_Encounter_Count,

    SUM(CASE WHEN eat.AdmissionType_Std IS NULL THEN 1 ELSE 0 END)
        AS Null_AdmissionTypeStd_Encounter_Count,

    CAST(
        SUM(CASE WHEN eat.AdmissionType_Std IS NULL THEN 1 ELSE 0 END) * 1.0
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    ) AS Null_AdmissionTypeStd_Rate
FROM #Encounter_AdmitType AS eat
GROUP BY
    eat.Facility_Key,
    eat.Facility_Name,
    eat.Encounter_Year
ORDER BY
    eat.Facility_Name,
    eat.Encounter_Year;

--------------------------------------------------------------------------------
-- STEP 05.03.01.C - AdmissionType_Std distribution (incl. NULL)
--------------------------------------------------------------------------------
SELECT
    eat.Facility_Key,
    eat.Facility_Name,
    eat.Encounter_Year,

    ISNULL(eat.AdmissionType_Std, '<<NULL>>') AS AdmissionType_Std,

    COUNT(*) AS Encounter_Count,

    CAST(
        COUNT(*) * 1.0
        / NULLIF(
            SUM(COUNT(*)) OVER (PARTITION BY eat.Facility_Key, eat.Encounter_Year), 0
        )
        AS DECIMAL(10,4)
    ) AS Encounter_Share
FROM #Encounter_AdmitType AS eat
GROUP BY
    eat.Facility_Key,
    eat.Facility_Name,
    eat.Encounter_Year,
    ISNULL(eat.AdmissionType_Std, '<<NULL>>')
ORDER BY
    eat.Facility_Name,
    eat.Encounter_Year,
    AdmissionType_Std;

--------------------------------------------------------------------------------
-- STEP 05.03.01.D - Parallel presence/volume checks + discrepancy flags
-- OUTPUT:
--   - ED/Urgent proxy volume (intake signal)
--   - Executive Unplanned volume (semantic signal, if present)
--   - Planned admissions are inferred by exclusion, with remaining encounters categorized as Unknown
--   - Flags for common "missing signal" scenarios
--------------------------------------------------------------------------------
SELECT
    eat.Facility_Key,
    eat.Facility_Name,
    eat.Encounter_Year,

    SUM(CASE WHEN eat.AdmissionType_Std = 'Unplanned' THEN 1 ELSE 0 END)
        AS Unplanned_Exec_Encounter_Count,

    SUM(CASE
            WHEN eat.AdmissionType_Std IS NOT NULL
             AND eat.AdmissionType_Std <> 'Unplanned'
            THEN 1 ELSE 0
        END) AS Planned_Exec_Encounter_Count,

    SUM(CASE WHEN eat.AdmissionType_Std IS NULL THEN 1 ELSE 0 END)
        AS Unknown_Exec_Encounter_Count,

    COUNT(*) AS Total_Encounter_Count,

    CAST(
        SUM(CASE WHEN eat.AdmissionType_Std = 'Unplanned' THEN 1 ELSE 0 END) * 1.0
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    ) AS Unplanned_Exec_Rate
FROM #Encounter_AdmitType AS eat
GROUP BY
    eat.Facility_Key,
    eat.Facility_Name,
    eat.Encounter_Year
ORDER BY
    eat.Facility_Name,
    eat.Encounter_Year;


--------------------------------------------------------------------------------
-- STEP 05.03.01.E - Year slice quick view (kept from your original, expanded)
--------------------------------------------------------------------------------
DECLARE @DebugYear INT = 2015;

SELECT
    ISNULL(AdmissionType_Std, '<<NULL>>') AS AdmissionType_Std,
    COUNT(*) AS Encounter_Count
FROM #Encounter_AdmitType
WHERE Encounter_Year = @DebugYear
GROUP BY ISNULL(AdmissionType_Std, '<<NULL>>')
ORDER BY Encounter_Count DESC;

--------------------------------------------------------------------------------
-- STEP 05.03.01.F - Optional: show whether the domain even contains key labels
-- (This tells you if ED/Urgent or Unplanned exist at all in Dim_AdmissionType.)
--------------------------------------------------------------------------------
SELECT
    dat.AdmissionType_Std,
    COUNT(*) AS Dim_Row_Count
FROM dbo.Dim_AdmissionType AS dat
GROUP BY dat.AdmissionType_Std
ORDER BY Dim_Row_Count DESC;


