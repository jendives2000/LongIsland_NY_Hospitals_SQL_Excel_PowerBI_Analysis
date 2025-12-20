/*
KPI 05.01 — Severity Mix Index (APR)
Goal: One script that
  1) Defines the encounter-level granular view (for validation exports)
  2) Defines the facility-year KPI view (the KPI you validate against)
  3) ACTUALLY OUTPUTS the encounter-level granular rows via a final SELECT

NOTE:
- Views themselves do not “output” until you SELECT from them.
- If your environment does not support GO, remove the GO lines.
*/


/* ============================================================
   1) Encounter-level output (granular) for validation export
   ============================================================ */
CREATE OR ALTER VIEW dbo.vw_KPI_05_01_SeverityMix_Encounter
AS
SELECT
    fe.Encounter_ID,
    df.Facility_Key,
    df.Facility_Name,
    dd.[Year] AS Discharge_Year,
    dcc.APR_Severity_Code
FROM dbo.Fact_Encounter fe
INNER JOIN dbo.Dim_Date dd
    ON fe.Discharge_Date_Key = dd.Date_Key
INNER JOIN dbo.Dim_Facility df
    ON fe.Facility_Key = df.Facility_Key
INNER JOIN dbo.Dim_ClinicalClass dcc
    ON fe.ClinicalClass_Key = dcc.ClinicalClass_Key
WHERE
    fe.Encounter_ID IS NOT NULL
    AND dd.[Year] IS NOT NULL
    AND dcc.APR_Severity_Code IN (1,2,3,4);
GO


/* ============================================================
   2) Facility-Year KPI view (the KPI to validate against)
   Outputs:
     - Encounter counts per severity 1–4
     - Encounter_Count
     - Severity_Mix_Index = Average(APR_Severity_Code)
   ============================================================ */
CREATE OR ALTER VIEW dbo.vw_KPI_05_01_SeverityMix_FacilityYear
AS
SELECT
    e.Facility_Key,
    e.Facility_Name,
    e.Discharge_Year,

    COUNT_BIG(*) AS Encounter_Count,

    SUM(CASE WHEN e.APR_Severity_Code = 1 THEN 1 ELSE 0 END) AS Severity_1_Count,
    SUM(CASE WHEN e.APR_Severity_Code = 2 THEN 1 ELSE 0 END) AS Severity_2_Count,
    SUM(CASE WHEN e.APR_Severity_Code = 3 THEN 1 ELSE 0 END) AS Severity_3_Count,
    SUM(CASE WHEN e.APR_Severity_Code = 4 THEN 1 ELSE 0 END) AS Severity_4_Count,

    CAST(AVG(CAST(e.APR_Severity_Code AS DECIMAL(10,4))) AS DECIMAL(10,4)) AS Severity_Mix_Index
FROM dbo.vw_KPI_05_01_SeverityMix_Encounter e
GROUP BY
    e.Facility_Key,
    e.Facility_Name,
    e.Discharge_Year;
GO


/* ============================================================
   3) OUTPUT: Full encounter-level granular view
   (This is the part you were missing.)
   ============================================================ */

-- FULL encounter-level output (no TOP)
SELECT
    Encounter_ID,
    Facility_Key,
    Facility_Name,
    Discharge_Year,
    APR_Severity_Code
FROM dbo.vw_KPI_05_01_SeverityMix_Encounter
ORDER BY
    Discharge_Year,
    Facility_Name,
    Encounter_ID;
GO


/* ============================================================
   4) OUTPUT: KPI results (facility-year rollup)
   ============================================================ */
SELECT
    Facility_Key,
    Facility_Name,
    Discharge_Year,
    Encounter_Count,
    Severity_1_Count,
    Severity_2_Count,
    Severity_3_Count,
    Severity_4_Count,
    Severity_Mix_Index
FROM dbo.vw_KPI_05_01_SeverityMix_FacilityYear
ORDER BY
    Discharge_Year,
    Facility_Name;
GO


/* ============================================================
   5) (Optional) One-line reconciliation check
   ============================================================ */
SELECT
    (SELECT COUNT_BIG(*) FROM dbo.vw_KPI_05_01_SeverityMix_Encounter) AS EncounterLevel_Rows,
    (SELECT SUM(Encounter_Count) FROM dbo.vw_KPI_05_01_SeverityMix_FacilityYear) AS KPI_Summed_Encounters;
GO
