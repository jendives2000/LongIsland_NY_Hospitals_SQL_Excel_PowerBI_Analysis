--------------------------------------------------------------------------------
-- FACT 05.06 - KPI: Mortality Rate
-- File: Fact_KPI_Mortality.sql
--------------------------------------------------------------------------------


IF OBJECT_ID('dbo.Fact_KPI_Mortality', 'U') IS NOT NULL
DROP TABLE dbo.Fact_KPI_Mortality;
GO


SELECT
fe.Facility_Key,
d.Year AS Discharge_Year,


COUNT(*) AS Total_Encounters,
SUM(CASE WHEN cc.APR_Risk_Of_Mortality_Desc = 'Extreme'
THEN 1 ELSE 0 END) AS Death_Count


INTO dbo.Fact_KPI_Mortality
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
-- KPI OUTPUT: Mortality Rate
--------------------------------------------------------------------------------

SELECT
    f.Facility_Name,
    k.Discharge_Year,
    k.Death_Count,
    k.Total_Encounters,
    CAST(
        k.Death_Count * 1.0
        / NULLIF(k.Total_Encounters, 0)
        AS DECIMAL(10,4)
    ) AS Mortality_Rate_validation
FROM dbo.Fact_KPI_Mortality k
JOIN dbo.Dim_Facility f
    ON k.Facility_Key = f.Facility_Key
ORDER BY
    f.Facility_Name,
    k.Discharge_Year;
