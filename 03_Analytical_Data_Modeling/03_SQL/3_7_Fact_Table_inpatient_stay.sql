/*
    STEP 03 – Dim_Facility, Attach Dimension Keys, and Build Fact_Encounter
    ----------------------------------------------------------------------

    Source fact-like staging table:
        dbo.LI_SPARCS_2015_25_Inpatient

    Dimension tables (assumed already created, except Dim_Facility which we rebuild here):
        dbo.Dim_Facility        -- rebuilt from fact
        dbo.Dim_AdmissionType
        dbo.Dim_Disposition
        dbo.Dim_Payer
        dbo.Dim_ClinicalClass
        dbo.Dim_Date

    Goals:
        1) Rebuild Dim_Facility directly from SPARCS inpatient data
        2) Attach all dimension keys to LI_SPARCS_2015_25_Inpatient
        3) Create Fact_Encounter at the encounter grain
        4) Apply Columnstore + supporting indexes for analytics performance
*/


/*============================================================
  1) REBUILD Dim_Facility FROM FACT DATA
     -----------------------------------
     Design choice:
     - Construct Dim_Facility directly from distinct facility
       attributes in the inpatient dataset.
     - Guarantees 1:1 coverage between facilities in the fact and
       facilities in the dimension.
============================================================*/

IF OBJECT_ID('dbo.Dim_Facility', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Dim_Facility;
END;
GO

CREATE TABLE dbo.Dim_Facility
(
    Facility_Key              INT IDENTITY(1,1) PRIMARY KEY,
    Facility_Id_Native        INT            NULL,
    Operating_Certificate_Num NVARCHAR(50)   NULL,
    Facility_Name             NVARCHAR(255)  NULL,
    Health_Service_Area       NVARCHAR(255)  NULL,
    Hospital_County           NVARCHAR(255)  NULL
);
GO

INSERT INTO dbo.Dim_Facility
(
    Facility_Id_Native,
    Operating_Certificate_Num,
    Facility_Name,
    Health_Service_Area,
    Hospital_County
)
SELECT DISTINCT
    TRY_CONVERT(INT, Facility_Id)                 AS Facility_Id_Native,
    LTRIM(RTRIM(Operating_Certificate_Number))    AS Operating_Certificate_Num,
    LTRIM(RTRIM(Facility_Name))                   AS Facility_Name,
    LTRIM(RTRIM(Health_Service_Area))             AS Health_Service_Area,
    LTRIM(RTRIM(Hospital_County))                 AS Hospital_County
FROM dbo.LI_SPARCS_2015_25_Inpatient;
GO


/*============================================================
  2) ENSURE ALL REQUIRED KEY COLUMNS EXIST ON THE FACT STAGING
============================================================*/

IF COL_LENGTH('dbo.LI_SPARCS_2015_25_Inpatient', 'Facility_Key') IS NULL
BEGIN
    ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD Facility_Key INT NULL;
END;

IF COL_LENGTH('dbo.LI_SPARCS_2015_25_Inpatient', 'AdmissionType_Key') IS NULL
BEGIN
    ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD AdmissionType_Key INT NULL;
END;

IF COL_LENGTH('dbo.LI_SPARCS_2015_25_Inpatient', 'Disposition_Key') IS NULL
BEGIN
    ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD Disposition_Key INT NULL;
END;

-- Payer_Key already existed in your table, but this is safe if you run on a fresh DB
IF COL_LENGTH('dbo.LI_SPARCS_2015_25_Inpatient', 'Payer_Key') IS NULL
BEGIN
    ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD Payer_Key INT NULL;
END;
GO


/*============================================================
  3) POPULATE KEYS FROM DIMENSIONS
============================================================*/

------------------------------------------------------------
-- 3a) Facility_Key from Dim_Facility
--     Join via Facility_Id → Facility_Id_Native
------------------------------------------------------------
UPDATE f
SET f.Facility_Key = d.Facility_Key
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
INNER JOIN dbo.Dim_Facility AS d
    ON TRY_CONVERT(INT, f.Facility_Id) = d.Facility_Id_Native;
GO

------------------------------------------------------------
-- 3b) AdmissionType_Key from Dim_AdmissionType
--     Join via standardized type-of-admission label
------------------------------------------------------------
UPDATE f
SET f.AdmissionType_Key = d.AdmissionType_Key
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
INNER JOIN dbo.Dim_AdmissionType AS d
    ON f.Type_of_Admission_Std = d.AdmissionType_Std;
GO

------------------------------------------------------------
------------------------------------------------------------
-- 3c) Disposition_Key from Dim_Disposition
--     Join using grouped disposition label
--     (assumes Dim_Disposition has Patient_Disposition_Grouped too)
------------------------------------------------------------
UPDATE f
SET f.Disposition_Key = d.Disposition_Key
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
INNER JOIN dbo.Dim_Disposition AS d
    ON f.Patient_Disposition_Grouped = d.Disposition_Grouped;
