--------------------------------------------------------------------------------
-- 06.01.05 — Fact_KPI_LOS_Summary
-- Grain: Facility_Key × Discharge_Year
-- Stores additive Total_LOS_Days; averages are validation only (hide in PBI)
--------------------------------------------------------------------------------

IF OBJECT_ID('dbo.Fact_KPI_LOS_Summary', 'U') IS NOT NULL
    DROP TABLE dbo.Fact_KPI_LOS_Summary;
GO

SELECT
    fe.Facility_Key,
    d.[Year] AS Discharge_Year,

    COUNT_BIG(*) AS Encounter_Count,
    SUM(CAST(fe.Length_of_Stay_Int AS BIGINT)) AS Total_LOS_Days,

    MIN(fe.Length_of_Stay_Int) AS Min_LOS_Days,
    MAX(fe.Length_of_Stay_Int) AS Max_LOS_Days,

    CAST(
        SUM(CAST(fe.Length_of_Stay_Int AS BIGINT)) * 1.0
        / NULLIF(COUNT_BIG(*), 0)
        AS DECIMAL(10,4)
    ) AS Avg_LOS_validation
INTO dbo.Fact_KPI_LOS_Summary
FROM dbo.Fact_Encounter fe
JOIN dbo.Dim_Date d
    ON fe.Discharge_Date_Key = d.Date_Key
WHERE
    d.[Year] IS NOT NULL
    AND fe.Length_of_Stay_Int IS NOT NULL
    AND fe.Length_of_Stay_Int >= 0
GROUP BY fe.Facility_Key, d.[Year];
GO
