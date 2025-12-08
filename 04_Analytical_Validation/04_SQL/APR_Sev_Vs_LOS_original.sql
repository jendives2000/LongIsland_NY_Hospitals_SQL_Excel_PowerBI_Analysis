/* ==========================================================
   Clinical Logic Validation:
   APR Severity of Illness vs Length of Stay (LOS)
   ----------------------------------------------------------
   WHAT:
   - Convert text LOS values (e.g., '120 +') to numeric
   - Flag extreme LOS values that can skew averages
   - Validate LOS increases with severity category

   WHY:
   - Prevent SQL errors on aggregation (AVG/MIN/MAX)
   - Maintain analytic transparency by preserving extreme cases
   - Ensure clinical plausibility across severity groups
========================================================== */

------------------------------------------
-- STEP 1 — Flag "120 +" LOS Outliers
------------------------------------------
-- Purpose: preserve clinical signal and keep LOS numeric
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
ADD LOS_120plus_Flag BIT DEFAULT 0;

UPDATE dbo.LI_SPARCS_2015_25_Inpatient
SET LOS_120plus_Flag = 1
WHERE Length_of_Stay = '120 +';

------------------------------------------
-- STEP 2 — Normalize LOS field to INT
------------------------------------------
-- Replace '120 +' with upper-bound numeric value
UPDATE dbo.LI_SPARCS_2015_25_Inpatient
SET Length_of_Stay = '120'
WHERE Length_of_Stay = '120 +';


------------------------------------------
-- STEP 3 — Clinical sanity check:
--      Severity ↑ → LOS should ↑
------------------------------------------
WITH LOS_Cast AS (
    SELECT
        TRY_CAST(Length_of_Stay AS INT) AS LOS_Int,
        APR_Severity_of_Illness_Code    AS Severity_Code,
        APR_Severity_of_Illness_Description AS Severity_Label
    FROM dbo.LI_SPARCS_2015_25_Inpatient
)
SELECT 
    Severity_Code,
    Severity_Label,
    COUNT(*) AS Encounter_Count,
    AVG(LOS_Int * 1.0) AS Avg_LOS,  -- WHY: ensure decimal division
    MIN(LOS_Int) AS Min_LOS,
    MAX(LOS_Int) AS Max_LOS
FROM LOS_Cast
WHERE LOS_Int IS NOT NULL  -- WHY: exclude casting failures
GROUP BY Severity_Code, Severity_Label
ORDER BY Severity_Code;
