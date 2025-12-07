/*
    STEP 02.7 – GROUP Payment_Typology_1 (Payer Granularity)

    Reason (WHY):
    - The raw SPARCS inpatient file uses the NAHDO Source of Payment Typology,
      which contains MANY fine-grained payer descriptions:
        * Medicare & Medicaid variants
        * Commercial / private plans (HMO, PPO, POS, Indemnity, BC/BS, etc.)
        * Self-pay / no charge / charity / bad debt
        * Workers’ comp, auto, liability, other government programmes, etc.
    - These detailed labels are great for claims, but noisy for BI:
        * Hard to see high-level payer mix
        * Hard to compare reimbursement and cost burden by payer type

    WHAT this script does:
    - Adds a new column: Payment_Typology_Group
    - Maps Payment_Typology_1 descriptions into broad buckets:
        * Medicare
        * Medicaid
        * Commercial
        * Self-Pay
        * Other
        * Unknown
    - Runs sanity checks so we can validate the distribution and refine
      mapping rules if needed.
*/

------------------------------------------------------------
-- 1) Add grouped payment typology column (if not present)
------------------------------------------------------------
IF COL_LENGTH('dbo.LI_SPARCS_2015_25_Inpatient', 'Payment_Typology_Group') IS NULL
BEGIN
    ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD Payment_Typology_Group NVARCHAR(30) NULL;
END;
GO

------------------------------------------------------------
-- 2) Map raw Payment_Typology_1 descriptions into broad
--    payer groups using simple keyword-based rules
------------------------------------------------------------
UPDATE dbo.LI_SPARCS_2015_25_Inpatient
SET Payment_Typology_Group =
    CASE
        ----------------------------------------------------------------
        -- UNKNOWN
        -- Null / empty values stay explicitly marked as Unknown
        ----------------------------------------------------------------
        WHEN Payment_Typology_1 IS NULL
             OR LTRIM(RTRIM(Payment_Typology_1)) = '' THEN 'Unknown'

        ----------------------------------------------------------------
        -- MEDICARE
        -- Any description mentioning Medicare (including dual-eligible)
        ----------------------------------------------------------------
        WHEN Payment_Typology_1 LIKE '%Medicare%' THEN 'Medicare'

        ----------------------------------------------------------------
        -- MEDICAID
        -- Any description mentioning Medicaid or SCHIP programmes
        ----------------------------------------------------------------
        WHEN Payment_Typology_1 LIKE '%Medicaid%'
             OR Payment_Typology_1 LIKE '%SCHIP%' THEN 'Medicaid'

        ----------------------------------------------------------------
        -- SELF-PAY / NO PAYMENT
        -- Self-pay, no charge, charity, bad debt, refusal to pay, etc.
        -- These correspond to "no payment from an organization".
        ----------------------------------------------------------------
        WHEN Payment_Typology_1 LIKE '%Self%Pay%'
             OR Payment_Typology_1 LIKE '%Self-pay%'
             OR Payment_Typology_1 LIKE '%Self Pay%'
             OR Payment_Typology_1 LIKE '%No Charge%'
             OR Payment_Typology_1 LIKE '%No Payment%'
             OR Payment_Typology_1 LIKE '%Charity%'
             OR Payment_Typology_1 LIKE '%Bad Debt%'
             OR Payment_Typology_1 LIKE '%Refusal%'
             OR Payment_Typology_1 LIKE '%Hill Burton%'
             OR Payment_Typology_1 LIKE '%Professional Courtesy%'
             OR Payment_Typology_1 LIKE '%Research%'
             OR Payment_Typology_1 LIKE '%Donor%' THEN 'Self-Pay'

        ----------------------------------------------------------------
        -- COMMERCIAL / PRIVATE INSURANCE
        -- Blue Cross/Blue Shield, commercial & private insurance,
        -- generic managed care (HMO, PPO, POS, indemnity, ERISA, etc.).
        ----------------------------------------------------------------
        WHEN Payment_Typology_1 LIKE '%Blue Cross%'
             OR Payment_Typology_1 LIKE '%Blue Shield%'
             OR Payment_Typology_1 LIKE '%BCBS%'
             OR Payment_Typology_1 LIKE '%Commercial%'
             OR Payment_Typology_1 LIKE '%Private%'
             OR Payment_Typology_1 LIKE '%Insurance%'
             OR Payment_Typology_1 LIKE '%HMO%'
             OR Payment_Typology_1 LIKE '%PPO%'
             OR Payment_Typology_1 LIKE '%POS%'
             OR Payment_Typology_1 LIKE '%Managed Care%'
             OR Payment_Typology_1 LIKE '%Indemnity%'
             OR Payment_Typology_1 LIKE '%ERISA%' THEN 'Commercial'

        ----------------------------------------------------------------
        -- OTHER
        -- Workers' compensation, auto/no-fault, liability, other
        -- government programmes, foreign, disability, LTC, generic
        -- "Other" that isn't already captured above.
        ----------------------------------------------------------------
        WHEN Payment_Typology_1 LIKE '%Worker%'
             OR Payment_Typology_1 LIKE '%Comp%'
             OR Payment_Typology_1 LIKE '%Auto%'
             OR Payment_Typology_1 LIKE '%Liability%'
             OR Payment_Typology_1 LIKE '%Foreign%'
             OR Payment_Typology_1 LIKE '%Disability%'
             OR Payment_Typology_1 LIKE '%Long%Term%Care%'
             OR Payment_Typology_1 LIKE '%Long-Term Care%'
             OR Payment_Typology_1 LIKE '%Long Term Care%'
             OR Payment_Typology_1 LIKE '%Other%' THEN 'Other'

        ----------------------------------------------------------------
        -- DEFAULT
        -- Safety net: any uncaught description goes to Other so that
        -- no row is left unmapped. We can later inspect these values
        -- and refine the rules if needed.
        ----------------------------------------------------------------
        ELSE 'Other'
    END;
GO

------------------------------------------------------------
-- 3) SANITY CHECKS – VALIDATE THE NEW GROUPS
------------------------------------------------------------

-- 3a) Distribution of payer groups
--     WHY:
--     - Confirm every row falls into exactly one of the expected buckets.
--     - Check if 'Other' or 'Unknown' is too large, meaning we may need
--       more specific mapping rules.
SELECT
    Payment_Typology_Group,
    COUNT(*) AS Record_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient
GROUP BY Payment_Typology_Group
ORDER BY Record_Count DESC;
GO

-- 3b) Inspect the most common raw values mapped to 'Other'
--     WHY:
--     - Helps identify frequent descriptions that might deserve their
--       own explicit mapping instead of living in the Other bucket.
SELECT TOP (50)
    Payment_Typology_1,
    Payment_Typology_Group,
    COUNT(*) AS Record_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient
GROUP BY Payment_Typology_1, Payment_Typology_Group
HAVING Payment_Typology_Group = 'Other'
ORDER BY Record_Count DESC;
GO

-- 3c) Inspect the most common raw values mapped to 'Unknown'
--     WHY:
--     - Sanity check that Unknown really is null/blank and not some
--       unhandled "Unknown"-like label.
SELECT TOP (50)
    Payment_Typology_1,
    Payment_Typology_Group,
    COUNT(*) AS Record_Count
FROM dbo.LI_SPARCS_2015_25_Inpatient
GROUP BY Payment_Typology_1, Payment_Typology_Group
HAVING Payment_Typology_Group = 'Unknown'
ORDER BY Record_Count DESC;
GO
