--------------------------------------------------------------------------------
-- KPI 05.02 — Payer Mix & Reimbursement Risk
-- Updated for README + Excel validation + FULL granular output
-- Pivot-safe KPI output: forces payer groups (incl. 'Other') to exist for all
-- Facility-Year combinations, returning 0 instead of blank/NULL.
--------------------------------------------------------------------------------

/* ============================================================================
   1) Encounter-level validation view (for Excel)
   ============================================================================ */
CREATE OR ALTER VIEW dbo.vw_KPI_05_02_PayerMix_Encounter
AS
SELECT
    fe.Encounter_ID,
    fe.Facility_Key,
    f.Facility_Name,
    d.[Year] AS Discharge_Year,

    /* 
       Force payer group to a non-empty value.
       Blank, whitespace, or NULL → '0'
       (Excel-friendly categorical placeholder)
    */
    COALESCE(
        NULLIF(LTRIM(RTRIM(dp.Payment_Typology_Group)), ''),
        '0'
    ) AS Payment_Typology_Group,

    /* Force numeric stability for Excel */
    COALESCE(fe.Total_Charges, 0) AS Total_Charges,
    COALESCE(fe.Total_Costs,   0) AS Total_Costs,

    /* Deterministic flag: always 0 or 1 */
    CASE
        WHEN COALESCE(fe.Total_Costs, 0) > COALESCE(fe.Total_Charges, 0)
        THEN 1
        ELSE 0
    END AS Negative_Margin_Flag

FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Facility AS f
    ON fe.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS d
    ON fe.Discharge_Date_Key = d.Date_Key
LEFT JOIN dbo.Dim_Payer AS dp
    ON fe.Payer_Key = dp.Payer_Key
WHERE
    fe.Encounter_ID IS NOT NULL
    AND d.[Year] IS NOT NULL;
GO


-- ✅ OUTPUT
SELECT
    Encounter_ID,
    Facility_Key,
    Facility_Name,
    Discharge_Year,
    Payment_Typology_Group,
    Total_Charges,
    Total_Costs,
    Negative_Margin_Flag
FROM dbo.vw_KPI_05_02_PayerMix_Encounter
ORDER BY
    Discharge_Year,
    Facility_Name,
    Payment_Typology_Group,
    Encounter_ID;
GO


--------------------------------------------------------------------------------
-- KPI 05.02 — Payer Mix & Reimbursement Risk
--
-- CHANGE REQUEST (Excel validation / Pivot safety):
--   Update dbo.vw_KPI_PayerMix_FacilityYear so that payer groups (incl. 'Other')
--   exist for every Facility-Year even when Encounter_Count = 0, returning 0s
--   instead of missing combinations (which Excel shows as blank cells).
--
-- KEY IDEA:
--   Build a payer-group scaffold (Commercial/Medicaid/Medicare/Other/Self-Pay)
--   and CROSS JOIN it to Facility-Year universe, then LEFT JOIN aggregates and
--   COALESCE missing measures to 0.
--------------------------------------------------------------------------------


/* ============================================================================
   1) Encounter-level validation view (kept as the audit / Excel extract source)
   ----------------------------------------------------------------------------
   IMPORTANT:
   - We normalize payer group blanks/NULLs to 'Other' so Excel never sees blanks.
   - This does NOT create a new payer group; it just prevents empty labels.
   ============================================================================ */
CREATE OR ALTER VIEW dbo.vw_KPI_05_02_PayerMix_Encounter
AS
SELECT
    fe.Encounter_ID,
    fe.Facility_Key,
    f.Facility_Name,
    d.[Year] AS Discharge_Year,

    -- WHAT: Standardized payer group, never blank.
    -- WHY: Blank categories create pivot artifacts and break validation groupings.
    COALESCE(NULLIF(LTRIM(RTRIM(dp.Payment_Typology_Group)), ''), 'Other') AS Payment_Typology_Group,

    -- WHAT: Financial inputs (default NULLs to 0 to stabilize Excel math).
    -- WHY: Excel validations behave best with deterministic numeric values.
    COALESCE(fe.Total_Charges, 0) AS Total_Charges,
    COALESCE(fe.Total_Costs,   0) AS Total_Costs,

    -- KPI helper: Negative margin flag (always 0/1)
    CASE
        WHEN COALESCE(fe.Total_Costs, 0) > COALESCE(fe.Total_Charges, 0) THEN 1
        ELSE 0
    END AS Negative_Margin_Flag

