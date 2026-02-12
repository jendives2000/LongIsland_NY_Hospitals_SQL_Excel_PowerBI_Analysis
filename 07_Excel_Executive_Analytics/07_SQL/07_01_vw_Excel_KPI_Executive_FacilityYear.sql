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
    b.Discharge_Year,

    /* Severity Mix (use the view that actually defines these columns) */
    sm.Severity_Mix_Index,
    sm.Encounter_Count AS Severity_Encounter_Count,
    sm.Severity_1_Count,
    sm.Severity_2_Count,
    sm.Severity_3_Count,
    sm.Severity_4_Count,

    /* Payer Mix (pivoted from Payer_Share) */
    pmx.Commercial_Share,
    pmx.Medicaid_Share,
    pmx.Medicare_Share,
    pmx.SelfPay_Share,
    pmx.Other_Share,
    pmx.Payer_Encounter_Count_Sum,

    /* Unplanned Admissions (Encounter_Year in the KPI view) */
    ua.Encounter_Count_Total,
    ua.Encounter_Count_Unplanned,
    ua.Encounter_Count_Planned,
    ua.Unplanned_Admission_Rate,

    /* Disposition Outcomes (pivoted from category rows) */
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

    /* LOS, Mortality, Cost/Margin (your newly created Facility-Year views) */
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


-- Grain uniqueness check: if returns 0 rows: the integration view has the correct grain: exactly one row per Facility-Year.
SELECT Facility_Key, Discharge_Year, COUNT(*) AS c
FROM dbo.vw_Excel_KPI_Executive_FacilityYear
GROUP BY Facility_Key, Discharge_Year
HAVING COUNT(*) > 1;

-- Row-count sanity check: should return 23 (the number of Facility-Year combinations)
SELECT COUNT(*) AS Integration_RowCount
FROM dbo.vw_Excel_KPI_Executive_FacilityYear;

