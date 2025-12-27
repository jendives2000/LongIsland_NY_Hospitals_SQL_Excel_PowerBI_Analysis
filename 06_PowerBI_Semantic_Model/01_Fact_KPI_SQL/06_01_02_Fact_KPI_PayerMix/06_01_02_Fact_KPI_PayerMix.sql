--------------------------------------------------------------------------------
-- FACT 05.01 - KPI: Severity Mix Index
-- File: Fact_KPI_SeverityMix.sql
--
-- WHAT:
-- Aggregate encounter-level APR severity into a Facility-Year KPI fact
-- suitable for Power BI slicing and reconciliation.
--
-- WHY:
-- Severity Mix Index reflects patient acuity and is foundational for
-- interpreting cost, LOS, and mortality KPIs.
--
-- GRAIN:
-- One row per Facility_Key per Discharge_Year.
--------------------------------------------------------------------------------


IF OBJECT_ID('dbo.Fact_KPI_SeverityMix', 'U') IS NOT NULL
DROP TABLE dbo.Fact_KPI_SeverityMix;
GO


SELECT
fe.Facility_Key,
d.Year AS Discharge_Year,


COUNT(*) AS Total_Encounters,


-- Numerator: weighted severity total
SUM(CASE cc.APR_Severity_Code
WHEN 1 THEN 1
WHEN 2 THEN 2
WHEN 3 THEN 3
WHEN 4 THEN 4
ELSE 0
END) AS Weighted_Severity_Sum,


-- Stored for validation only; recomputed in DAX for reporting
CAST(
SUM(CASE cc.APR_Severity_Code
WHEN 1 THEN 1
WHEN 2 THEN 2
WHEN 3 THEN 3
WHEN 4 THEN 4
ELSE 0
END) * 1.0
/ NULLIF(COUNT(*), 0)
AS DECIMAL(10,4)
) AS Severity_Mix_Index_validation


INTO dbo.Fact_KPI_SeverityMix
FROM dbo.Fact_Encounter fe
JOIN dbo.Dim_Date d
ON fe.Discharge_Date_Key = d.Date_Key
JOIN dbo.Dim_ClinicalClass cc
ON fe.ClinicalClass_Key = cc.ClinicalClass_Key
GROUP BY
fe.Facility_Key,
d.Year;
GO


--------------------------------------------------------------------------------
-- KPI OUTPUT: Severity Mix Index by Facility-Year
--------------------------------------------------------------------------------

SELECT
    f.Facility_Name,
    k.Discharge_Year,
    k.Weighted_Severity_Sum,
    k.Total_Encounters,
    CAST(
        k.Weighted_Severity_Sum * 1.0
        / NULLIF(k.Total_Encounters, 0)
        AS DECIMAL(10,4)
    ) AS Severity_Mix_Index_validation
FROM dbo.Fact_KPI_SeverityMix k
JOIN dbo.Dim_Facility f
    ON k.Facility_Key = f.Facility_Key
ORDER BY
    f.Facility_Name,
    k.Discharge_Year;
