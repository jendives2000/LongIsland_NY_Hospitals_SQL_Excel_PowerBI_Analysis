/* 
 STEP 02.6 – ADD SURROGATE PRIMARY KEY (Encounter_ID)

 Reason:
 - The SPARCS table has no single natural key that uniquely identifies each stay.
 - Without a key, it is hard to:
      * Track a specific hospital encounter
      * Join reliably to Fact/Dim tables later
      * Detect duplicates
 - We add a surrogate key Encounter_ID (INT IDENTITY) to give every row
   a stable, unique identifier for modeling and debugging.
*/

------------------------------------------------------------
-- 1) Add Encounter_ID column as an IDENTITY, if not present
------------------------------------------------------------
IF COL_LENGTH('dbo.LI_SPARCS_2015_25_Inpatient', 'Encounter_ID') IS NULL
BEGIN
    ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD Encounter_ID INT IDENTITY(1,1) NOT NULL;  -- auto-incrementing unique value
END
GO

------------------------------------------------------------
-- 2) Make Encounter_ID the primary key (clustered)
--    (Guarded so the script can be safely re-run)
------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1
    FROM sys.key_constraints
    WHERE [type] = 'PK'
      AND [parent_object_id] = OBJECT_ID('dbo.LI_SPARCS_2015_25_Inpatient')
)
BEGIN
    ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD CONSTRAINT PK_LI_SPARCS_2015_25_Inpatient_EncounterID
        PRIMARY KEY CLUSTERED (Encounter_ID);
END
GO


------------------------------------------------------------
-- 3️⃣ Sanity checks – confirm the key behaves as expected
--    WHAT:
--      - Check row count, min/max Encounter_ID, uniqueness.
--    WHY:
--      - Ensures no rows were lost and the key is well-formed.
------------------------------------------------------------

-- 3a) Row count: should match previous total row count for the table
SELECT COUNT(*) AS Total_Rows
FROM dbo.LI_SPARCS_2015_25_Inpatient;

-- 3b) Basic range check on Encounter_ID
SELECT 
    MIN(Encounter_ID) AS Min_Encounter_ID,
    MAX(Encounter_ID) AS Max_Encounter_ID
FROM dbo.LI_SPARCS_2015_25_Inpatient;

-- 3c) Uniqueness check (should return 0 if everything is OK)
SELECT 
    COUNT(*) - COUNT(DISTINCT Encounter_ID) AS Duplicate_Keys
FROM dbo.LI_SPARCS_2015_25_Inpatient;

