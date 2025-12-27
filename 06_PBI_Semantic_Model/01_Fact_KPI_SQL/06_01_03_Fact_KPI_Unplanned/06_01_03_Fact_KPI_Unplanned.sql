--------------------------------------------------------------------------------
-- 06.01.03 — Fact_KPI_Unplanned
-- Grain: Facility_Key × Discharge_Year
--------------------------------------------------------------------------------

IF OBJECT_ID('dbo.Fact_KPI_Unplanned', 'U') IS NOT NULL
    DROP TABLE dbo.Fact_KPI_Unplanned;
GO

SELECT
    fe.Facility_Key,
    d.[Year] AS Discharge_Year,

    COUNT_BIG(*) AS Total_Encounters,

    SUM(CASE WHEN at.AdmissionType_Std = 'Unplanned' THEN 1 ELSE 0 END) AS Unplanned_Encounter_Count,
    SUM(CASE WHEN at.AdmissionType_Std <> 'Unplanned' OR at.AdmissionType_Std IS NULL THEN 1 ELSE 0 END) AS Planned_Encounter_Count,

    CAST(
        SUM(CASE WHEN at.AdmissionType_Std = 'Unplanned' THEN 1 ELSE 0 END) * 1.0
        / NULLIF(COUNT_BIG(*), 0)
        AS DECIMAL(10,4)
    ) AS Unplanned_Admission_Rate_validation
INTO dbo.Fact_KPI_Unplanned
FROM dbo.Fact_Encounter fe
JOIN dbo.Dim_Date d
    ON fe.Discharge_Date_Key = d.Date_Key
JOIN dbo.Dim_AdmissionType at
    ON fe.AdmissionType_Key = at.AdmissionType_Key
WHERE d.[Year] IS NOT NULL
GROUP BY fe.Facility_Key, d.[Year];
GO
