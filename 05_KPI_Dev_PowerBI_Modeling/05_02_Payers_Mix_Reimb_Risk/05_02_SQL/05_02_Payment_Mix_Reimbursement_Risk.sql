--------------------------------------------------------------------------------
-- STEP 05.02 - KPI: Payer Mix & Reimbursement Risk
-- File: 05_02_Payer_Mix_and_Reimbursement_Risk.sql
--
-- WHAT:
--   Define a KPI view that summarizes encounter volume, financial exposure,
--   and negative-margin risk across payer groups by facility and year.
--
-- WHY:
--   Payer mix directly affects hospital revenue stability. Understanding which
--   payer groups drive volume, cost, and losses is essential for financial
--   planning and contract negotiations.
--
-- DEPENDENCIES:
--   Fact table:
--     - dbo.Fact_Encounter
--       * Facility_Key
--       * Payer_Key
--       * Admission_Date_Key
--       * Total_Charges
--       * Total_Costs
--
--   Dimensions:
--     - dbo.Dim_Facility
--       * Facility_Key, Facility_Name
--     - dbo.Dim_Payer
--       * Payer_Key, Payment_Typology_Group
--     - dbo.Dim_Date
--       * Date_Key, Year
--------------------------------------------------------------------------------

IF OBJECT_ID('dbo.vw_KPI_PayerMix_FacilityYear', 'V') IS NOT NULL
BEGIN
    DROP VIEW dbo.vw_KPI_PayerMix_FacilityYear;
END;
GO

CREATE VIEW dbo.vw_KPI_PayerMix_FacilityYear
AS
WITH Payer_Clean AS (
    SELECT
        fe.Encounter_ID,              -- keep encounter grain for counting
        fe.Facility_Key,
        fe.Payer_Key,
        fe.Admission_Date_Key,        -- anchor for Encounter_Year
        fe.Total_Charges,
        fe.Total_Costs,

        -- WHAT:
        --   Standardized payer group label from Dim_Payer.
        --   If NULL, explicitly set to 'Unknown' so that no encounters are
        --   silently dropped due to missing group.
        --
        -- WHY:
        --   Ensures every encounter is included in the payer mix, even if
        --   classification is incomplete.
        ISNULL(dp.Payment_Typology_Group, 'Unknown') AS Payment_Typology_Group
    FROM dbo.Fact_Encounter AS fe
    INNER JOIN dbo.Dim_Payer AS dp
        ON fe.Payer_Key = dp.Payer_Key
)
SELECT
    f.Facility_Key,
    f.Facility_Name,
    d.Year                           AS Encounter_Year,
    pc.Payment_Typology_Group,

    -- WHAT: Total encounters for this Facility-Year-PayerGroup.
    -- WHY: Core volume metric to understand how many cases come from each payer.
    COUNT(*)                         AS Encounter_Count,

    -- WHAT: Share of encounters for each payer group within a facility-year.
    -- WHY: Shows concentration of volume and dependency on specific payer groups.
    CAST(COUNT(*) * 1.0
         / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY f.Facility_Key, d.Year), 0)
         AS DECIMAL(10,4))           AS Encounter_Share,

    -- WHAT: Average total charges and costs per encounter.
    -- WHY: Indicates price level and resource consumption per payer group.
    AVG(CAST(pc.Total_Charges AS DECIMAL(18,2))) AS Avg_Total_Charges,
    AVG(CAST(pc.Total_Costs  AS DECIMAL(18,2)))  AS Avg_Total_Costs,

    -- WHAT: Cost-to-charge ratio (CTR) per payer group.
    -- WHY: Helps compare cost structure and pricing across payer groups.
    CASE 
        WHEN SUM(pc.Total_Charges) = 0 THEN NULL
        ELSE CAST(SUM(pc.Total_Costs) * 1.0
                  / SUM(pc.Total_Charges) AS DECIMAL(10,4))
    END                              AS Cost_to_Charge_Ratio,

    -- WHAT: Count of negative-margin encounters (Total_Costs > Total_Charges).
    -- WHY: Highlights where the hospital is losing money by payer group.
    SUM(CASE WHEN pc.Total_Costs > pc.Total_Charges THEN 1 ELSE 0 END)
                                     AS Negative_Margin_Encounter_Count,

    -- WHAT: Rate of negative-margin encounters as a percentage of encounters.
    -- WHY: Quantifies margin pressure per payer group for finance/contracting.
    CAST(
        SUM(CASE WHEN pc.Total_Costs > pc.Total_Charges THEN 1 ELSE 0 END) * 1.0
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    )                                AS Negative_Margin_Rate

FROM Payer_Clean AS pc
INNER JOIN dbo.Dim_Facility AS f
    ON pc.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS d
    ON pc.Admission_Date_Key = d.Date_Key    -- define encounter year by admission
GROUP BY
    f.Facility_Key,
    f.Facility_Name,
    d.Year,
    pc.Payment_Typology_Group;
GO


--------------------------------------------------------------------------------
-- SANITY CHECK QUERIES
-- These are intended to be run manually in SSMS as part of KPI validation.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- SANITY CHECK 1: Payer group coverage
--
-- WHAT:
--   Review how many distinct payer groups exist and how many encounters
--   fall into each group, including 'Unknown'.
--
-- WHY:
--   Ensures that:
--     - Payment_Typology_Group is populated as expected.
--     - Any NULLs are correctly mapped to 'Unknown'.
--     - No major payer category is accidentally excluded.
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- SANITY CHECK 1 (SCOPED): Payer group distribution
--
-- WHAT:
--   Count encounters by Payment_Typology_Group for a single facility and year.
--
-- WHY:
--   Allows manual inspection of payer classification and ensures no encounters
--   are lost or misclassified before trusting the aggregated KPI view.
--------------------------------------------------------------------------------

