--------------------------------------------------------------------------------
-- FACT 05.03 - KPI: Unplanned Admission Rate
-- File: Fact_KPI_Unplanned.sql
--------------------------------------------------------------------------------


IF OBJECT_ID('dbo.Fact_KPI_Unplanned', 'U') IS NOT NULL
DROP TABLE dbo.Fact_KPI_Unplanned;
GO


SELECT
fe.Facility_Key,
d.Year AS Discharge_Year,


COUNT(*) AS Total_Encounters,
SUM(CASE WHEN da.AdmissionType_Std = 'Unplanned'
THEN 1 ELSE 0 END) AS Unplanned_Encounter_Count


INTO dbo.Fact_KPI_Unplanned
FROM dbo.Fact_Encounter fe
JOIN dbo.Dim_Date d
ON fe.Discharge_Date_Key = d.Date_Key
JOIN dbo.Dim_AdmissionType da
ON fe.AdmissionType_Key = da.AdmissionType_Key
GROUP BY
fe.Facility_Key,
d.Year;
GO


--------------------------------------------------------------------------------
-- KPI OUTPUT: Unplanned Admission Rate
--------------------------------------------------------------------------------

SELECT
    f.Facility_Name,
    k.Discharge_Year,
    k.Unplanned_Encounter_Count,
    k.Total_Encounters,
    CAST(
        k.Unplanned_Encounter_Count * 1.0
        / NULLIF(k.Total_Encounters, 0)
        AS DECIMAL(10,4)
    ) AS Unplanned_Admission_Rate_validation
FROM dbo.Fact_KPI_Unplanned k
JOIN dbo.Dim_Facility f
    ON k.Facility_Key = f.Facility_Key
ORDER BY
    f.Facility_Name,
    k.Discharge_Year;
