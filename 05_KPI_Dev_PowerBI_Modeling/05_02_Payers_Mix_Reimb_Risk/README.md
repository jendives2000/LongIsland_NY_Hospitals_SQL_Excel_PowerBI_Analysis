# 05.02. Payer Mix & Reimbursement Risk


## What:

This KPI summarizes encounter volume, financial exposure, and negative-margin risk across payer groups by facility and year, using standardized payment typologies.

## Why:

Payer mix directly affects hospital revenue stability. Understanding which payer groups drive volume, cost, and losses is essential for financial planning and contract negotiations.

## Design Summary

**Primary View:** dbo.vw_KPI_PayerMix_FacilityYear

**Why it comes second:**
- Simple grouping logic using Payment_Typology_Group.
- Does not depend on LOS, mortality, or disposition logic.
- Establishes the core financial exposure context of the hospital system.
- Essential background for interpreting cost-per-case and margin pressure in later KPIs.

**Key Columns Used**:
- From Fact_Encounter: Facility_Key, Payer_Key, Total_Costs, Total_Charges
- From Dim_Payer: Payment_Typology_Group
- From Dim_Date: Year
- From Dim_Facility: Facility_Name

## SQL Checks:
SQL file: [here](./05_02_SQL/05_02_Payment_Mix_Reimbursement_Risk.sql)

- Ensure payer groups are correctly mapped and no encounters fall into unexpected NULL categories

![Payer group coverage](image.png)

- Validate negative-margin logic (Total_Costs > Total_Charges)

![Raw negative-margin counts per Facility-Year-PayerGroup](image-1.png)

Outputs:

- Encounter counts per payer group
- Share of total encounters per group
- Avg total charges & costs per payer group
- Negative-margin rate (percentage of encounters where Total_Costs > Total_Charges)
- Foundation for later Cost & Margin Pressure KPIs

## Excel Validation ✅

Excel validation file: [here](./05_02_Excel/05_02_Payment_Mix_Reimbursement_Risk)

What to validate: 
- Payer group counts and negative-margin classification
- PivotTable correctly groups encounters by Payment_Typology_Group (sampled just 1 hospital)
- Counts per payer group match the SQL view
- Negative-margin classification in Excel (Total_Costs > Total_Charges) matches SQL output
