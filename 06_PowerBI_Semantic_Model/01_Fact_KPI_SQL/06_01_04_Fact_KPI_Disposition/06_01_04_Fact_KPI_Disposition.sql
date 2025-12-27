--------------------------------------------------------------------------------
-- FACT 05.04 - KPI: Disposition Outcomes
-- File: Fact_KPI_Disposition.sql
--------------------------------------------------------------------------------


IF OBJECT_ID('dbo.Fact_KPI_Disposition', 'U') IS NOT NULL
DROP TABLE dbo.Fact_KPI_Disposition;
GO


SELECT
fe.Facility_Key,
d.Year AS Discharge_Year,
dd.Disposition_Grouped,


COUNT(*) AS Disposition_Count


INTO dbo.Fact_KPI_Disposition
FROM dbo.Fact_Encounter fe
JOIN dbo.Dim_Date d
ON fe.Discharge_Date_Key = d.Date_Key
JOIN dbo.Dim_Disposition dd
ON fe.Disposition_Key = dd.Disposition_Key
GROUP BY
fe.Facility_Key,
d.Year,
dd.Disposition_Grouped;
GO



--------------------------------------------------------------------------------
-- KPI OUTPUT (VALIDATION): Disposition Rate by Facility-Year
--------------------------------------------------------------------------------

SELECT
    f.Facility_Name,
    k.Discharge_Year,
    k.Disposition_Grouped,

    -- Numerator
    k.Disposition_Count,

    -- Denominator
    SUM(k.Disposition_Count) OVER (
        PARTITION BY k.Facility_Key, k.Discharge_Year
    ) AS Total_Encounters_Facility_Year,

    -- Non-additive rate (validation only)
    CAST(
        k.Disposition_Count * 1.0
        / NULLIF(
            SUM(k.Disposition_Count) OVER (
                PARTITION BY k.Facility_Key, k.Discharge_Year
            ),
            0
        )
        AS DECIMAL(10,4)
    ) AS Disposition_Rate_validation

FROM dbo.Fact_KPI_Disposition k
JOIN dbo.Dim_Facility f
    ON k.Facility_Key = f.Facility_Key
ORDER BY
    f.Facility_Name,
    k.Discharge_Year,
    k.Disposition_Grouped;