GO


------------------------------------------------------------
-- 3d) Payer_Key from Dim_Payer
--     Join via primary payment typology and grouped payer bucket
------------------------------------------------------------
UPDATE f
SET f.Payer_Key = d.Payer_Key
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
INNER JOIN dbo.Dim_Payer AS d
    ON ISNULL(f.Payment_Typology_1,    '') = ISNULL(d.Payment_Typology_1,    '')
   AND ISNULL(f.Payment_Typology_Group,'') = ISNULL(d.Payment_Typology_Group,'');
GO


/*============================================================
  4) SANITY CHECKS FOR NULL OR MISSING KEYS
     (Good for debugging + README notes if needed)
============================================================*/

SELECT
    COUNT(*) AS Total_Rows,
    SUM(CASE WHEN Facility_Key       IS NULL THEN 1 ELSE 0 END) AS Rows_Without_Facility_Key,
    SUM(CASE WHEN AdmissionType_Key  IS NULL THEN 1 ELSE 0 END) AS Rows_Without_AdmissionType_Key,
    SUM(CASE WHEN Disposition_Key    IS NULL THEN 1 ELSE 0 END) AS Rows_Without_Disposition_Key,
    SUM(CASE WHEN Payer_Key          IS NULL THEN 1 ELSE 0 END) AS Rows_Without_Payer_Key,
    SUM(CASE WHEN ClinicalClass_Key  IS NULL THEN 1 ELSE 0 END) AS Rows_Without_ClinicalClass_Key,
    SUM(CASE WHEN Admission_Date_Key IS NULL THEN 1 ELSE 0 END) AS Rows_Without_Admission_Date_Key,
    SUM(CASE WHEN Discharge_Date_Key IS NULL THEN 1 ELSE 0 END) AS Rows_Without_Discharge_Date_Key
FROM dbo.LI_SPARCS_2015_25_Inpatient;
GO

-- Optional: inspect a small sample of problem rows (if any)
SELECT TOP (50)
    Facility_Key,
    AdmissionType_Key,
    Disposition_Key,
    Payer_Key,
    ClinicalClass_Key,
    Admission_Date_Key,
    Discharge_Date_Key,
    Facility_Id,
    Type_of_Admission_Std,
    Patient_Disposition,
    Patient_Disposition_Grouped,
    Payment_Typology_1,
    Payment_Typology_Group
FROM dbo.LI_SPARCS_2015_25_Inpatient
WHERE Facility_Key IS NULL
   OR AdmissionType_Key IS NULL
   OR Disposition_Key IS NULL
   OR Payer_Key IS NULL
   OR ClinicalClass_Key IS NULL
   OR Admission_Date_Key IS NULL
   OR Discharge_Date_Key IS NULL;
GO


/*============================================================
  5) CREATE Fact_Encounter (STAR-SCHEMA FACT TABLE)
============================================================*/

IF OBJECT_ID('dbo.Fact_Encounter', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Fact_Encounter;
END;
GO

CREATE TABLE dbo.Fact_Encounter
(
    Encounter_ID            INT             NOT NULL,

    Facility_Key            INT             NOT NULL,
    AdmissionType_Key       INT             NULL,
    Disposition_Key         INT             NULL,
    Payer_Key               INT             NULL,
    ClinicalClass_Key       INT             NULL,
    Admission_Date_Key      INT             NULL,
    Discharge_Date_Key      INT             NULL,

    LOS_Sim                 INT             NULL,

    Total_Charges           NUMERIC(18,2)   NULL,
    Total_Costs             NUMERIC(18,2)   NULL,

    ED_Flag                 BIT             NULL,   -- 1 = ED encounter, 0 = non-ED

    CONSTRAINT PK_Fact_Encounter
        PRIMARY KEY NONCLUSTERED (Encounter_ID)
);
GO

INSERT INTO dbo.Fact_Encounter
(
    Encounter_ID,
    Facility_Key,
    AdmissionType_Key,
    Disposition_Key,
    Payer_Key,
    ClinicalClass_Key,
    Admission_Date_Key,
    Discharge_Date_Key,
    LOS_Sim,
    Total_Charges,
    Total_Costs,
    ED_Flag
)
SELECT
    f.Encounter_ID,
    f.Facility_Key,
    f.AdmissionType_Key,
    f.Disposition_Key,
    f.Payer_Key,
    f.ClinicalClass_Key,
    f.Admission_Date_Key,
    f.Discharge_Date_Key,
    f.LOS_Sim,
    f.Total_Charges,
    f.Total_Costs,
    CASE WHEN f.Emergency_Department_Indicator = 'Y' THEN 1 ELSE 0 END AS ED_Flag
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f;
GO


/*============================================================
  6) PERFORMANCE INDEXING FOR ANALYTICS
     - Clustered Columnstore Index (CCI) on the fact
     - Supporting nonclustered indexes on key columns
============================================================*/

-- 6a) Clustered Columnstore Index: main analytics engine
IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.Fact_Encounter')
      AND name = 'CCI_Fact_Encounter'
)
BEGIN
    DROP INDEX CCI_Fact_Encounter ON dbo.Fact_Encounter;
