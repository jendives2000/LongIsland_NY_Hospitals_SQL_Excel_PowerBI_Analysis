/* 
 STEP 02.6 – IDENTIFY NVARCHAR(MAX) COLUMNS
 Reason:
 - Columns imported as NVARCHAR(MAX) (-1 length) are slower to index and scan.
 - In this dataset, these are mostly code descriptions, not true free-text notes,
   so we can safely shrink them to a realistic length.
*/

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'LI_SPARCS_2015_25_Inpatient'
  AND DATA_TYPE = 'nvarchar'
  AND CHARACTER_MAXIMUM_LENGTH = -1;

/* 1) – Measure actual lengths of NVARCHAR(MAX) columns */

SELECT 'Operating_Certificate_Number' AS ColumnName,
       MAX(LEN(Operating_Certificate_Number)) AS MaxLen
FROM dbo.LI_SPARCS_2015_25_Inpatient

UNION ALL
SELECT 'Facility_Name',
       MAX(LEN(Facility_Name))
FROM dbo.LI_SPARCS_2015_25_Inpatient

UNION ALL
SELECT 'Type_of_Admission',
       MAX(LEN(Type_of_Admission))
FROM dbo.LI_SPARCS_2015_25_Inpatient

UNION ALL
SELECT 'Patient_Disposition',
       MAX(LEN(Patient_Disposition))
FROM dbo.LI_SPARCS_2015_25_Inpatient

UNION ALL
SELECT 'CCS_Diagnosis_Description',
       MAX(LEN(CCS_Diagnosis_Description))
FROM dbo.LI_SPARCS_2015_25_Inpatient

UNION ALL
SELECT 'CCS_Procedure_Description',
       MAX(LEN(CCS_Procedure_Description))
FROM dbo.LI_SPARCS_2015_25_Inpatient

UNION ALL
SELECT 'APR_DRG_Description',
       MAX(LEN(APR_DRG_Description))
FROM dbo.LI_SPARCS_2015_25_Inpatient

UNION ALL
SELECT 'APR_MDC_Description',
       MAX(LEN(APR_MDC_Description))
FROM dbo.LI_SPARCS_2015_25_Inpatient

UNION ALL
SELECT 'APR_Severity_of_Illness_Description',
       MAX(LEN(APR_Severity_of_Illness_Description))
FROM dbo.LI_SPARCS_2015_25_Inpatient

UNION ALL
SELECT 'APR_Medical_Surgical_Description',
       MAX(LEN(APR_Medical_Surgical_Description))
FROM dbo.LI_SPARCS_2015_25_Inpatient;


/* 
 2) – RIGHT-SIZE NVARCHAR(MAX) COLUMNS
 Reason:
 - These columns were imported as NVARCHAR(MAX) (-1 length)
 - They actually contain short/medium text (codes & descriptions)
 - Fixed lengths are faster to index and query, and save storage
*/

-- Operating certificate numbers are short identifiers
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ALTER COLUMN Operating_Certificate_Number NVARCHAR(10) NULL;   -- adjust accordingly

-- Facility names: usually under 150 chars → give some headroom
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ALTER COLUMN Facility_Name NVARCHAR(75) NULL;                 -- adjust accordingly

-- Admission type labels: short categorical text
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ALTER COLUMN Type_of_Admission NVARCHAR(20) NULL;

-- Patient disposition labels: a bit longer, but still bounded
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ALTER COLUMN Patient_Disposition NVARCHAR(45) NULL;

-- Clinical descriptions (diagnosis/procedure): longer but still finite
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ALTER COLUMN CCS_Diagnosis_Description NVARCHAR(125) NULL;

ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ALTER COLUMN CCS_Procedure_Description NVARCHAR(30) NULL;

ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ALTER COLUMN APR_DRG_Description NVARCHAR(100) NULL;

ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ALTER COLUMN APR_MDC_Description NVARCHAR(110) NULL;

-- These two are usually short category labels (e.g., "Minor", "Moderate")
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ALTER COLUMN APR_Severity_of_Illness_Description NVARCHAR(15) NULL;

ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ALTER COLUMN APR_Medical_Surgical_Description NVARCHAR(20) NULL;


/* Check if any NVARCHAR(MAX) (-1) columns remain */

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'LI_SPARCS_2015_25_Inpatient'
  AND DATA_TYPE = 'nvarchar'
  AND CHARACTER_MAXIMUM_LENGTH = -1;