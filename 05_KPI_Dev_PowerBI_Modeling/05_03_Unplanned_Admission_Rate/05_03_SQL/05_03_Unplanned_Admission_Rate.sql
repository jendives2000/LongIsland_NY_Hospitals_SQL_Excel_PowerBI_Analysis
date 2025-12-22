--------------------------------------------------------------------------------
-- STEP 05.03 - KPI: Unplanned Admission Rate
-- File: 05_03_Unplanned_Admission_Rate.sql
--
-- WHAT:
--   Create a KPI view that measures the proportion of encounters admitted via
--   unplanned routes (Emergency / Urgent) by Facility and Year.
--
-- WHY:
--   Unplanned admissions increase operational pressure (ED load, bed capacity,
--   staffing) and help explain downstream KPIs like LOS and cost.
--
-- LOGIC (project assumption):
--   AdmissionType_Std IN ('Emergency', 'Urgent')  => Unplanned
--   Else                                         => Planned
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
--
-- Note: Inputs & dependency field list aligns with Step 05 README inputs :contentReference[oaicite:0]{index=0}
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

        -- WHAT: Flag unplanned encounters.
        -- WHY: Makes the grouping rule explicit and reusable.
        CASE
            WHEN da.AdmissionType_Std IN ('Emergency', 'Urgent') THEN 1
            ELSE 0
        END AS Unplanned_Flag
    FROM dbo.Fact_Encounter AS fe
    INNER JOIN dbo.Dim_AdmissionType AS da
        ON fe.AdmissionType_Key = da.AdmissionType_Key
    WHERE fe.Admission_Date_Key IS NOT NULL
          -- WHAT: Require an admission date to assign a year.
          -- WHY: Prevents unassigned-year encounters from being silently misgrouped.
)
SELECT
    f.Facility_Key,
    f.Facility_Name,
    d.Year AS Encounter_Year,

    -- WHAT: Total encounters (with a valid admission date and admission type join).
    -- WHY: Denominator for planned/unplanned rates.
    COUNT(*) AS Encounter_Count_Total,

    -- WHAT: Count unplanned encounters.
    -- WHY: Numerator to quantify ED/urgent pressure on capacity.
    SUM(Unplanned_Flag) AS Encounter_Count_Unplanned,

    -- WHAT: Count planned encounters.
    -- WHY: Complements unplanned for a quick volume breakdown.
    SUM(CASE WHEN Unplanned_Flag = 0 THEN 1 ELSE 0 END) AS Encounter_Count_Planned,

    -- WHAT: Unplanned admission rate (0–1).
    -- WHY: Comparable metric across facilities and time.
    CAST(SUM(Unplanned_Flag) * 1.0 / NULLIF(COUNT(*), 0) AS DECIMAL(10,4)) AS Unplanned_Admission_Rate

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
--
-- WHAT:
--   One row per encounter with the admission type and the derived Unplanned_Flag.
--
-- WHY:
--   This is the raw dataset you export to Excel to reproduce the KPI using a PivotTable.
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
-- KPI view to validate the granular view against for Excel logic and metrics validations
--------------------------------------------------------------------------------
-- a) Raw aggregation (facility-year)
SELECT
    f.Facility_Name,
    d.Year AS Encounter_Year,
    COUNT(*) AS Encounter_Count_Total,

    -- Unplanned encounters
    SUM(
        CASE 
            WHEN da.AdmissionType_Std = 'Unplanned' THEN 1 
            ELSE 0 
        END
    ) AS Encounter_Count_Unplanned,

    -- Planned encounters (Elective + Other)
    SUM(
        CASE 
            WHEN da.AdmissionType_Std <> 'Unplanned' THEN 1 
            ELSE 0 
        END
    ) AS Encounter_Count_Planned,

    -- Unplanned admission rate
    CAST(
        SUM(
            CASE 
                WHEN da.AdmissionType_Std = 'Unplanned' THEN 1 
                ELSE 0 
            END
        ) * 1.0 / NULLIF(COUNT(*), 0)
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
-- SANITY CHECK 1: AdmissionType_Std distribution (data quality)
--
-- WHAT:
--   Show counts by AdmissionType_Std for a scoped facility-year.
--
-- WHY:
--   Confirms standardized admission types exist as expected and highlights
--   unexpected categories (or missing standardization).
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
-- SANITY CHECK 2: Reconciliation check (no dropped/duplicated encounters)
--
-- WHAT:
--   Compare encounter totals per facility-year between:
--     (1) Fact_Encounter joined to Dim_Date + Dim_AdmissionType
--     (2) KPI view
--
-- WHY:
--   Ensures the KPI view includes every eligible encounter exactly once.
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
