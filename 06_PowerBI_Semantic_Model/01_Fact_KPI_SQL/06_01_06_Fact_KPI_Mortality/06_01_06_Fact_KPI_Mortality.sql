--------------------------------------------------------------------------------
-- 06.01.06 — Fact_KPI_Mortality
-- Grain: Facility_Key × Discharge_Year
-- Death defined via Dim_Disposition.Disposition_Grouped = 'Death'
--------------------------------------------------------------------------------

IF OBJECT_ID('dbo.Fact_KPI_Mortality', 'U') IS NOT NULL
    DROP TABLE dbo.Fact_KPI_Mortality;
GO

SELECT
    fe.Facility_Key,
    d.[Year] AS Discharge_Year,

    COUNT_BIG(*) AS Total_Encounters,

    SUM(CASE WHEN disp.Disposition_Grouped = 'Death' THEN 1 ELSE 0 END) AS Death_Count,

    CAST(
        SUM(CASE WHEN disp.Disposition_Grouped = 'Death' THEN 1 ELSE 0 END) * 1.0
        / NULLIF(COUNT_BIG(*), 0)
        AS DECIMAL(10,4)
    ) AS Mortality_Rate_validation
INTO dbo.Fact_KPI_Mortality
FROM dbo.Fact_Encounter fe
JOIN dbo.Dim_Date d
    ON fe.Discharge_Date_Key = d.Date_Key
JOIN dbo.Dim_Disposition disp
    ON fe.Disposition_Key = disp.Disposition_Key
WHERE d.[Year] IS NOT NULL
GROUP BY fe.Facility_Key, d.[Year];
GO