SELECT
    ISNULL(dp.Payment_Typology_Group, 'Unknown') AS Payment_Typology_Group,
    COUNT(*) AS Encounter_Count
FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Payer AS dp
    ON fe.Payer_Key = dp.Payer_Key
INNER JOIN dbo.Dim_Facility AS f
    ON fe.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS d
    ON fe.Admission_Date_Key = d.Date_Key
WHERE
    d.Year = 2015
    AND f.Facility_Name = 'Peconic Bay Medical Center'   -- adjust as needed
GROUP BY
    ISNULL(dp.Payment_Typology_Group, 'Unknown')
ORDER BY
    Encounter_Count DESC;
GO



--------------------------------------------------------------------------------
-- SANITY CHECK 1 (GRANULAR): Encounter-level payer group mapping
--
-- WHAT:
--   Return encounter-level rows showing how each encounter maps to a
--   Payment_Typology_Group (including handling of NULL as 'Unknown').
--
-- WHY:
--   Lets you manually spot-check payer classification (no missing joins,
--   no unexpected NULLs) before trusting the aggregated payer-mix KPI.
--
-- HOW TO USE:
--   1) Start with ONE facility + ONE year (recommended) so the dataset is manageable.
--   2) Remove the Facility/Year filter only if you truly need full-volume export.
--------------------------------------------------------------------------------

SELECT
    fe.Encounter_ID,
    f.Facility_Name,
    d.Year AS Encounter_Year,

    fe.Payer_Key,
    dp.Payment_Typology_1,
    dp.Payment_Typology_Group,

    -- Explicitly show what the KPI view uses (NULL -> 'Unknown')
    ISNULL(dp.Payment_Typology_Group, 'Unknown') AS Payment_Typology_Group_Std,

    fe.Total_Charges,
    fe.Total_Costs,

    -- Optional: show the negative-margin flag at encounter level
    CASE WHEN fe.Total_Costs > fe.Total_Charges THEN 1 ELSE 0 END AS Negative_Margin_Flag

FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Facility AS f
    ON fe.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS d
    ON fe.Admission_Date_Key = d.Date_Key
INNER JOIN dbo.Dim_Payer AS dp
    ON fe.Payer_Key = dp.Payer_Key

WHERE
    d.Year = 2015
    AND f.Facility_Name = 'Peconic Bay Medical Center'  -- adjust to any one hospital

ORDER BY
    dp.Payment_Typology_Group,
    fe.Encounter_ID;



--------------------------------------------------------------------------------
-- SANITY CHECK 2: Negative-margin logic validation
--
-- WHAT:
--   Check how many encounters have Total_Costs > Total_Charges (negative margin)
--   at the raw encounter level, and compare with counts aggregated in the view.
--
-- WHY:
--   Confirms that the negative margin logic used in the KPI view matches the
--   underlying encounter-level data.
--------------------------------------------------------------------------------

-- a) Raw negative-margin counts per Facility-Year-PayerGroup
SELECT
    f.Facility_Name,
    d.Year AS Encounter_Year,
    ISNULL(dp.Payment_Typology_Group, 'Unknown') AS Payment_Typology_Group,
    COUNT(*) AS Negative_Margin_Encounter_Count
FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Facility AS f
    ON fe.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS d
    ON fe.Admission_Date_Key = d.Date_Key
INNER JOIN dbo.Dim_Payer AS dp
    ON fe.Payer_Key = dp.Payer_Key
WHERE fe.Total_Costs > fe.Total_Charges
GROUP BY
    f.Facility_Name,
    d.Year,
    ISNULL(dp.Payment_Typology_Group, 'Unknown')
ORDER BY
    f.Facility_Name,
    d.Year,
    Payment_Typology_Group;


-- b) KPI view negative-margin counts per Facility-Year-PayerGroup
SELECT
    Facility_Name,
    Encounter_Year,
    Payment_Typology_Group,
    Negative_Margin_Encounter_Count
FROM dbo.vw_KPI_PayerMix_FacilityYear
ORDER BY
    Facility_Name,
    Encounter_Year,
    Payment_Typology_Group;
GO


--------------------------------------------------------------------------------
-- SANITY CHECK 3: Encounter count reconciliation
--
-- WHAT:
--   Compare total encounter counts per Facility-Year between:
--     (1) Fact_Encounter joined to Dim_Payer + Dim_Date
--     (2) Aggregated KPI view
--
-- WHY:
--   Ensures the KPI view did not accidentally drop or duplicate encounters.
--------------------------------------------------------------------------------

-- a) Counts from the KPI view (sum over payer groups)
SELECT
    Facility_Name,
    Encounter_Year,
    SUM(Encounter_Count) AS View_Encounter_Count
FROM dbo.vw_KPI_PayerMix_FacilityYear
GROUP BY
    Facility_Name,
    Encounter_Year
ORDER BY
    Facility_Name,
    Encounter_Year;


-- b) Counts directly from the fact table
SELECT
    f.Facility_Name,
    d.Year AS Encounter_Year,
    COUNT(*) AS Fact_Encounter_Count
FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Facility AS f
    ON fe.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS d
    ON fe.Admission_Date_Key = d.Date_Key
INNER JOIN dbo.Dim_Payer AS dp
    ON fe.Payer_Key = dp.Payer_Key
GROUP BY
    f.Facility_Name,
    d.Year
ORDER BY
    f.Facility_Name,
    d.Year;
GO
