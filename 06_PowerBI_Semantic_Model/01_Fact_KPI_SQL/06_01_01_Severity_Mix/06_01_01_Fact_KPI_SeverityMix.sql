--------------------------------------------------------------------------------
-- 06.01.01 — Fact_KPI_SeverityMix
-- Grain: Facility_Key × Discharge_Year
-- Keys: Facility_Key, Discharge_Year (relate to Dim_Facility + Dim_Year)
-- Stores additive components; KPI rate stored only as _validation (hide in PBI)
--------------------------------------------------------------------------------

IF OBJECT_ID('dbo.Fact_KPI_SeverityMix', 'U') IS NOT NULL
    DROP TABLE dbo.Fact_KPI_SeverityMix;
GO

SELECT
    fe.Facility_Key,
    d.[Year] AS Discharge_Year,

    COUNT_BIG(*) AS Total_Encounters,

    SUM(
        CASE
            WHEN cc.APR_Severity_Code BETWEEN 1 AND 4 THEN cc.APR_Severity_Code
            ELSE 0
        END
    ) AS Weighted_Severity_Sum,

    CAST(
        SUM(CASE WHEN cc.APR_Severity_Code BETWEEN 1 AND 4 THEN cc.APR_Severity_Code ELSE 0 END) * 1.0
        / NULLIF(COUNT_BIG(*), 0)
        AS DECIMAL(10,4)
    ) AS Severity_Mix_Index_validation

INTO dbo.Fact_KPI_SeverityMix
FROM dbo.Fact_Encounter fe
JOIN dbo.Dim_Date d
    ON fe.Discharge_Date_Key = d.Date_Key
JOIN dbo.Dim_ClinicalClass cc
    ON fe.ClinicalClass_Key = cc.ClinicalClass_Key
WHERE d.[Year] IS NOT NULL
GROUP BY
    fe.Facility_Key,
    d.[Year];
GO





