/* 
 STEP 02.2 – STANDARDIZE ZIP INFORMATION
 Reason:
 - Zip_Code_3_digits includes NULL and 'OOS'
 - For analysis we want clear buckets: In-state, Out-of-state, Unknown
*/

-- 1) Add a standardized ZIP category column
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ADD Zip3_Category NVARCHAR(20) NULL;

-- 2) Populate with simple, interpretable buckets
UPDATE dbo.LI_SPARCS_2015_25_Inpatient
SET Zip3_Category =
    CASE
        WHEN Zip_Code_3_digits IS NULL THEN 'Unknown'
        WHEN Zip_Code_3_digits = 'OOS' THEN 'Out-of-State'
        ELSE 'In-State Zip3'
    END;

/*
  3️) Sanity Check — Verify category distributions
  Why:
  - Ensures records were correctly bucketed
  - Detects unexpected values we may need to address later
  Output:
  - Count of each ZIP category label
*/
SELECT 
    Zip3_Category,
    COUNT(*) AS Record_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient
GROUP BY Zip3_Category
ORDER BY Record_Count DESC;