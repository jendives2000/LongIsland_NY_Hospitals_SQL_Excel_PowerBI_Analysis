--------------------------------------------------------------------------------
-- STEP 05.07 - KPI: MCost per Encounter & Margin Pressure
-- File: 05_07_MCost_and_Margin_Pressure.sql
--
-- WHAT:
--   Produce financial efficiency KPIs from encounter-level costs and charges:
--     (1) Encounter-level export for Excel validation (one row per stay)
--     (2) Facility-Year KPI output:
--         - Avg MCost per Encounter  = Sum(Total_Costs) / Count(Encounters)
--         - Margin Pressure Ratio    = Sum(Total_Costs) / Sum(Total_Charges)
--         - Supporting totals for reconciliation
--
-- WHY:
--   This KPI connects clinical volume to financial performance. It is designed
--   for directional benchmarking of cost intensity and “pressure” (costs as a
--   share of charges), not for true profitability analysis.
--
-- DEPENDENCIES (per project Inputs & Dependencies):
--   Fact:
--     dbo.Fact_Encounter
--       * Encounter_ID
--       * Facility_Key
--       * Discharge_Date_Key
--       * Total_Costs
--       * Total_Charges
--   Dims:
--     dbo.Dim_Facility (Facility_Key, Facility_Name)
--     dbo.Dim_Date     (Date_Key, Year)
--------------------------------------------------------------------------------

SET NOCOUNT ON;

--------------------------------------------------------------------------------
-- STEP 05.07.00 - Build encounter-grain financial base (temp table)
--
-- WHAT:
--   Create one row per encounter with costs/charges and discharge year.
-- WHY:
--   Provides a clean, auditable grain for Excel Pivot validation and ensures
--   all KPI aggregates reconcile exactly to encounter-level totals.
--------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#Encounter_Finance') IS NOT NULL
BEGIN
    DROP TABLE #Encounter_Finance;
END;

SELECT
    fe.Encounter_ID,
    fe.Facility_Key,
    df.Facility_Name,
    dd.[Year] AS Discharge_Year,

    -- Financial inputs (encounter grain)
    fe.Total_Costs,
    fe.Total_Charges
INTO #Encounter_Finance
FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Facility AS df
    ON fe.Facility_Key = df.Facility_Key
INNER JOIN dbo.Dim_Date AS dd
    ON fe.Discharge_Date_Key = dd.Date_Key;

--------------------------------------------------------------------------------
-- STEP 05.07.01 - OUTPUT (Granular): Encounter-level export for Excel validation
--
-- Excel Pivot setup (per README):
--   Rows  : Facility_Name
--   Values: Sum(Total_Costs), Sum(Total_Charges), Count(Encounter_ID)
--   Calc  : Avg MCost = Sum(Total_Costs)/Count(Encounter_ID)
--           Margin Pressure = Sum(Total_Costs)/Sum(Total_Charges)
--------------------------------------------------------------------------------
SELECT
    Encounter_ID,
    Facility_Name,
    Discharge_Year,
    Total_Costs,
    Total_Charges
FROM #Encounter_Finance
ORDER BY
    Facility_Name,
    Discharge_Year,
    Encounter_ID;
GO

--------------------------------------------------------------------------------
-- STEP 05.07.02 - KPI OUTPUT: Facility-Year MCost per Encounter & Margin Pressure
--
-- WHAT:
--   Facility-Year aggregation with totals + ratios needed for reconciliation.
-- WHY:
--   Totals are included so Excel can reconcile numerator/denominator exactly.
--
-- Notes:
--   - Division by zero is protected via NULLIF.
--   - Ratios are DECIMAL(18,4) to minimize rounding drift vs Excel.
--------------------------------------------------------------------------------
SELECT
    Facility_Key,
    Facility_Name,
    Discharge_Year,

    COUNT(*) AS Encounter_Count,
    SUM(Total_Costs)  AS Total_Costs_Sum,
    SUM(Total_Charges) AS Total_Charges_Sum,

    -- Avg MCost = Total Costs / Total Encounters
    CAST(
        SUM(Total_Costs) * 1.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(18,4)
    ) AS Avg_MCost_Per_Encounter,

    -- Margin Pressure = Total Costs / Total Charges
    CAST(
        SUM(Total_Costs) * 1.0 / NULLIF(SUM(Total_Charges), 0)
        AS DECIMAL(18,4)
    ) AS Margin_Pressure_Ratio

FROM #Encounter_Finance
GROUP BY
    Facility_Key,
    Facility_Name,
    Discharge_Year
ORDER BY
    Facility_Name,
    Discharge_Year;
GO

--------------------------------------------------------------------------------
-- STEP 05.07.03 - OPTIONAL: Facility-Year data quality transparency slice
-- (Not a “SQL checks” section; this is practical audit context for Excel users.)
--
-- WHAT:
--   Show counts of encounters with NULL/zero costs or charges.
-- WHY:
--   Prevents confusion when margin pressure is NULL (Sum Charges = 0) or when
--   totals differ due to filtered rows in Excel.
--------------------------------------------------------------------------------
SELECT
    Facility_Name,
    Discharge_Year,

    COUNT(*) AS Encounter_Count,

    SUM(CASE WHEN Total_Costs   IS NULL THEN 1 ELSE 0 END) AS Null_Costs_Count,
    SUM(CASE WHEN Total_Charges IS NULL THEN 1 ELSE 0 END) AS Null_Charges_Count,

    SUM(CASE WHEN Total_Costs   = 0 THEN 1 ELSE 0 END) AS Zero_Costs_Count,
    SUM(CASE WHEN Total_Charges = 0 THEN 1 ELSE 0 END) AS Zero_Charges_Count

FROM #Encounter_Finance
GROUP BY
    Facility_Name,
    Discharge_Year
ORDER BY
    Facility_Name,
    Discharge_Year;
GO
