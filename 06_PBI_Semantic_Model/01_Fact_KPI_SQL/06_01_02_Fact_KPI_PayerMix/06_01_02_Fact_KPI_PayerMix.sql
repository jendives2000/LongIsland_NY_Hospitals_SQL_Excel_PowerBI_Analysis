--------------------------------------------------------------------------------
-- 06.01.02 — Fact_KPI_PayerMix
-- Grain: Facility_Key × Discharge_Year × Payer_Key
-- Keys relate to: Dim_Facility, Dim_Year, Dim_Payer
-- Additive components only; ratios stored as _validation
--------------------------------------------------------------------------------

IF OBJECT_ID('dbo.Fact_KPI_PayerMix', 'U') IS NOT NULL
    DROP TABLE dbo.Fact_KPI_PayerMix;
GO

WITH base AS (
    SELECT
        fe.Facility_Key,
        d.[Year] AS Discharge_Year,
        fe.Payer_Key,

        CAST(fe.Total_Costs   AS DECIMAL(19,4)) AS Total_Costs,
        CAST(fe.Total_Charges AS DECIMAL(19,4)) AS Total_Charges
    FROM dbo.Fact_Encounter fe
    JOIN dbo.Dim_Date d
        ON fe.Discharge_Date_Key = d.Date_Key
    WHERE
        d.[Year] IS NOT NULL
        AND fe.Payer_Key IS NOT NULL
        AND fe.Total_Costs IS NOT NULL
        AND fe.Total_Charges IS NOT NULL
),

agg AS (
    SELECT
        Facility_Key,
        Discharge_Year,
        Payer_Key,

        COUNT_BIG(*) AS Encounter_Count,
        SUM(Total_Costs) AS Total_Costs,
        SUM(Total_Charges) AS Total_Charges,
        SUM(CASE WHEN Total_Costs > Total_Charges THEN 1 ELSE 0 END)
            AS Negative_Margin_Encounter_Count
    FROM base
    GROUP BY Facility_Key, Discharge_Year, Payer_Key
),

facility_year_totals AS (
    SELECT
        Facility_Key,
        Discharge_Year,
        SUM(Encounter_Count) AS Facility_Year_Total_Encounters,
        SUM(Total_Costs)     AS Facility_Year_Total_Costs,
        SUM(Total_Charges)   AS Facility_Year_Total_Charges
    FROM agg
    GROUP BY Facility_Key, Discharge_Year
)

SELECT
    a.Facility_Key,
    a.Discharge_Year,
    a.Payer_Key,

    a.Encounter_Count,
    a.Total_Costs,
    a.Total_Charges,
    a.Negative_Margin_Encounter_Count,

    -- Validation-only (hide in Power BI)
    CAST(
        a.Encounter_Count * 1.0
        / NULLIF(t.Facility_Year_Total_Encounters, 0)
        AS DECIMAL(10,4)
    ) AS Payer_Encounter_Share_validation,

    CAST(
        a.Total_Costs * 1.0
        / NULLIF(t.Facility_Year_Total_Costs, 0)
        AS DECIMAL(10,4)
    ) AS Payer_Cost_Share_validation,

    CAST(
        a.Total_Charges * 1.0
        / NULLIF(t.Facility_Year_Total_Charges, 0)
        AS DECIMAL(10,4)
    ) AS Payer_Charge_Share_validation,

    CAST(
        a.Total_Costs * 1.0
        / NULLIF(a.Encounter_Count, 0)
        AS DECIMAL(10,4)
    ) AS Avg_Cost_Per_Encounter_validation,

    CAST(
        a.Total_Charges * 1.0
        / NULLIF(a.Encounter_Count, 0)
        AS DECIMAL(10,4)
    ) AS Avg_Charges_Per_Encounter_validation,

    CAST(
        a.Total_Charges - a.Total_Costs
        AS DECIMAL(19,4)
    ) AS Total_Margin_validation

INTO dbo.Fact_KPI_PayerMix
FROM agg a
JOIN facility_year_totals t
    ON a.Facility_Key   = t.Facility_Key
   AND a.Discharge_Year = t.Discharge_Year;
GO
