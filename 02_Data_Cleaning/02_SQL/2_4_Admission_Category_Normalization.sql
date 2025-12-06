/* 
 STEP 02.4 – STANDARDIZE Type_of_Admission
 Reason:
 - Original labels may mix 'Emergency', 'Urgent', 'Elective', etc.
 - We create a simplified, analysis-friendly bucket field
*/

-- 1️) Add standardized column
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ADD Type_of_Admission_Std NVARCHAR(20) NULL;

-- 2️) Map original values to a small, consistent set
UPDATE dbo.LI_SPARCS_2015_25_Inpatient
SET Type_of_Admission_Std =
    CASE
        WHEN Type_of_Admission IN ('Emergency', 'EMERGENCY', 'Urgent') THEN 'Unplanned'
        WHEN Type_of_Admission IN ('Elective') THEN 'Elective'
        WHEN Type_of_Admission IS NULL OR Type_of_Admission = '' THEN 'Unknown'
        ELSE 'Other'
    END;

-- 3️) Sanity check – verify distribution of the new standardized categories
--    Why:
--    - Confirms all rows were classified into one of the expected buckets
--    - Highlights if 'Other' is too large (meaning more mapping rules are needed)
SELECT 
    Type_of_Admission_Std,
    COUNT(*) AS Record_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient
GROUP BY Type_of_Admission_Std
ORDER BY Record_Count DESC;
