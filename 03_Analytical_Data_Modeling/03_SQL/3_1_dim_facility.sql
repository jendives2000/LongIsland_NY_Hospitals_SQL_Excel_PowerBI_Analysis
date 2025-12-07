/* 
 DIM: FACILITY
 Purpose:
 - Stores standardized information about hospitals (name, county, region)
 - Reduces duplication and enables performance benchmarking across facilities
*/

CREATE TABLE dbo.Dim_Facility (
    Facility_Key              INT IDENTITY(1,1) PRIMARY KEY, -- Surrogate key
    Facility_Id_Native        INT           NULL,            -- Original facility ID from staging
    Operating_Certificate_Num NVARCHAR(50)  NULL,            -- Compliance identifier
    Facility_Name             NVARCHAR(255) NULL,
    Health_Service_Area       NVARCHAR(50)  NULL,
    Hospital_County           NVARCHAR(50)  NULL
);

-- Populate Dimension with distinct values from staging table
INSERT INTO dbo.Dim_Facility (
    Facility_Id_Native,
    Operating_Certificate_Num,
    Facility_Name,
    Health_Service_Area,
    Hospital_County
)
SELECT DISTINCT
    Facility_Id,
    Operating_Certificate_Number,
    Facility_Name,
    Health_Service_Area,
    Hospital_County
FROM dbo.LI_SPARCS_2015_25_Inpatient;