END;
GO

CREATE CLUSTERED COLUMNSTORE INDEX CCI_Fact_Encounter
ON dbo.Fact_Encounter;
GO

-- 6b) Supporting nonclustered indexes for common filters/joins
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.Fact_Encounter')
      AND name = 'IX_Fact_Encounter_Facility'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Fact_Encounter_Facility
    ON dbo.Fact_Encounter (Facility_Key);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.Fact_Encounter')
      AND name = 'IX_Fact_Encounter_Payer'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Fact_Encounter_Payer
    ON dbo.Fact_Encounter (Payer_Key);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.Fact_Encounter')
      AND name = 'IX_Fact_Encounter_AdmissionDate'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Fact_Encounter_AdmissionDate
    ON dbo.Fact_Encounter (Admission_Date_Key);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.Fact_Encounter')
      AND name = 'IX_Fact_Encounter_DischargeDate'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Fact_Encounter_DischargeDate
    ON dbo.Fact_Encounter (Discharge_Date_Key);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.Fact_Encounter')
      AND name = 'IX_Fact_Encounter_ClinicalClass'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Fact_Encounter_ClinicalClass
    ON dbo.Fact_Encounter (ClinicalClass_Key);
END;
GO


/*============================================================
  7) OPTIONAL: FOREIGN-KEY CONSTRAINTS
     Uncomment once you are sure there are no orphan keys.
============================================================*/
/*
ALTER TABLE dbo.Fact_Encounter WITH CHECK
ADD CONSTRAINT FK_Fact_Encounter_Dim_Facility
    FOREIGN KEY (Facility_Key)
    REFERENCES dbo.Dim_Facility (Facility_Key);

ALTER TABLE dbo.Fact_Encounter WITH CHECK
ADD CONSTRAINT FK_Fact_Encounter_Dim_AdmissionType
    FOREIGN KEY (AdmissionType_Key)
    REFERENCES dbo.Dim_AdmissionType (AdmissionType_Key);

ALTER TABLE dbo.Fact_Encounter WITH CHECK
ADD CONSTRAINT FK_Fact_Encounter_Dim_Disposition
    FOREIGN KEY (Disposition_Key)
    REFERENCES dbo.Dim_Disposition (Disposition_Key);

ALTER TABLE dbo.Fact_Encounter WITH CHECK
ADD CONSTRAINT FK_Fact_Encounter_Dim_Payer
    FOREIGN KEY (Payer_Key)
    REFERENCES dbo.Dim_Payer (Payer_Key);

ALTER TABLE dbo.Fact_Encounter WITH CHECK
ADD CONSTRAINT FK_Fact_Encounter_Dim_ClinicalClass
    FOREIGN KEY (ClinicalClass_Key)
    REFERENCES dbo.Dim_ClinicalClass (ClinicalClass_Key);

ALTER TABLE dbo.Fact_Encounter WITH CHECK
ADD CONSTRAINT FK_Fact_Encounter_Dim_Date_Admission
    FOREIGN KEY (Admission_Date_Key)
    REFERENCES dbo.Dim_Date (Date_Key);

ALTER TABLE dbo.Fact_Encounter WITH CHECK
ADD CONSTRAINT FK_Fact_Encounter_Dim_Date_Discharge
    FOREIGN KEY (Discharge_Date_Key)
    REFERENCES dbo.Dim_Date (Date_Key);
*/
GO


/*============================================================
  8) QUICK STAR-SCHEMA SANITY / PERFORMANCE CHECK
============================================================*/

SELECT TOP (20)
    d.[Year],
    p.Payment_Typology_Group,
    fac.Facility_Name,
    SUM(f.Total_Charges) AS Total_Charges,
    COUNT(*)             AS Encounter_Count
FROM dbo.Fact_Encounter      AS f
JOIN dbo.Dim_Date            AS d   ON f.Discharge_Date_Key = d.Date_Key
JOIN dbo.Dim_Payer           AS p   ON f.Payer_Key          = p.Payer_Key
JOIN dbo.Dim_Facility        AS fac ON f.Facility_Key       = fac.Facility_Key
GROUP BY
    d.[Year],
    p.Payment_Typology_Group,
    fac.Facility_Name
ORDER BY
    d.[Year],
    p.Payment_Typology_Group,
    Encounter_Count DESC;
GO
