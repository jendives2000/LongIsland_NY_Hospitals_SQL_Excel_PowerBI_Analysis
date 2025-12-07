/*
    STEP 03.5 – Build Dim_ClinicalClass and link it to the inpatient table

    Assumptions about source columns on dbo.LI_SPARCS_2015_25_Inpatient:
        - APR_DRG_Code          : code of the APR-DRG
        - APR_DRG_Description   : text label for the APR-DRG

*/

------------------------------------------------------------
-- 1) Drop and recreate Dim_ClinicalClass
------------------------------------------------------------
IF OBJECT_ID('dbo.Dim_ClinicalClass', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Dim_ClinicalClass;
END;
GO

CREATE TABLE dbo.Dim_ClinicalClass
(
    ClinicalClass_Key     INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Dim_ClinicalClass PRIMARY KEY CLUSTERED,

    APR_DRG_Code          NVARCHAR(20)  NULL,
    APR_DRG_Description   NVARCHAR(255) NULL,

    Is_Unknown            BIT NOT NULL
        CONSTRAINT DF_Dim_ClinicalClass_Is_Unknown DEFAULT (0)
);
GO

------------------------------------------------------------
-- 2) Populate Dim_ClinicalClass from distinct APR-DRG values
------------------------------------------------------------
INSERT INTO dbo.Dim_ClinicalClass (APR_DRG_Code, APR_DRG_Description, Is_Unknown)
SELECT DISTINCT
    f.APR_DRG_Code,
    f.APR_DRG_Description,
    CASE
        WHEN f.APR_DRG_Code IS NULL
             OR LTRIM(RTRIM(f.APR_DRG_Code)) = ''
        THEN 1
        ELSE 0
    END AS Is_Unknown
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f;
GO

------------------------------------------------------------
-- 3) Add ClinicalClass_Key to the inpatient table (if not present)
------------------------------------------------------------
IF COL_LENGTH('dbo.LI_SPARCS_2015_25_Inpatient', 'ClinicalClass_Key') IS NULL
BEGIN
    ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD ClinicalClass_Key INT NULL;
END;
GO

------------------------------------------------------------
-- 4) Populate ClinicalClass_Key on the inpatient table
------------------------------------------------------------
UPDATE f
SET f.ClinicalClass_Key = d.ClinicalClass_Key
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
INNER JOIN dbo.Dim_ClinicalClass AS d
    ON ISNULL(f.APR_DRG_Code, '')        = ISNULL(d.APR_DRG_Code, '')
   AND ISNULL(f.APR_DRG_Description, '') = ISNULL(d.APR_DRG_Description, '');
GO

------------------------------------------------------------
-- 5) Sanity checks
------------------------------------------------------------

-- 5a) Total rows and how many are missing a ClinicalClass_Key
SELECT
    COUNT(*) AS Total_Rows,
    SUM(CASE WHEN ClinicalClass_Key IS NULL THEN 1 ELSE 0 END) AS Rows_Without_ClinicalClass_Key
FROM dbo.LI_SPARCS_2015_25_Inpatient;
GO

-- 5b) Inspect sample rows without a ClinicalClass_Key (if any)
SELECT TOP (50)
    f.APR_DRG_Code,
    f.APR_DRG_Description,
    f.ClinicalClass_Key
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
WHERE f.ClinicalClass_Key IS NULL
ORDER BY f.APR_DRG_Code, f.APR_DRG_Description;
GO

-- 5c) Distinct clinical classes by Unknown flag
SELECT
    Is_Unknown,
    COUNT(*) AS Distinct_ClinicalClasses
FROM dbo.Dim_ClinicalClass
GROUP BY Is_Unknown;
GO

-- 5d) Record distribution by ClinicalClass via the dimension
SELECT TOP (20)
    d.APR_DRG_Code,
    d.APR_DRG_Description,
    COUNT(*) AS Record_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
INNER JOIN dbo.Dim_ClinicalClass AS d
    ON f.ClinicalClass_Key = d.ClinicalClass_Key
GROUP BY d.APR_DRG_Code, d.APR_DRG_Description
ORDER BY Record_Count DESC;
GO

------------------------------------------------------------
-- 6) Optional: add foreign key constraint once you're confident
--    there are no NULL or invalid ClinicalClass_Key values.
------------------------------------------------------------
/*
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ADD CONSTRAINT FK_LI_SPARCS_ClinicalClass
    FOREIGN KEY (ClinicalClass_Key)
    REFERENCES dbo.Dim_ClinicalClass (ClinicalClass_Key);
GO
*/
