--------------------------------------------------------------------------------
-- FACT 05.07 - KPI: MCost & Margin Pressure
-- File: Fact_KPI_FinancialPressure.sql
--------------------------------------------------------------------------------


IF OBJECT_ID('dbo.Fact_KPI_FinancialPressure', 'U') IS NOT NULL
DROP TABLE dbo.Fact_KPI_FinancialPressure;
GO


SELECT
fe.Facility_Key,
d.Year AS Discharge_Year,


COUNT(*) AS Encounter_Count,
SUM(fe.Total_Costs) AS Total_Costs,
SUM(fe.Total_Charges) AS Total_Charges,


AVG(fe.Total_Costs) AS Avg_MCost,
SUM(CASE WHEN fe.Total_Costs > fe.Total_Charges
THEN 1 ELSE 0 END) AS Negative_Margin_Encounter_Count


INTO dbo.Fact_KPI_FinancialPressure
FROM dbo.Fact_Encounter fe
JOIN dbo.Dim_Date d
ON fe.Discharge_Date_Key = d.Date_Key
GROUP BY
fe.Facility_Key,
d.Year;
GO


--------------------------------------------------------------------------------
-- KPI OUTPUT (UPDATED): Financial Pressure Summary
-- PURPOSE:
--   Visual validation in SSMS.
--
-- NOTES:
--   - Avg_Cost_Per_Encounter_validation is NON-additive.
--   - Authoritative Avg Cost must be computed in Power BI using:
--       SUM(Total_Costs) / SUM(Encounter_Count)
--------------------------------------------------------------------------------

SELECT
    f.Facility_Name,
    k.Discharge_Year,

    -- Additive components
    k.Encounter_Count,
    k.Total_Costs,
    k.Total_Charges,

    -- Validation: Average cost per encounter (non-additive)
    CAST(
        k.Total_Costs * 1.0
        / NULLIF(k.Encounter_Count, 0)
        AS DECIMAL(18,2)
    ) AS Avg_Cost_Per_Encounter_validation,

    -- Margin diagnostics
    CAST(
        k.Total_Charges - k.Total_Costs
        AS DECIMAL(18,2)
    ) AS Total_Margin,

    CAST(
        (k.Total_Charges - k.Total_Costs) * 1.0
        / NULLIF(k.Total_Charges, 0)
        AS DECIMAL(10,4)
    ) AS Margin_Rate_validation,

    k.Negative_Margin_Encounter_Count

FROM dbo.Fact_KPI_FinancialPressure k
JOIN dbo.Dim_Facility f
    ON k.Facility_Key = f.Facility_Key
ORDER BY
    f.Facility_Name,
    k.Discharge_Year;

