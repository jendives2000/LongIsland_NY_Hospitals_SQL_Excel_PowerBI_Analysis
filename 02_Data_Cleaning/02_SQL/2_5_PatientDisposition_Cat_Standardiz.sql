/* 
 STEP 02.5 – GROUP Patient_Disposition
 Reason:
 - Raw patient disposition has many detailed categories
 - For reporting, we want broader groups (Home, SNF/Rehab, Death, Other, Unknown)
*/

-- 1️) Add grouped disposition column
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ADD Patient_Disposition_Grouped NVARCHAR(50) NULL;

-- 2️) Map detailed values to broad, interpretable groups
UPDATE dbo.LI_SPARCS_2015_25_Inpatient
SET Patient_Disposition_Grouped =
    CASE
        WHEN Patient_Disposition IN ('Home or Self Care', 'Home') THEN 'Home'
        WHEN Patient_Disposition LIKE '%Skilled Nursing%' THEN 'Skilled Nursing / Rehab'
        WHEN Patient_Disposition LIKE '%Rehab%' THEN 'Skilled Nursing / Rehab'
        WHEN Patient_Disposition LIKE '%Expired%' 
          OR Patient_Disposition LIKE '%Died%' THEN 'Death'
        WHEN Patient_Disposition IS NULL OR Patient_Disposition = '' THEN 'Unknown'
        ELSE 'Other'
    END;

-- 3️) Sanity check – verify grouped disposition distribution
--    Why:
--    - Ensures all records are bucketed into meaningful groups
--    - Helps spot unexpected values still falling into 'Other'
SELECT 
    Patient_Disposition_Grouped,
    COUNT(*) AS Record_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient
GROUP BY Patient_Disposition_Grouped
ORDER BY Record_Count DESC;
