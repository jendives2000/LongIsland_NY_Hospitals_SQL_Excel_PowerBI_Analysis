--------------------------------------------------------------------------------
-- STEP 05.04 - KPI: Disposition Outcomes
-- File: 05_04_Disposition_Outcomes.sql
--
-- WHAT:
--   Produce two outputs:
--     (1) Encounter-level export (one row per patient stay) for Excel validation:
--         - Encounter_ID
--         - Facility_Name
--         - Discharge_Year
--         - Standardized_Disposition_Category
--     (2) KPI aggregation: Facility-Year-Standardized_Disposition_Category counts
--         and shares of total discharges.
--
-- WHY:
--   Disposition outcomes describe where patients go after discharge (Home,
--   Post-Acute, Transfer, Expired, etc.). This is a core executive flow/outcomes
--   KPI that complements admission pressure and LOS metrics.
--
-- DEPENDENCIES (per project Knowledge documentation):
--   Fact:
--     - dbo.Fact_Encounter
--       * Encounter_ID
--       * Facility_Key
--       * Discharge_Date_Key
--       * Disposition_Key
--   Dims:
--     - dbo.Dim_Facility      (Facility_Key, Facility_Name)
--     - dbo.Dim_Date          (Date_Key, Year)
--     - dbo.Dim_Disposition   (Disposition_Key, Disposition_Grouped)
--------------------------------------------------------------------------------

SET NOCOUNT ON;

--------------------------------------------------------------------------------
-- STEP 05.04.01 - OUTPUT (Granular): Encounter-level export for Excel validation
--
-- Excel needs one row per patient stay with:
--   Encounter_ID, Facility_Name, Discharge_Year, Standardized_Disposition_Category
--
-- NOTE:
--   We standardize disposition using Dim_Disposition.Disposition_Grouped.
--   If missing, we label as 'Unknown' so encounters are not silently dropped.
--------------------------------------------------------------------------------
SELECT
    fe.Encounter_ID,
    df.Facility_Name,
    dd.[Year] AS Discharge_Year,

    -- WHAT: Standardized executive disposition bucket
    -- WHY : Makes reporting stable across coding variation and supports Excel pivot validation
    ISNULL(ddisp.Disposition_Grouped, 'Unknown') AS Standardized_Disposition_Category
FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Facility AS df
    ON fe.Facility_Key = df.Facility_Key
INNER JOIN dbo.Dim_Date AS dd
    ON fe.Discharge_Date_Key = dd.Date_Key
LEFT JOIN dbo.Dim_Disposition AS ddisp
    ON fe.Disposition_Key = ddisp.Disposition_Key
ORDER BY
    df.Facility_Name,
    dd.[Year],
    fe.Encounter_ID;
GO

--------------------------------------------------------------------------------
-- STEP 05.04.02 - KPI View: Facility-Year-Standardized_Disposition_Category
-- OUTPUT:
--   - Encounter_Count
--   - Encounter_Share (within Facility-Year)
--
-- KPI consumer (BI / dashboard / downstream model) should read this view.
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.vw_KPI_DispositionOutcomes_FacilityYear', 'V') IS NOT NULL
BEGIN
    DROP VIEW dbo.vw_KPI_DispositionOutcomes_FacilityYear;
END;
GO

CREATE VIEW dbo.vw_KPI_DispositionOutcomes_FacilityYear
AS
WITH Encounter_Disposition AS (
    SELECT
        fe.Encounter_ID,                    -- keep encounter grain for accurate counts
        fe.Facility_Key,
        dd.[Year] AS Discharge_Year,

        -- WHAT: Standardized disposition group (executive-safe)
        -- WHY : Ensures consistent categorization and avoids dropping NULLs
        ISNULL(ddisp.Disposition_Grouped, 'Unknown') AS Standardized_Disposition_Category
    FROM dbo.Fact_Encounter AS fe
    INNER JOIN dbo.Dim_Date AS dd
        ON fe.Discharge_Date_Key = dd.Date_Key
    LEFT JOIN dbo.Dim_Disposition AS ddisp
        ON fe.Disposition_Key = ddisp.Disposition_Key
)
SELECT
    df.Facility_Key,
    df.Facility_Name,
    ed.Discharge_Year,
    ed.Standardized_Disposition_Category,

    -- KPI: Disposition Encounter Count
    -- WHAT: number of discharges in this category for the facility-year
    -- WHY : core volume measure for discharge outcomes
    COUNT(*) AS Disposition_Encounter_Count,

    -- KPI: Disposition Share
    -- WHAT: share of discharges in this category within facility-year
    -- WHY : makes cross-facility comparisons fair across different volumes
    CAST(
        COUNT(*) * 1.0
        / NULLIF(
            SUM(COUNT(*)) OVER (PARTITION BY df.Facility_Key, ed.Discharge_Year), 0
        )
        AS DECIMAL(10,4)
    ) AS Disposition_Encounter_Share

FROM Encounter_Disposition AS ed
INNER JOIN dbo.Dim_Facility AS df
    ON ed.Facility_Key = df.Facility_Key
GROUP BY
    df.Facility_Key,
    df.Facility_Name,
    ed.Discharge_Year,
    ed.Standardized_Disposition_Category;
GO

--------------------------------------------------------------------------------
-- STEP 05.04.03 - OUTPUT (KPI Table): Query the view (for review / export)
--------------------------------------------------------------------------------
SELECT
    Facility_Key,
    Facility_Name,
    Discharge_Year,
    Standardized_Disposition_Category,
    Disposition_Encounter_Count,
    Disposition_Encounter_Share
FROM dbo.vw_KPI_DispositionOutcomes_FacilityYear
ORDER BY
    Facility_Name,
    Discharge_Year,
    Standardized_Disposition_Category;
GO
