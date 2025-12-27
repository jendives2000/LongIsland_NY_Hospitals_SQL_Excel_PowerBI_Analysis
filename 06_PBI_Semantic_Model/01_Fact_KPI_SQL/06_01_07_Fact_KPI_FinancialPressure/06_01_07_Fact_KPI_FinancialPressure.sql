--------------------------------------------------------------------------------
-- 06.01.07 — Fact_KPI_FinancialPressure
-- Grain: Facility_Key × Discharge_Year
-- Stores additive totals + counts; ratios are validation only (hide in PBI)
--------------------------------------------------------------------------------

IF OBJECT_ID('dbo.Fact_KPI_FinancialPressure', 'U') IS NOT NULL
    DROP TABLE dbo.Fact_KPI_FinancialPressure;
GO

SELECT
    fe.Facility_Key,
    d.[Year] AS Discharge_Year,

    COUNT_BIG(*) AS Encounter_Count,

    SUM(CAST(fe.Total_Costs   AS DECIMAL(19,4))) AS Total_Costs,
    SUM(CAST(fe.Total_Charges AS DECIMAL(19,4))) AS Total_Charges,

    SUM(CASE WHEN fe.Total_Costs > fe.Total_Charges THEN 1 ELSE 0 END) AS Negative_Margin_Encounter_Count,

    CAST(
        SUM(CAST(fe.Total_Costs AS DECIMAL(19,4))) * 1.0
        / NULLIF(COUNT_BIG(*), 0)
        AS DECIMAL(10,4)
    ) AS Avg_MCost_validation,

    CAST(
        (SUM(CAST(fe.Total_Charges AS DECIMAL(19,4))) - SUM(CAST(fe.Total_Costs AS DECIMAL(19,4))))
        AS DECIMAL(19,4)
    ) AS Total_Margin_validation,

    CAST(
        SUM(CAST(fe.Total_Costs AS DECIMAL(19,4))) * 1.0
        / NULLIF(SUM(CAST(fe.Total_Charges AS DECIMAL(19,4))), 0)
        AS DECIMAL(10,4)
    ) AS Margin_Pressure_validation
INTO dbo.Fact_KPI_FinancialPressure
FROM dbo.Fact_Encounter fe
JOIN dbo.Dim_Date d
    ON fe.Discharge_Date_Key = d.Date_Key
WHERE
    d.[Year] IS NOT NULL
    AND fe.Total_Costs IS NOT NULL
    AND fe.Total_Charges IS NOT NULL
GROUP BY fe.Facility_Key, d.[Year];
GO
