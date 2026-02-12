--------------------------------------------------------------------------------
-- STEP 05.03 - KPI: Unplanned Admission Rate
-- File: 05_03_Unplanned_Admission_Rate.sql
--
-- WHAT:
--   Create a KPI view that measures the proportion of encounters admitted via
--   unplanned routes by Facility and Year.
--
-- WHY:
--   Unplanned admissions increase operational pressure (ED load, bed capacity,
--   staffing) and help explain downstream KPIs like LOS and cost.
--
-- LOGIC (data-aligned to Dim_AdmissionType.AdmissionType_Std values):
--   AdmissionType_Std = 'Unplanned'  => Unplanned
--   Else                             => Planned
--
-- DEPENDENCIES (schema-aligned):
--   dbo.Fact_Encounter:
--     Encounter_ID, Facility_Key, AdmissionType_Key, Admission_Date_Key
--   dbo.Dim_AdmissionType:
--     AdmissionType_Key, AdmissionType_Std
--   dbo.Dim_Facility:
--     Facility_Key, Facility_Name
--   dbo.Dim_Date:
--     Date_Key, Year
--------------------------------------------------------------------------------

IF OBJECT_ID('dbo.vw_KPI_UnplannedAdmissions_FacilityYear', 'V') IS NOT NULL
BEGIN
    DROP VIEW dbo.vw_KPI_UnplannedAdmissions_FacilityYear;
END;
GO

CREATE VIEW dbo.vw_KPI_UnplannedAdmissions_FacilityYear
AS
WITH AdmitType_Clean AS (
    SELECT
        fe.Encounter_ID,               -- encounter grain for correct counting
        fe.Facility_Key,
        fe.Admission_Date_Key,         -- anchor for Encounter_Year
        da.AdmissionType_Std,

        -- Flag unplanned encounters using standardized domain values
        CASE
            WHEN da.AdmissionType_Std = 'Unplanned' THEN 1
            ELSE 0
        END AS Unplanned_Flag
    FROM dbo.Fact_Encounter AS fe
    INNER JOIN dbo.Dim_AdmissionType AS da
        ON fe.AdmissionType_Key = da.AdmissionType_Key
    WHERE fe.Admission_Date_Key IS NOT NULL
)
SELECT
    f.Facility_Key,
    f.Facility_Name,
    d.Year AS Encounter_Year,

    COUNT(*) AS Encounter_Count_Total,
    SUM(atc.Unplanned_Flag) AS Encounter_Count_Unplanned,
    SUM(CASE WHEN atc.Unplanned_Flag = 0 THEN 1 ELSE 0 END) AS Encounter_Count_Planned,
    CAST(SUM(atc.Unplanned_Flag) * 1.0 / NULLIF(COUNT(*), 0) AS DECIMAL(10,4)) AS Unplanned_Admission_Rate
FROM AdmitType_Clean AS atc
INNER JOIN dbo.Dim_Facility AS f
    ON atc.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS d
    ON atc.Admission_Date_Key = d.Date_Key
GROUP BY
    f.Facility_Key,
    f.Facility_Name,
    d.Year;
GO

--------------------------------------------------------------------------------
-- 05.03 (GRANULAR EXTRACT): Unplanned Admission validation dataset
--   One row per encounter with admission type and derived Unplanned_Flag.
--------------------------------------------------------------------------------

SELECT
    fe.Encounter_ID,
    f.Facility_Name,
    d.Year AS Encounter_Year,
    da.AdmissionType_Std,
    CASE
        WHEN da.AdmissionType_Std = 'Unplanned' THEN 1
        ELSE 0
    END AS Unplanned_Flag
FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Facility AS f
    ON fe.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS d
    ON fe.Admission_Date_Key = d.Date_Key
INNER JOIN dbo.Dim_AdmissionType AS da
    ON fe.AdmissionType_Key = da.AdmissionType_Key
WHERE
    d.Year = 2015
ORDER BY
    f.Facility_Name,
    fe.Encounter_ID;
GO

--------------------------------------------------------------------------------
-- KPI view validation: raw aggregation (facility-year)
--------------------------------------------------------------------------------

SELECT
    f.Facility_Name,
    d.Year AS Encounter_Year,
    COUNT(*) AS Encounter_Count_Total,

    SUM(CASE WHEN da.AdmissionType_Std = 'Unplanned' THEN 1 ELSE 0 END) AS Encounter_Count_Unplanned,
    SUM(CASE WHEN da.AdmissionType_Std <> 'Unplanned' THEN 1 ELSE 0 END) AS Encounter_Count_Planned,

    CAST(
        SUM(CASE WHEN da.AdmissionType_Std = 'Unplanned' THEN 1 ELSE 0 END) * 1.0
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    ) AS Unplanned_Admission_Rate
FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Facility AS f
    ON fe.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS d
    ON fe.Admission_Date_Key = d.Date_Key
INNER JOIN dbo.Dim_AdmissionType AS da
    ON fe.AdmissionType_Key = da.AdmissionType_Key
WHERE
    d.Year = 2015
GROUP BY
    f.Facility_Name,
    d.Year
ORDER BY
    f.Facility_Name;
GO

--------------------------------------------------------------------------------
-- SANITY CHECK: AdmissionType_Std distribution for a year
--------------------------------------------------------------------------------

SELECT
    d.Year AS Encounter_Year,
    da.AdmissionType_Std,
    COUNT(*) AS Encounter_Count
FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Date AS d
    ON fe.Admission_Date_Key = d.Date_Key
INNER JOIN dbo.Dim_AdmissionType AS da
    ON fe.AdmissionType_Key = da.AdmissionType_Key
WHERE
    d.Year = 2015
GROUP BY
    d.Year,
    da.AdmissionType_Std
ORDER BY
    da.AdmissionType_Std;
GO

--------------------------------------------------------------------------------
-- RECONCILIATION: Compare totals between KPI view and fact joins
--------------------------------------------------------------------------------

-- a) KPI view totals
SELECT
    Facility_Name,
    Encounter_Year,
    SUM(Encounter_Count_Total) AS View_Encounter_Count
FROM dbo.vw_KPI_UnplannedAdmissions_FacilityYear
GROUP BY
    Facility_Name,
    Encounter_Year
ORDER BY
    Facility_Name,
    Encounter_Year;
GO

-- b) Fact table totals (same join conditions)
SELECT
    f.Facility_Name,
    d.Year AS Encounter_Year,
    COUNT(*) AS Fact_Encounter_Count
FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Facility AS f
    ON fe.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS d
    ON fe.Admission_Date_Key = d.Date_Key
INNER JOIN dbo.Dim_AdmissionType AS da
    ON fe.AdmissionType_Key = da.AdmissionType_Key
GROUP BY
    f.Facility_Name,
    d.Year
ORDER BY
    f.Facility_Name,
    d.Year;
GO
