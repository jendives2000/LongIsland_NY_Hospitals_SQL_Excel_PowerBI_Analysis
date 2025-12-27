--------------------------------------------------------------------------------
-- FACT 05.05A - KPI: Length of Stay Summary
-- GRAIN: One row per Facility-Year
--
-- NOTE:
--   Avg / Min / Max LOS are NON-ADDITIVE and validation-only.
--   Authoritative Avg LOS must be computed in Power BI using:
--     SUM(Total_LOS_Days) / SUM(Encounter_Count)
--------------------------------------------------------------------------------

IF OBJECT_ID('dbo.Fact_KPI_LOS_Summary', 'U') IS NOT NULL
    DROP TABLE dbo.Fact_KPI_LOS_Summary;
GO

SELECT
    fe.Facility_Key,
    d.Year AS Discharge_Year,

    -- Additive denominator
    COUNT(*) AS Encounter_Count,

    -- Additive numerator (CRITICAL)
    SUM(fe.Length_of_Stay_Int) AS Total_LOS_Days,

    -- Non-additive statistics (validation only)
    AVG(CAST(fe.Length_of_Stay_Int AS DECIMAL(10,4))) AS Avg_LOS_validation,
    MIN(fe.Length_of_Stay_Int) AS Min_LOS_validation,
    MAX(fe.Length_of_Stay_Int) AS Max_LOS_validation

INTO dbo.Fact_KPI_LOS_Summary
FROM dbo.Fact_Encounter fe
JOIN dbo.Dim_Date d
    ON fe.Discharge_Date_Key = d.Date_Key
GROUP BY
    fe.Facility_Key,
    d.Year;
GO




--------------------------------------------------------------------------------
-- KPI OUTPUT (UPDATED): Length of Stay Summary
-- PURPOSE:
--   Visual confirmation in SSMS after adding additive LOS numerator.
--
-- NOTES:
--   - Authoritative Avg LOS is recomputed from additive components.
--   - *_validation columns are NON-additive and for sanity checks only.
--------------------------------------------------------------------------------

SELECT
    f.Facility_Name,
    k.Discharge_Year,

    -- Additive components (authoritative)
    k.Total_LOS_Days,
    k.Encounter_Count,

    -- Non-additive statistics (validation only)
    k.Avg_LOS_validation,
    k.Min_LOS_validation,
    k.Max_LOS_validation

FROM dbo.Fact_KPI_LOS_Summary k
JOIN dbo.Dim_Facility f
    ON k.Facility_Key = f.Facility_Key
ORDER BY
    f.Facility_Name,
    k.Discharge_Year;

