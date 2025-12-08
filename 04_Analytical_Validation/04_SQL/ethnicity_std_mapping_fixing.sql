/* Fix Ethnicity_Std mapping to correctly handle 'Not Span/Hispanic' */

UPDATE dbo.LI_SPARCS_2015_25_Inpatient
SET Ethnicity_Std =
    CASE
        -- 1) Explicit "Not Spanish/Hispanic" first
        WHEN Ethnicity LIKE 'Not Span/Hispanic%' THEN 'Non-Hispanic'

        -- 2) Then true Hispanic values
        WHEN Ethnicity LIKE 'Spanish/Hispanic%'  THEN 'Hispanic'

        -- 3) Unknown / missing / not reported
        WHEN Ethnicity IS NULL
          OR Ethnicity IN ('Unknown', 'Other', '')
          OR Ethnicity LIKE '%Not Reported%'
          OR Ethnicity LIKE '%Not Documented%'
          OR Ethnicity LIKE '%Not Listed%'
        THEN 'Unknown'

        -- 4) Everything else
        ELSE 'Other'
    END;

-- 1) Check how 'Not Span/Hispanic' is mapped now
SELECT 
    Ethnicity,
    Ethnicity_Std,
    COUNT(*) AS Record_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient
WHERE Ethnicity LIKE 'Not Span/Hispanic%'
GROUP BY Ethnicity, Ethnicity_Std
ORDER BY Record_Count DESC;

-- 2) Overall standardized distribution
SELECT 
    Ethnicity_Std,
    COUNT(*) AS Record_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient
GROUP BY Ethnicity_Std
ORDER BY Record_Count DESC;
