/* ==========================================================
   04.7 — Setup: Numeric Length_of_Stay in Fact_Encounter
   Source: dbo.LI_SPARCS_2015_25_Inpatient (Length_of_Stay)
   Fact:   dbo.Fact_Encounter (Length_of_Stay_Int)
   ========================================================== */

--------------------------------------------------------------
-- 0A. Ensure Length_of_Stay_Int exists in the FACT table
--------------------------------------------------------------
/* WHAT:
      Add Length_of_Stay_Int to Fact_Encounter if missing.
   WHY:
      We need a numeric LOS field in the fact for outlier analysis.
*/
IF COL_LENGTH('dbo.Fact_Encounter', 'Length_of_Stay_Int') IS NULL
BEGIN
    ALTER TABLE dbo.Fact_Encounter
    ADD Length_of_Stay_Int INT;

    PRINT '✔ Length_of_Stay_Int column created on Fact_Encounter.';
END
ELSE
BEGIN
    PRINT 'ℹ Length_of_Stay_Int already exists on Fact_Encounter — no structure change.';
END;
GO

--------------------------------------------------------------
-- 0B. Populate Fact_Encounter.Length_of_Stay_Int from source
--------------------------------------------------------------
/* WHAT:
      Sync LOS from the raw SPARCS table into the fact table,
      converting from text to INT on the fly.
   WHY:
      Keeps the fact table aligned with the original dataset.
*/
UPDATE f
SET f.Length_of_Stay_Int = TRY_CAST(s.Length_of_Stay AS INT)
FROM dbo.Fact_Encounter f
JOIN dbo.LI_SPARCS_2015_25_Inpatient s
    ON f.Encounter_ID = s.Encounter_ID;

PRINT '✔ Fact_Encounter.Length_of_Stay_Int populated from LI_SPARCS_2015_25_Inpatient.Length_of_Stay.';
GO



/* ==========================================================
   04.7 — Outlier & Anomaly Scan (Length_of_Stay-based)
   Tables:
     - Source: dbo.LI_SPARCS_2015_25_Inpatient
     - Fact:   dbo.Fact_Encounter
   Assumptions:
     - Length_of_Stay is stored as text in the source table.
     - Value '120+' was already cleaned to '120'.
     - Encounter_ID links source and fact.
   ========================================================== */


--------------------------------------------------------------
-- 1. Z-Score Outlier Scan (±3 SD)
--------------------------------------------------------------
/* WHAT:
      Compute Z-scores for LOS, Total_Charges, and Total_Costs.
   WHY:
      Flags statistical anomalies often linked to coding issues,
      rare clinical events, or billing irregularities.
*/
WITH Stats AS (
    SELECT 
        AVG(Length_of_Stay_Int * 1.0) AS Avg_LOS,
        STDEV(Length_of_Stay_Int * 1.0) AS SD_LOS,
        AVG(Total_Charges * 1.0)        AS Avg_Charges,
        STDEV(Total_Charges * 1.0)      AS SD_Charges,
        AVG(Total_Costs * 1.0)          AS Avg_Costs,
        STDEV(Total_Costs * 1.0)        AS SD_Costs
    FROM dbo.Fact_Encounter
),
Z AS (
    SELECT
        f.Encounter_ID,

        f.Length_of_Stay_Int,
        (f.Length_of_Stay_Int - s.Avg_LOS)      / NULLIF(s.SD_LOS, 0)      AS Z_LOS,

        f.Total_Charges,
        (f.Total_Charges     - s.Avg_Charges)   / NULLIF(s.SD_Charges, 0)  AS Z_Charges,

        f.Total_Costs,
        (f.Total_Costs       - s.Avg_Costs)     / NULLIF(s.SD_Costs, 0)    AS Z_Costs
    FROM dbo.Fact_Encounter f
    CROSS JOIN Stats s
)
SELECT *
FROM Z
WHERE ABS(Z_LOS)      > 3
   OR ABS(Z_Charges)  > 3
   OR ABS(Z_Costs)    > 3
ORDER BY ABS(Z_Charges) DESC;
GO


/* ----------------------------------------------------------
   WHAT: Summarize how many encounters are outliers on
         LOS vs Charges vs Costs.
   WHY: 9,190 rows is too many to eyeball; we want a profile.
----------------------------------------------------------- */

WITH Stats AS (
    SELECT 
        AVG(Length_of_Stay_Int * 1.0) AS Avg_LOS,
        STDEV(Length_of_Stay_Int * 1.0) AS SD_LOS,
        AVG(Total_Charges * 1.0)        AS Avg_Charges,
        STDEV(Total_Charges * 1.0)      AS SD_Charges,
        AVG(Total_Costs * 1.0)          AS Avg_Costs,
        STDEV(Total_Costs * 1.0)        AS SD_Costs
    FROM dbo.Fact_Encounter
),
Z AS (
    SELECT
        f.Encounter_ID,

        f.Length_of_Stay_Int,
        (f.Length_of_Stay_Int - s.Avg_LOS)      / NULLIF(s.SD_LOS, 0)      AS Z_LOS,

        f.Total_Charges,
        (f.Total_Charges     - s.Avg_Charges)   / NULLIF(s.SD_Charges, 0)  AS Z_Charges,

        f.Total_Costs,
        (f.Total_Costs       - s.Avg_Costs)     / NULLIF(s.SD_Costs, 0)    AS Z_Costs
    FROM dbo.Fact_Encounter f
    CROSS JOIN Stats s
)
SELECT
    COUNT(*) AS Total_Encounters,
    SUM(CASE WHEN ABS(Z_LOS)     > 3 THEN 1 ELSE 0 END) AS LOS_Z3_Count,
    SUM(CASE WHEN ABS(Z_Charges) > 3 THEN 1 ELSE 0 END) AS Charges_Z3_Count,
    SUM(CASE WHEN ABS(Z_Costs)   > 3 THEN 1 ELSE 0 END) AS Costs_Z3_Count,
    SUM(CASE WHEN (ABS(Z_LOS) > 3 OR ABS(Z_Charges) > 3 OR ABS(Z_Costs) > 3)
        THEN 1 ELSE 0 END) AS Any_Z3_Count
