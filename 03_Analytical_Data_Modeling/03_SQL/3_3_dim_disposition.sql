/* 
 DIM: DISPOSITION
 Purpose:
 - Tracks where patients go after discharge
 - Critical for readmission risk, care continuity, and mortality insights
 - Refines the previously large “Other” bucket (~20%) into meaningful categories
*/

CREATE TABLE dbo.Dim_Disposition (
    Disposition_Key      INT IDENTITY(1,1) PRIMARY KEY, -- Surrogate key
    Disposition_Grouped  NVARCHAR(50)  NOT NULL,         -- Standard category
    Disposition_Detailed NVARCHAR(255) NOT NULL          -- Original detailed disposition
);

-- Populate using cleaned logic from Step 02, preserving raw text
-- Refining the other bucket by grouping into 4 subcategories: Transfers to another acute hospital, Psychiatric discharges, Hospice care transitions, AMA (Against Medical Advice)
INSERT INTO dbo.Dim_Disposition (Disposition_Grouped, Disposition_Detailed)
SELECT DISTINCT
    CASE
        WHEN Patient_Disposition IN ('Home or Self Care', 'Home') THEN 'Home'
        WHEN Patient_Disposition LIKE '%Skilled Nursing%' OR Patient_Disposition LIKE '%Rehab%' THEN 'Skilled Nursing / Rehab'
        WHEN Patient_Disposition LIKE '%Short-term Hospital%' OR Patient_Disposition LIKE '%Another Hospital%' THEN 'Transfer to Acute Care'
        WHEN Patient_Disposition LIKE '%Psych%' THEN 'Behavioral Health'
        WHEN Patient_Disposition LIKE '%Hospice%' THEN 'Hospice'
        WHEN Patient_Disposition LIKE '%Against Medical Advice%' OR Patient_Disposition LIKE '%AMA%' THEN 'Left AMA'
        WHEN Patient_Disposition LIKE '%Expired%' OR Patient_Disposition LIKE '%Died%' THEN 'Death'
        WHEN Patient_Disposition IS NULL OR Patient_Disposition = '' THEN 'Unknown'
        ELSE 'Other'
    END,
    Patient_Disposition
FROM dbo.LI_SPARCS_2015_25_Inpatient;

/* 
 SANITY CHECK – Dim_Disposition
 Validate grouped discharge categories are distributed as expected
*/

SELECT 
    Disposition_Grouped,
    COUNT(*) AS Record_Count
FROM dbo.Dim_Disposition
GROUP BY Disposition_Grouped
ORDER BY Record_Count DESC;
