/*==========================================================
 STEP 03.5 – Dim_ClinicalClass using official APR fields
==========================================================*/

DROP TABLE IF EXISTS dbo.Dim_ClinicalClass;
GO

CREATE TABLE dbo.Dim_ClinicalClass (
    ClinicalClass_Key INT IDENTITY(1,1) PRIMARY KEY,
    APR_DRG_Code NVARCHAR(10),
    APR_DRG_Description NVARCHAR(200),
    APR_Severity_Code INT,
    APR_Severity_Description NVARCHAR(20),
    APR_Risk_Of_Mortality_Desc NVARCHAR(20),
    APR_MDC_Code NVARCHAR(10),
    APR_MDC_Description NVARCHAR(200)
);

INSERT INTO dbo.Dim_ClinicalClass (
    APR_DRG_Code,
    APR_DRG_Description,
    APR_Severity_Code,
    APR_Severity_Description,
    APR_Risk_Of_Mortality_Desc,
    APR_MDC_Code,
    APR_MDC_Description
)
SELECT DISTINCT
    APR_DRG_Code,
    APR_DRG_Description,
    APR_Severity_of_Illness_Code,
    APR_Severity_of_Illness_Description,
    APR_Risk_of_Mortality,
    APR_MDC_Code,
    APR_MDC_Description
FROM dbo.LI_SPARCS_2015_25_Inpatient;


-- Row count by severity
SELECT APR_Severity_Description, COUNT(*)
FROM dbo.Dim_ClinicalClass
GROUP BY APR_Severity_Description;

-- Make sure no missing severity coding
SELECT *
FROM dbo.Dim_ClinicalClass
WHERE APR_Severity_Code IS NULL;

