/*==============================================================================
  View: dbo.vw_Excel_KPI_Executive_FacilityYear

  CHANGE:
    Add Peer Group attributes for Excel slicing while preserving 1 row per
    Facility-Year grain.

  IMPORTANT (grain safety):
    Bridge_Facility_PeerGroup is many-to-many by design. A direct join would
    duplicate Facility-Year rows. To prevent that, we pre-aggregate peer groups
    to a single row per Facility in PeerGroup_Facility.

    Output columns added:
      - PeerGroup_Name          (single label: exact name if 1, otherwise 'Multiple')
      - PeerGroup_List          (all peer group names concatenated for transparency)
      - PeerGroup_Count         (how many peer groups assigned to the facility)
==============================================================================*/

CREATE OR ALTER VIEW dbo.vw_Excel_KPI_Executive_FacilityYear
AS
WITH FacilityYear_Backbone AS (
    SELECT
        e.Facility_Key,
        d.[Year] AS Discharge_Year
    FROM dbo.Fact_Encounter e
    JOIN dbo.Dim_Date d
        ON d.Date_Key = e.Discharge_Date_Key
    GROUP BY
        e.Facility_Key,
        d.[Year]
),
/*-----------------------------------------------------------------------------
  Peer Group rollup to preserve Facility grain (avoid row duplication)
-----------------------------------------------------------------------------*/
PeerGroup_Facility AS (
    SELECT
        bpg.Facility_Key,
        COUNT(*) AS PeerGroup_Count,

        /* WHAT: Concatenated list for transparency in Excel.
           WHY: If a facility belongs to multiple peer groups, we expose the full
                list so the user understands why PeerGroup_Name may show 'Multiple'. */
        STRING_AGG(pg.PeerGroup_Name, ', ') WITHIN GROUP (ORDER BY pg.PeerGroup_Name) AS PeerGroup_List,

        /* WHAT: Single slicer-friendly label.
           WHY: Excel slicers expect a single category per row; 'Multiple' flags
                non-unique assignments without duplicating Facility-Year rows. */
        CASE
            WHEN COUNT(*) = 1 THEN MAX(pg.PeerGroup_Name)
            ELSE 'Multiple'
        END AS PeerGroup_Name
    FROM dbo.Bridge_Facility_PeerGroup bpg
    JOIN dbo.Dim_PeerGroup pg
        ON pg.PeerGroup_Key = bpg.PeerGroup_Key
    GROUP BY
        bpg.Facility_Key
),
PayerMix_FY AS (
    SELECT
        pm.Facility_Key,
        pm.Encounter_Year,
        MAX(CASE WHEN pm.Payment_Typology_Group = 'Commercial' THEN pm.Payer_Share ELSE 0 END) AS Commercial_Share,
        MAX(CASE WHEN pm.Payment_Typology_Group = 'Medicaid'   THEN pm.Payer_Share ELSE 0 END) AS Medicaid_Share,
        MAX(CASE WHEN pm.Payment_Typology_Group = 'Medicare'   THEN pm.Payer_Share ELSE 0 END) AS Medicare_Share,
        MAX(CASE WHEN pm.Payment_Typology_Group = 'Self-Pay'   THEN pm.Payer_Share ELSE 0 END) AS SelfPay_Share,
        MAX(CASE WHEN pm.Payment_Typology_Group = 'Other'      THEN pm.Payer_Share ELSE 0 END) AS Other_Share,
        SUM(pm.Encounter_Count) AS Payer_Encounter_Count_Sum
    FROM dbo.vw_KPI_PayerMix_FacilityYear pm
    GROUP BY
        pm.Facility_Key,
        pm.Encounter_Year
),
Disposition_FY AS (
    SELECT
        dx.Facility_Key,
        dx.Discharge_Year,

        SUM(CASE WHEN dx.Standardized_Disposition_Category LIKE '%Home%' THEN dx.Disposition_Encounter_Count ELSE 0 END) AS Home_Count,
        SUM(CASE WHEN dx.Standardized_Disposition_Category LIKE '%Skilled%'
                   OR dx.Standardized_Disposition_Category LIKE '%Rehab%'
                   OR dx.Standardized_Disposition_Category LIKE '%Nursing%'
                 THEN dx.Disposition_Encounter_Count ELSE 0 END) AS PostAcute_Count,
        SUM(CASE WHEN dx.Standardized_Disposition_Category LIKE '%Transfer%' THEN dx.Disposition_Encounter_Count ELSE 0 END) AS AcuteTransfer_Count,
        SUM(CASE WHEN dx.Standardized_Disposition_Category LIKE '%Death%'
                   OR dx.Standardized_Disposition_Category LIKE '%Expired%'
                   OR dx.Standardized_Disposition_Category LIKE '%Died%'
                 THEN dx.Disposition_Encounter_Count ELSE 0 END) AS Expired_Count,
        SUM(CASE WHEN dx.Standardized_Disposition_Category LIKE '%Unknown%' THEN dx.Disposition_Encounter_Count ELSE 0 END) AS OtherUnknown_Count,

        SUM(CASE WHEN dx.Standardized_Disposition_Category LIKE '%Home%' THEN dx.Disposition_Encounter_Share ELSE 0 END) AS Home_Share,
        SUM(CASE WHEN dx.Standardized_Disposition_Category LIKE '%Skilled%'
                   OR dx.Standardized_Disposition_Category LIKE '%Rehab%'
                   OR dx.Standardized_Disposition_Category LIKE '%Nursing%'
                 THEN dx.Disposition_Encounter_Share ELSE 0 END) AS PostAcute_Share,
        SUM(CASE WHEN dx.Standardized_Disposition_Category LIKE '%Transfer%' THEN dx.Disposition_Encounter_Share ELSE 0 END) AS AcuteTransfer_Share,
        SUM(CASE WHEN dx.Standardized_Disposition_Category LIKE '%Death%'
                   OR dx.Standardized_Disposition_Category LIKE '%Expired%'
                   OR dx.Standardized_Disposition_Category LIKE '%Died%'
                 THEN dx.Disposition_Encounter_Share ELSE 0 END) AS Expired_Share,
        SUM(CASE WHEN dx.Standardized_Disposition_Category LIKE '%Unknown%' THEN dx.Disposition_Encounter_Share ELSE 0 END) AS OtherUnknown_Share,

        SUM(dx.Disposition_Encounter_Count) AS Disposition_Total_Encounters
    FROM dbo.vw_KPI_DispositionOutcomes_FacilityYear dx
    GROUP BY
        dx.Facility_Key,
        dx.Discharge_Year
)
SELECT
    b.Facility_Key,
    f.Facility_Name,

    /* Peer Group context for Excel slicing */
    pgf.PeerGroup_Name,
    pgf.PeerGroup_Count,
    pgf.PeerGroup_List,

    b.Discharge_Year,

    /* Severity Mix */
    sm.Severity_Mix_Index,
    sm.Encounter_Count AS Severity_Encounter_Count,
    sm.Severity_1_Count,
    sm.Severity_2_Count,
    sm.Severity_3_Count,
    sm.Severity_4_Count,

    /* Payer Mix */
    pmx.Commercial_Share,
    pmx.Medicaid_Share,
    pmx.Medicare_Share,
    pmx.SelfPay_Share,
    pmx.Other_Share,
    pmx.Payer_Encounter_Count_Sum,

    /* Unplanned Admissions */
    ua.Encounter_Count_Total,
    ua.Encounter_Count_Unplanned,
    ua.Encounter_Count_Planned,
    ua.Unplanned_Admission_Rate,

    /* Disposition Outcomes */
    dx.Home_Count,
    dx.PostAcute_Count,
    dx.AcuteTransfer_Count,
    dx.Expired_Count,
    dx.OtherUnknown_Count,
    dx.Home_Share,
    dx.PostAcute_Share,
    dx.AcuteTransfer_Share,
    dx.Expired_Share,
    dx.OtherUnknown_Share,
    dx.Disposition_Total_Encounters,

    /* LOS, Mortality, Cost/Margin */
    los.Avg_LOS,
    los.Min_LOS,
    los.Max_LOS,
    mort.Death_Count,
    mort.Mortality_Rate,
    cost.Avg_MCost,
    cost.Margin_Pressure_Ratio,
    cost.NegMargin_Rate,
    cost.Total_Costs,
    cost.Total_Charges