FROM dbo.Fact_Encounter AS fe
INNER JOIN dbo.Dim_Facility AS f
    ON fe.Facility_Key = f.Facility_Key
INNER JOIN dbo.Dim_Date AS d
    ON fe.Discharge_Date_Key = d.Date_Key
LEFT JOIN dbo.Dim_Payer AS dp
    ON fe.Payer_Key = dp.Payer_Key
WHERE
    fe.Encounter_ID IS NOT NULL
    AND d.[Year] IS NOT NULL;
GO


/* ============================================================================
   2) KPI view (Facility-Year-PayerGroup) — Pivot-safe version
   ----------------------------------------------------------------------------
   WHAT:
     Produce Facility-Year-PayerGroup rows for ALL payer groups, even if a payer
     group has 0 encounters at that facility-year.
   WHY:
     Excel PivotTables show blanks when the source has no row for a combination.
     This scaffold forces the row to exist and returns 0s instead.
   ============================================================================ */
CREATE OR ALTER VIEW dbo.vw_KPI_PayerMix_FacilityYear
AS
WITH payer_groups AS (
    -- Canonical payer groups used in the README and expected in Excel columns
    SELECT v.Payment_Typology_Group
    FROM (VALUES
        ('Commercial'),
        ('Medicaid'),
        ('Medicare'),
        ('Other'),
        ('Self-Pay')
    ) v(Payment_Typology_Group)
),
facility_year AS (
    -- Universe of Facility-Year combinations (ALL hospitals present in data)
    SELECT DISTINCT
        e.Facility_Key,
        e.Facility_Name,
        e.Discharge_Year
    FROM dbo.vw_KPI_05_02_PayerMix_Encounter e
),
agg AS (
    -- Aggregate the encounter-level records to payer-group grain
    SELECT
        e.Facility_Key,
        e.Facility_Name,
        e.Discharge_Year,
        e.Payment_Typology_Group,

        COUNT_BIG(*) AS Encounter_Count,

        -- Sums for stable ratio computations
        SUM(CAST(e.Total_Costs   AS DECIMAL(18,4))) AS Total_Costs,
        SUM(CAST(e.Total_Charges AS DECIMAL(18,4))) AS Total_Charges,

        -- Negative margin count
        SUM(e.Negative_Margin_Flag) AS Negative_Margin_Encounter_Count
    FROM dbo.vw_KPI_05_02_PayerMix_Encounter e
    WHERE e.Payment_Typology_Group IN ('Commercial','Medicaid','Medicare','Other','Self-Pay')
    GROUP BY
        e.Facility_Key,
        e.Facility_Name,
        e.Discharge_Year,
        e.Payment_Typology_Group
),
facility_year_totals AS (
    -- Denominator for payer share within facility-year
    SELECT
        e.Facility_Key,
        e.Discharge_Year,
        COUNT_BIG(*) AS FacilityYear_TotalEncounters
    FROM dbo.vw_KPI_05_02_PayerMix_Encounter e
    WHERE e.Payment_Typology_Group IN ('Commercial','Medicaid','Medicare','Other','Self-Pay')
    GROUP BY e.Facility_Key, e.Discharge_Year
)
SELECT
    fy.Facility_Key,
    fy.Facility_Name,
    fy.Discharge_Year AS Encounter_Year,
    pg.Payment_Typology_Group,

    -- KPI: Encounter counts (force 0 when missing)
    COALESCE(a.Encounter_Count, 0) AS Encounter_Count,

    -- KPI: Share of encounters within facility-year (force 0 when missing)
    CAST(
        COALESCE(a.Encounter_Count, 0) * 1.0
        / NULLIF(fyt.FacilityYear_TotalEncounters, 0)
        AS DECIMAL(10,4)
    ) AS Payer_Share,

    -- KPI: Avg costs/charges (return 0 if no encounters for this payer group)
    CAST(
        CASE WHEN COALESCE(a.Encounter_Count, 0) = 0 THEN 0
             ELSE a.Total_Charges / NULLIF(COALESCE(a.Encounter_Count, 0), 0)
        END AS DECIMAL(18,4)
    ) AS Avg_Total_Charges,

    CAST(
        CASE WHEN COALESCE(a.Encounter_Count, 0) = 0 THEN 0
             ELSE a.Total_Costs / NULLIF(COALESCE(a.Encounter_Count, 0), 0)
        END AS DECIMAL(18,4)
    ) AS Avg_Total_Costs,

    -- KPI: Cost-to-charge ratio (return 0 if charges are 0)
    CAST(
        CASE WHEN COALESCE(a.Total_Charges, 0) = 0 THEN 0
             ELSE COALESCE(a.Total_Costs, 0) / NULLIF(COALESCE(a.Total_Charges, 0), 0)
        END AS DECIMAL(18,4)
    ) AS Cost_To_Charge_Ratio,

    -- KPI: Negative margin count and rate (force 0 when missing)
    COALESCE(a.Negative_Margin_Encounter_Count, 0) AS Negative_Margin_Encounter_Count,

    CAST(
        CASE WHEN COALESCE(a.Encounter_Count, 0) = 0 THEN 0
             ELSE COALESCE(a.Negative_Margin_Encounter_Count, 0) * 1.0
                  / NULLIF(COALESCE(a.Encounter_Count, 0), 0)
        END AS DECIMAL(10,4)
    ) AS Negative_Margin_Rate

