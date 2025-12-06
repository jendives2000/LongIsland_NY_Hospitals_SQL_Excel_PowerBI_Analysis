/* 
 STEP 02.3 – STANDARDIZE DEMOGRAPHIC PLACEHOLDERS
 Reason:
 - Race and Ethnicity fields contain inconsistent labels
   (“Unknown”, “Multi-ethnic”, “Not Span/Hispanic”, blanks, etc.)
 - These can distort equity and population health reporting
 - I create clean, analysis-ready versions while preserving the raw fields
*/

-- 1️) Add standardized Race and Ethnicity columns
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ADD Race_Std NVARCHAR(50) NULL,
    Ethnicity_Std NVARCHAR(50) NULL;

-- 2️) Standardize Race categories to simple industry-view buckets
UPDATE dbo.LI_SPARCS_2015_25_Inpatient
SET Race_Std =
    CASE
        WHEN Race IN ('White', 'Black/African American', 'Asian', 'American Indian/Alaska Native', 'Pacific Islander') THEN Race
        WHEN Race LIKE '%Multi%' THEN 'Multiracial'
        WHEN Race IS NULL OR Race IN ('Unknown', 'Other', '') THEN 'Unknown'
        ELSE 'Other'
    END;

-- 3️) Standardize Ethnicity into Hispanic / Non-Hispanic / Unknown
UPDATE dbo.LI_SPARCS_2015_25_Inpatient
SET Ethnicity_Std =
    CASE
        WHEN Ethnicity LIKE '%Hispanic%' THEN 'Hispanic'
        WHEN Ethnicity LIKE '%Not Span%' THEN 'Non-Hispanic'
        WHEN Ethnicity IS NULL OR Ethnicity IN ('Unknown', 'Other', '') THEN 'Unknown'
        ELSE 'Other'
    END;

/*
 4️) Sanity Check — Verify mapped distributions
 Why:
 - Ensures categories were remapped correctly
 - Reveals unexpected values that need rules added later
 Output:
 - Count of Race_Std and Ethnicity_Std records
*/
SELECT 'Race' AS Field, Race_Std AS Category, COUNT(*) AS Record_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient
GROUP BY Race_Std

UNION ALL

SELECT 'Ethnicity' AS Field, Ethnicity_Std AS Category, COUNT(*) AS Record_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient
GROUP BY Ethnicity_Std

ORDER BY Field, Record_Count DESC;