FROM FacilityYear_Backbone b
JOIN dbo.Dim_Facility f
    ON f.Facility_Key = b.Facility_Key

LEFT JOIN PeerGroup_Facility pgf
    ON pgf.Facility_Key = b.Facility_Key

LEFT JOIN dbo.vw_KPI_05_01_SeverityMix_FacilityYear sm
    ON sm.Facility_Key = b.Facility_Key
   AND sm.Discharge_Year = b.Discharge_Year

LEFT JOIN PayerMix_FY pmx
    ON pmx.Facility_Key = b.Facility_Key
   AND pmx.Encounter_Year = b.Discharge_Year

LEFT JOIN dbo.vw_KPI_UnplannedAdmissions_FacilityYear ua
    ON ua.Facility_Key = b.Facility_Key
   AND ua.Encounter_Year = b.Discharge_Year

LEFT JOIN Disposition_FY dx
    ON dx.Facility_Key = b.Facility_Key
   AND dx.Discharge_Year = b.Discharge_Year

LEFT JOIN dbo.vw_KPI_LOS_FacilityYear los
    ON los.Facility_Key = b.Facility_Key
   AND los.Discharge_Year = b.Discharge_Year

LEFT JOIN dbo.vw_KPI_Mortality_FacilityYear mort
    ON mort.Facility_Key = b.Facility_Key
   AND mort.Discharge_Year = b.Discharge_Year

