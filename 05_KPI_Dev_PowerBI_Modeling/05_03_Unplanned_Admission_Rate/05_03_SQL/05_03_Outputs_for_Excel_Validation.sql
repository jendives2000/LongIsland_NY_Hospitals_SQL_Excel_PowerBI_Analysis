
-- Export for Excel: Encounter-grain rows (Granular all-rows output for Validation)
DECLARE @Year INT = 2015;

SELECT
    eat.Encounter_ID,
    eat.Facility_Name,
    eat.Encounter_Year,
    ISNULL(eat.AdmissionType_Std, '<<NULL>>') AS AdmissionType_Std
FROM #Encounter_AdmitType AS eat
WHERE eat.Encounter_Year = @Year
ORDER BY
    eat.Facility_Name, eat.Encounter_ID;


-- Export for Excel: Output to validate against: Facility-Year Unplanned totals
DECLARE @Year INT = 2015;

SELECT
    eat.Facility_Name,
    eat.Encounter_Year,
    COUNT(*) AS Total_Encounter_Count,
    SUM(CASE WHEN eat.AdmissionType_Std = 'Unplanned' THEN 1 ELSE 0 END) AS Unplanned_Encounter_Count,
    SUM(CASE WHEN eat.AdmissionType_Std IS NULL THEN 1 ELSE 0 END) AS Null_Std_Count,
    SUM(CASE WHEN eat.AdmissionType_Std IS NOT NULL AND eat.AdmissionType_Std <> 'Unplanned' THEN 1 ELSE 0 END) AS NonUnplanned_NonNull_Count
FROM #Encounter_AdmitType AS eat
WHERE eat.Encounter_Year = @Year
GROUP BY
    eat.Facility_Name,
    eat.Encounter_Year
ORDER BY
    eat.Facility_Name;