FROM facility_year fy
CROSS JOIN payer_groups pg
LEFT JOIN agg a
    ON  fy.Facility_Key = a.Facility_Key
    AND fy.Discharge_Year = a.Discharge_Year
    AND pg.Payment_Typology_Group = a.Payment_Typology_Group
LEFT JOIN facility_year_totals fyt
    ON  fy.Facility_Key = fyt.Facility_Key
    AND fy.Discharge_Year = fyt.Discharge_Year;
GO


--------------------------------------------------------------------------------
-- OPTIONAL: Quick proof that 'Other' now exists everywhere as 0 when missing
--------------------------------------------------------------------------------
-- Example: show Facility-Year rows where Other is present with 0 encounters
SELECT TOP (200)
    Facility_Name,
    Encounter_Year,
    Payment_Typology_Group,
    Encounter_Count,
    Negative_Margin_Encounter_Count
FROM dbo.vw_KPI_PayerMix_FacilityYear
WHERE Payment_Typology_Group = 'Other'
  AND Encounter_Count = 0
ORDER BY Encounter_Year, Facility_Name;
GO



--------------------------------------------------------------------------------
-- SANITY CHECK QUERIES
--------------------------------------------------------------------------------
/* ============================================================================
   1) Payer group coverage (ensure nothing is silently dropped)
   ----------------------------------------------------------------------------
   WHAT:
     Count encounter volume by payer group from the encounter-level view.
   WHY:
     Confirms the payer group mapping is populated and stable for Excel validation.
     Also confirms blanks are being routed to 'Other' (no empty categories).
   ============================================================================ */
SELECT
    e.Payment_Typology_Group,
    COUNT_BIG(*) AS Encounter_Count
FROM dbo.vw_KPI_05_02_PayerMix_Encounter AS e
WHERE e.Payment_Typology_Group IN ('Commercial','Medicaid','Medicare','Other','Self-Pay')
GROUP BY e.Payment_Typology_Group
ORDER BY e.Payment_Typology_Group;
GO


/* ============================================================================
   2) Negative-margin logic (pivot-safe raw counts)
   ----------------------------------------------------------------------------
   WHAT:
     Facility-Year-PayerGroup counts INCLUDING payer groups with zero encounters,
     so Excel sees 0 instead of blank.
   WHY:
     Grouping raw encounter rows cannot produce a row for a missing category.
     The scaffold forces the category row to exist.
   ============================================================================ */
WITH payer_groups AS (
    SELECT v.Payment_Typology_Group
    FROM (VALUES
        ('Commercial'),
        ('Medicaid'),
        ('Medicare'),
        ('Other'),
        ('Self-Pay')
    ) v(Payment_Typology_Group)
),
facility_year AS (
    SELECT DISTINCT
        e.Facility_Key,
        e.Facility_Name,
        e.Discharge_Year
    FROM dbo.vw_KPI_05_02_PayerMix_Encounter AS e
),
agg AS (
    SELECT
        e.Facility_Key,
        e.Facility_Name,
        e.Discharge_Year,
        e.Payment_Typology_Group,
        COUNT_BIG(*) AS Encounter_Count,
        SUM(e.Negative_Margin_Flag) AS Negative_Margin_Encounter_Count
    FROM dbo.vw_KPI_05_02_PayerMix_Encounter AS e
    WHERE e.Payment_Typology_Group IN ('Commercial','Medicaid','Medicare','Other','Self-Pay')
    GROUP BY
        e.Facility_Key,
        e.Facility_Name,
        e.Discharge_Year,
        e.Payment_Typology_Group
)
SELECT
    fy.Facility_Name,
    fy.Discharge_Year,
    pg.Payment_Typology_Group,
    COALESCE(a.Encounter_Count, 0) AS Encounter_Count,
    COALESCE(a.Negative_Margin_Encounter_Count, 0) AS Negative_Margin_Encounter_Count