FROM Z;



/* Severe charge outliers: |Z_Charges| > 4 */

WITH Stats AS (
    SELECT 
        AVG(Length_of_Stay_Int * 1.0) AS Avg_LOS,
        STDEV(Length_of_Stay_Int * 1.0) AS SD_LOS,
        AVG(Total_Charges * 1.0)        AS Avg_Charges,
        STDEV(Total_Charges * 1.0)      AS SD_Charges,
        AVG(Total_Costs * 1.0)          AS Avg_Costs,
        STDEV(Total_Costs * 1.0)        AS SD_Costs
    FROM dbo.Fact_Encounter
),
Z AS (
    SELECT
        f.Encounter_ID,

        f.Length_of_Stay_Int,
        (f.Length_of_Stay_Int - s.Avg_LOS)      / NULLIF(s.SD_LOS, 0)      AS Z_LOS,

        f.Total_Charges,
        (f.Total_Charges     - s.Avg_Charges)   / NULLIF(s.SD_Charges, 0)  AS Z_Charges,

        f.Total_Costs,
        (f.Total_Costs       - s.Avg_Costs)     / NULLIF(s.SD_Costs, 0)    AS Z_Costs
    FROM dbo.Fact_Encounter f
    CROSS JOIN Stats s
)
SELECT
    COUNT(*) AS Total_Encounters,
    SUM(CASE WHEN ABS(Z_LOS)     > 4 THEN 1 ELSE 0 END) AS LOS_Z4_Count,
    SUM(CASE WHEN ABS(Z_Charges) > 4 THEN 1 ELSE 0 END) AS Charges_Z4_Count,
    SUM(CASE WHEN ABS(Z_Costs)   > 4 THEN 1 ELSE 0 END) AS Costs_Z4_Count,
    SUM(CASE WHEN (ABS(Z_LOS) > 4 OR ABS(Z_Charges) > 4 OR ABS(Z_Costs) > 4)
        THEN 1 ELSE 0 END) AS Any_Z4_Count
FROM Z;



--------------------------------------------------------------
-- 2. IQR Outlier Scan (1.5 × IQR Rule)
--------------------------------------------------------------
/* WHAT:
      Identify skewed-distribution outliers using the IQR method.
   WHY:
      Charges and costs in healthcare are heavily right-skewed;
      IQR is robust against extreme tails.
*/
WITH Percentiles AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Length_of_Stay_Int) OVER() AS Q1_LOS,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Length_of_Stay_Int) OVER() AS Q3_LOS,

        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Total_Charges) OVER()          AS Q1_Charges,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Total_Charges) OVER()          AS Q3_Charges,

        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Total_Costs) OVER()            AS Q1_Costs,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Total_Costs) OVER()            AS Q3_Costs
    FROM dbo.Fact_Encounter
),
Bounds AS (
    SELECT DISTINCT
        Q1_LOS, Q3_LOS, (Q3_LOS - Q1_LOS)                 AS IQR_LOS,
        Q1_Charges, Q3_Charges, (Q3_Charges - Q1_Charges) AS IQR_Charges,
        Q1_Costs, Q3_Costs, (Q3_Costs - Q1_Costs)         AS IQR_Costs
    FROM Percentiles
)
SELECT 
    f.Encounter_ID,
    f.Length_of_Stay_Int,
    f.Total_Charges,
    f.Total_Costs
FROM dbo.Fact_Encounter f
CROSS JOIN Bounds b
WHERE 
      f.Length_of_Stay_Int <  b.Q1_LOS      - 1.5 * b.IQR_LOS
   OR f.Length_of_Stay_Int >  b.Q3_LOS      + 1.5 * b.IQR_LOS
   OR f.Total_Charges      <  b.Q1_Charges  - 1.5 * b.IQR_Charges
   OR f.Total_Charges      >  b.Q3_Charges  + 1.5 * b.IQR_Charges
   OR f.Total_Costs        <  b.Q1_Costs    - 1.5 * b.IQR_Costs
   OR f.Total_Costs        >  b.Q3_Costs    + 1.5 * b.IQR_Costs
ORDER BY f.Total_Charges DESC;
GO


--------------------------------------------------------------
-- 3. Sanity Check — Impossible / Suspicious Values
--------------------------------------------------------------
/* WHAT:
      Hard-rule validation for impossible LOS, charges, or costs.
   WHY:
      Catches ETL defects and data-entry errors before KPI modeling.
*/
SELECT *
FROM dbo.Fact_Encounter
WHERE Length_of_Stay_Int <= 0         -- LOS cannot be 0 or negative
   OR Total_Charges <= 0              -- impossible in billing
   OR Total_Costs <= 0
   OR Total_Costs > Total_Charges     -- costs cannot exceed charges
ORDER BY Total_Costs DESC;
GO



