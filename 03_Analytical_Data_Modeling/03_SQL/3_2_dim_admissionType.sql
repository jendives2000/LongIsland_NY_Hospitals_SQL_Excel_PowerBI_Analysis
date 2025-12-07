/* 
 DIM: ADMISSION TYPE
 Purpose:
 - Simplifies admission reasons into analysis-friendly groups
 - Enables Emergency/Urgent vs Elective utilization reporting
*/

CREATE TABLE dbo.Dim_AdmissionType (
    AdmissionType_Key INT IDENTITY(1,1) PRIMARY KEY,  -- Surrogate key
    AdmissionType_Std NVARCHAR(20)  NOT NULL,          -- Clean category: Unplanned, Elective, Other, Unknown
    AdmissionType_Raw NVARCHAR(100) NULL               -- Original text for traceability
);

-- Insert distinct mappings from staging
INSERT INTO dbo.Dim_AdmissionType (AdmissionType_Std, AdmissionType_Raw)
SELECT DISTINCT
    Type_of_Admission_Std,
    Type_of_Admission
FROM dbo.LI_SPARCS_2015_25_Inpatient;

/* 
 SANITY CHECK – Dim_AdmissionType
 Purpose:
 - Verify correct category mapping
 - Ensure no unexpected or empty values exist
*/

SELECT 
    AdmissionType_Std,
    COUNT(*) AS Record_Count
FROM dbo.Dim_AdmissionType
GROUP BY AdmissionType_Std
ORDER BY Record_Count DESC;