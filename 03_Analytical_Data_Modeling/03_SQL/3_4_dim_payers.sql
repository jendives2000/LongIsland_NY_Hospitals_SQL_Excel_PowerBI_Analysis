/*
    STEP 03.4 – Build Dim_Payer and link it to the inpatient fact table

    WHY:
    - Step 02.7 created Payment_Typology_Group on the raw inpatient table
      (Medicare, Medicaid, Commercial, Self-Pay, Other, Unknown).
    - For a proper star schema, payer information should live in its own
      dimension table, with a surrogate key referenced by the fact table.

    WHAT THIS SCRIPT DOES:
    1) Creates dbo.Dim_Payer with a surrogate key (Payer_Key).
    2) Populates Dim_Payer from distinct payer values observed in
       dbo.LI_SPARCS_2015_25_Inpatient.
    3) Adds Payer_Key as a foreign-key-style column on the inpatient table.
    4) Populates Payer_Key by joining fact rows to Dim_Payer.
    5) Runs sanity checks to confirm everything is wired correctly.
*/

------------------------------------------------------------
-- 1) Create Dim_Payer (drop and recreate if needed)
------------------------------------------------------------
IF OBJECT_ID('dbo.Dim_Payer', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Dim_Payer;
END;
GO

CREATE TABLE dbo.Dim_Payer
(
    Payer_Key              INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Dim_Payer PRIMARY KEY CLUSTERED,

    -- Original payer label as it appears in the SPARCS file
    Payment_Typology_1     NVARCHAR(255) NULL,

    -- Grouped payer bucket from Step 02.7 (Medicare, Medicaid, etc.)
    Payment_Typology_Group NVARCHAR(30)  NULL,

    -- Helper flag to quickly isolate missing/unknown payer info
    Is_Unknown             BIT NOT NULL
        CONSTRAINT DF_Dim_Payer_Is_Unknown DEFAULT (0)
);
GO

------------------------------------------------------------
-- 2) Populate Dim_Payer from distinct payer values
--
--    WHY:
--    - We let the source inpatient table drive the list of payers
--      actually present in the data.
--    - We carry both the raw label and the grouped bucket so that
--      we can aggregate at either level later.
------------------------------------------------------------
INSERT INTO dbo.Dim_Payer (Payment_Typology_1, Payment_Typology_Group, Is_Unknown)
SELECT DISTINCT
    f.Payment_Typology_1,
    f.Payment_Typology_Group,
    CASE
        WHEN f.Payment_Typology_Group = 'Unknown'
             OR f.Payment_Typology_1 IS NULL
             OR LTRIM(RTRIM(f.Payment_Typology_1)) = ''
        THEN 1
        ELSE 0
    END AS Is_Unknown
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f;
GO

------------------------------------------------------------
-- 3) Add Payer_Key to the inpatient fact table (if not already there)
--
--    WHY:
--    - This is the foreign-key-style link from the fact table to Dim_Payer.
--    - We keep it NULL initially, then backfill it via an UPDATE JOIN.
------------------------------------------------------------
IF COL_LENGTH('dbo.LI_SPARCS_2015_25_Inpatient', 'Payer_Key') IS NULL
BEGIN
    ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD Payer_Key INT NULL;
END;
GO

------------------------------------------------------------
-- 4) Populate Payer_Key on the fact table
--
--    JOIN LOGIC:
--    - Match on both Payment_Typology_1 and Payment_Typology_Group.
--    - Use ISNULL/COALESCE to avoid join issues if any values are NULL.
------------------------------------------------------------
UPDATE f
SET f.Payer_Key = d.Payer_Key
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
INNER JOIN dbo.Dim_Payer AS d
    ON ISNULL(f.Payment_Typology_1, '')     = ISNULL(d.Payment_Typology_1, '')
   AND ISNULL(f.Payment_Typology_Group, '') = ISNULL(d.Payment_Typology_Group, '');
GO

------------------------------------------------------------
-- 5) SANITY CHECKS
------------------------------------------------------------

-- 5a) Check total rows and how many lack a Payer_Key
SELECT
    COUNT(*) AS Total_Rows,
    SUM(CASE WHEN Payer_Key IS NULL THEN 1 ELSE 0 END) AS Rows_Without_Payer_Key
FROM dbo.LI_SPARCS_2015_25_Inpatient;
GO

-- 5b) Inspect a few sample rows with missing Payer_Key, if any
SELECT TOP (50)
    f.Payment_Typology_1,
    f.Payment_Typology_Group,
    f.Payer_Key
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
WHERE f.Payer_Key IS NULL
ORDER BY f.Payment_Typology_Group, f.Payment_Typology_1;
GO

-- 5c) Distribution of payer groups in Dim_Payer
SELECT
    Payment_Typology_Group,
    COUNT(*) AS Distinct_Payers
FROM dbo.Dim_Payer
GROUP BY Payment_Typology_Group
ORDER BY Distinct_Payers DESC;
GO

-- 5d) Optional: verify fact rows by payer group via the Dim_Payer join
SELECT
    d.Payment_Typology_Group,
    COUNT(*) AS Record_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient AS f
INNER JOIN dbo.Dim_Payer AS d
    ON f.Payer_Key = d.Payer_Key
GROUP BY d.Payment_Typology_Group
ORDER BY Record_Count DESC;
GO

------------------------------------------------------------
-- 6) (Optional) Add a foreign key constraint once you are confident
--    that every row has a valid Payer_Key and there are no orphaned
--    references.
------------------------------------------------------------
/*
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ADD CONSTRAINT FK_LI_SPARCS_2015_25_Inpatient_Dim_Payer
    FOREIGN KEY (Payer_Key)
    REFERENCES dbo.Dim_Payer (Payer_Key);
GO
*/