FROM facility_year fy
CROSS JOIN payer_groups pg
LEFT JOIN agg a
    ON  fy.Facility_Key = a.Facility_Key
    AND fy.Discharge_Year = a.Discharge_Year
    AND pg.Payment_Typology_Group = a.Payment_Typology_Group
ORDER BY
    fy.Facility_Name,
    fy.Discharge_Year,
    pg.Payment_Typology_Group;
GO



/* ============================================================================
   3) KPI reconciliation (sum of payer-group counts = total encounters per facility-year)
   ----------------------------------------------------------------------------
   IMPORTANT CHANGE:
     Because dbo.vw_KPI_PayerMix_FacilityYear is now pivot-safe (it includes
     rows with Encounter_Count = 0), we validate reconciliation by comparing:

       Sum(Encounter_Count across payer groups)  ==  Total encounters in encounter view

   WHY:
     Confirms the CROSS JOIN scaffold did not introduce duplication and that
     the KPI view remains mathematically consistent with the encounter base.
   ============================================================================ */
WITH kpi_sum AS (
    SELECT
        k.Facility_Key,
        k.Facility_Name,
        k.Encounter_Year,
        SUM(k.Encounter_Count) AS Sum_Of_PayerGroup_Encounters
    FROM dbo.vw_KPI_PayerMix_FacilityYear AS k
    WHERE k.Payment_Typology_Group IN ('Commercial','Medicaid','Medicare','Other','Self-Pay')
    GROUP BY
        k.Facility_Key,
        k.Facility_Name,
        k.Encounter_Year
),
enc_total AS (
    SELECT
        e.Facility_Key,
        e.Facility_Name,
        e.Discharge_Year AS Encounter_Year,
        COUNT_BIG(*) AS EncounterLevel_TotalEncounters
    FROM dbo.vw_KPI_05_02_PayerMix_Encounter AS e
    WHERE e.Payment_Typology_Group IN ('Commercial','Medicaid','Medicare','Other','Self-Pay')
    GROUP BY
        e.Facility_Key,
        e.Facility_Name,
        e.Discharge_Year
)
SELECT
    ks.Facility_Name,
    ks.Encounter_Year,
    ks.Sum_Of_PayerGroup_Encounters,
    et.EncounterLevel_TotalEncounters,
    (ks.Sum_Of_PayerGroup_Encounters - et.EncounterLevel_TotalEncounters) AS Delta
FROM kpi_sum ks
INNER JOIN enc_total et
    ON  ks.Facility_Key = et.Facility_Key
    AND ks.Encounter_Year = et.Encounter_Year
ORDER BY
    ABS(ks.Sum_Of_PayerGroup_Encounters - et.EncounterLevel_TotalEncounters) DESC,
    ks.Facility_Name,
    ks.Encounter_Year;
GO



/* ============================================================================
   Step E — KPI output for Excel validation (ALL facilities)
   ----------------------------------------------------------------------------
   WHAT:
     Full KPI result set across all facilities, years, and payer groups.
   WHY:
     This is the canonical KPI output against which Excel calculations
     (counts, rates, shares, averages, CTR) are validated.
   ============================================================================ */

SELECT
    k.Facility_Name,
    k.Encounter_Year,
    k.Payment_Typology_Group,
    k.Encounter_Count,
    k.Negative_Margin_Encounter_Count,
    k.Payer_Share,
    k.Avg_Total_Charges,
    k.Avg_Total_Costs,
    k.Cost_To_Charge_Ratio,
    k.Negative_Margin_Rate
FROM dbo.vw_KPI_PayerMix_FacilityYear AS k
ORDER BY
    k.Encounter_Year,
    k.Facility_Name,
    CASE k.Payment_Typology_Group
        WHEN 'Commercial' THEN 1
        WHEN 'Medicaid'   THEN 2
        WHEN 'Medicare'   THEN 3
        WHEN 'Other'      THEN 4
        WHEN 'Self-Pay'   THEN 5
        ELSE 99
    END;
GO










