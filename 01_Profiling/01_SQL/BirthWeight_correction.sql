/* 
 STEP: FIX Birth_Weight DATA TYPE
 Reason:
 The Birth_Weight field was imported as text (nvarchar),
 causing incorrect profiling results and preventing numeric analysis.
 We first create a properly typed column, migrate data, and then replace the old column.
*/

-- 1️. Add a new numeric column (INT allows proper measurements in grams)
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD Birth_Weight_Grams INT NULL;

-- 2️. Convert text values into integers where possible
-- TRY_CAST prevents errors by setting invalid values to NULL instead of failing
UPDATE dbo.LI_SPARCS_2015_25_Inpatient
SET Birth_Weight_Grams = TRY_CAST(Birth_Weight AS INT);

-- 3️. Remove the original text column after successful migration
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
DROP COLUMN Birth_Weight;

-- 4️. Rename the numeric column to the original name
-- This keeps backward compatibility for all future analysis
EXEC sp_rename
    'dbo.LI_SPARCS_2015_25_Inpatient.Birth_Weight_Grams',
    'Birth_Weight',
    'COLUMN';