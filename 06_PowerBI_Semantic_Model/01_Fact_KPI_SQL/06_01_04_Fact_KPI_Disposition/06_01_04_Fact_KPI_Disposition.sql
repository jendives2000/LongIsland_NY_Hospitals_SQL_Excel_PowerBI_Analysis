--------------------------------------------------------------------------------
-- 06.01.04 — Fact_KPI_Disposition
-- Grain: Facility_Key × Discharge_Year × Disposition_Key
--------------------------------------------------------------------------------

IF OBJECT_ID('dbo.Fact_KPI_Disposition', 'U') IS NOT NULL
    DROP TABLE dbo.Fact_KPI_Disposition;
GO

SELECT
    fe.Facility_Key,
    d.[Year] AS Discharge_Year,
    fe.Disposition_Key,

    COUNT_BIG(*) AS Disposition_Count
INTO dbo.Fact_KPI_Disposition
FROM dbo.Fact_Encounter fe
JOIN dbo.Dim_Date d
    ON fe.Discharge_Date_Key = d.Date_Key
WHERE
    d.[Year] IS NOT NULL
    AND fe.Disposition_Key IS NOT NULL
GROUP BY
    fe.Facility_Key, d.[Year], fe.Disposition_Key;
GO