LEFT JOIN dbo.vw_KPI_CostPerCase_FacilityYear cost
    ON cost.Facility_Key = b.Facility_Key
   AND cost.Discharge_Year = b.Discharge_Year;
GO

/* Grain uniqueness check: should return 0 rows */
SELECT Facility_Key, Discharge_Year, COUNT(*) AS c
FROM dbo.vw_Excel_KPI_Executive_FacilityYear
GROUP BY Facility_Key, Discharge_Year
HAVING COUNT(*) > 1;

/* Row-count sanity check */
SELECT COUNT(*) AS Integration_RowCount
FROM dbo.vw_Excel_KPI_Executive_FacilityYear;



-- Check: Does every facility have a peer group? Why: Excel slicers must not have NULL peer groups unless intentionally allowed. Should return 0 rows
SELECT
    f.Facility_Key,
    f.Facility_Name,
    COUNT(bpg.PeerGroup_Key) AS PeerGroup_Assignments
FROM dbo.Dim_Facility f
LEFT JOIN dbo.Bridge_Facility_PeerGroup bpg
    ON f.Facility_Key = bpg.Facility_Key
GROUP BY
    f.Facility_Key,
    f.Facility_Name
HAVING COUNT(bpg.PeerGroup_Key) = 0;

-- Check: Are any facilities assigned to multiple peer groups? Why: Multiple assignments can break one-row-per-facility grain. Should return 0 rows
SELECT
    bpg.Facility_Key,
    f.Facility_Name,
    COUNT(*) AS PeerGroup_Count
FROM dbo.Bridge_Facility_PeerGroup bpg
JOIN dbo.Dim_Facility f
    ON f.Facility_Key = bpg.Facility_Key
GROUP BY
    bpg.Facility_Key,
    f.Facility_Name
HAVING COUNT(*) > 1
ORDER BY PeerGroup_Count DESC;

-- Check: Is the bridge table valid (no orphan keys)? Why: Prevent broken joins. Should return 0 rows
-- Orphan Facility Keys
SELECT *
FROM dbo.Bridge_Facility_PeerGroup bpg
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Dim_Facility f
    WHERE f.Facility_Key = bpg.Facility_Key
);

-- Orphan PeerGroup Keys
SELECT *
FROM dbo.Bridge_Facility_PeerGroup bpg
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Dim_PeerGroup pg
    WHERE pg.PeerGroup_Key = bpg.PeerGroup_Key
);


-- Check: Does the integration view still preserve grain? Should return 0 rows
SELECT
    Facility_Key,
    Discharge_Year,
    COUNT(*) AS Row_Count
FROM dbo.vw_Excel_KPI_Executive_FacilityYear
GROUP BY
    Facility_Key,
    Discharge_Year
HAVING COUNT(*) > 1;
