/* 
 STEP 02.2 – FIX MONEY FIELDS (Total_Charges, Total_Costs)
 Reason:
 - Imported as nvarchar with $ signs and thousand separators
 - Cannot aggregate or compute ratios reliably in this state
 - We convert them to DECIMAL(18,2) for financial analysis
*/

-- 1) Add new numeric columns
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
    ADD Total_Charges_Num DECIMAL(18,2) NULL,
        Total_Costs_Num   DECIMAL(18,2) NULL;

-- 2) Strip '$' and ',' then convert to DECIMAL
UPDATE dbo.LI_SPARCS_2015_25_Inpatient
SET Total_Charges_Num = TRY_CONVERT(
        DECIMAL(18,2),
        REPLACE(REPLACE(Total_Charges, '$', ''), ',', '')
    ),
    Total_Costs_Num = TRY_CONVERT(
        DECIMAL(18,2),
        REPLACE(REPLACE(Total_Costs, '$', ''), ',', '')
    );

-- 3) Drop old text columns
ALTER TABLE dbo.LI_SPARCS_2015_25_Inpatient
DROP COLUMN Total_Charges,
            Total_Costs;

-- 4) Rename numeric columns to original names
EXEC sp_rename
    'dbo.LI_SPARCS_2015_25_Inpatient.Total_Charges_Num',
    'Total_Charges',
    'COLUMN';

EXEC sp_rename
    'dbo.LI_SPARCS_2015_25_Inpatient.Total_Costs_Num',
    'Total_Costs',
    'COLUMN';

-- (Optional sanity check)
SELECT 
    MIN(Total_Charges) AS Min_Charges,
    MAX(Total_Charges) AS Max_Charges,
    MIN(Total_Costs)   AS Min_Costs,
    MAX(Total_Costs)   AS Max_Costs
FROM dbo.LI_SPARCS_2015_25_Inpatient;
