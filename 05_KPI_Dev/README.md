# 05 - KPI Development

## Purpose

This step defines and validates the KPI layer used by both the semantic model (`06`) and the executive Excel integration (`07`).

All KPI logic is authored in SQL, validated with encounter-level exports, and then promoted to governed facility-year KPI views where applicable.

---

## Explainability-First Design

KPI sequencing is intentional:

- Context KPIs: Severity Mix, Payer Mix, Unplanned Intake
- Outcome KPIs: Disposition, LOS, Mortality, Cost and Margin Pressure

This preserves interpretation safety by establishing operating context before judging outcomes.

---

## Inputs and Dependencies

Primary dependency objects:

- `dbo.Fact_Encounter`
- `dbo.Dim_Date`
- `dbo.Dim_Facility`
- `dbo.Dim_Payer`
- `dbo.Dim_AdmissionType`
- `dbo.Dim_Disposition`
- `dbo.Dim_ClinicalClass`

Validation dependency:

- Step [`04_Analytical_Validation`](/04_Analytical_Validation/README.md) anomaly and plausibility controls

---

## Step 05 Output Types

### 1) Validation Outputs (Step-05 internal QA)

These are encounter-grain outputs used for Excel reconciliation and logic validation.

- One row per encounter
- Used to reconcile numerators, denominators, and rates
- Not intended as final executive consumption layer

### 2) Executive-Consumption KPI Views (Step-07-facing)

These are governed SQL views intended to be consumed by Step 07 integration.

- Stable grain (typically Facility-Year)
- Reusable across Power BI and Excel
- Avoids KPI recomputation in Excel

---

## KPI Catalog and Contracts

- [`05_01_Severity_Mix_Index_APR`](/05_KPI_Dev/05_01_Severity_Mix_Index_APR/README.md)
- [`05_02_Payers_Mix_Reimb_Risk`](/05_KPI_Dev/05_02_Payers_Mix_Reimb_Risk/README.md)
- [`05_03_Unplanned_Admission_Rate`](/05_KPI_Dev/05_03_Unplanned_Admission_Rate/README.md)
- [`05_04_Disposition_Outcomes`](/05_KPI_Dev/05_04_Disposition_Outcomes/README.md)
- [`05_05_LOS_LengthOfStay_KPI`](/05_KPI_Dev/05_05_LOS_LengthOfStay_KPI/README.md)
- [`05_06_Mortality_Rate`](/05_KPI_Dev/05_06_Mortality_Rate/README.md)
- [`05_07_MCost_and_Margin_Pressure`](/05_KPI_Dev/05_07_MCost_and_Margin_Pressure/README.md)

Template:

- [`05_0x_folder_template`](/05_KPI_Dev/05_0x_folder_template/README.md)

---

## Step-07 Consumption Mapping

Step 07 ([`07_SQL/07_01_vw_Excel_KPI_Executive_FacilityYear.sql`](/07_Excel_Executive_Analytics/07_SQL/07_01_vw_Excel_KPI_Executive_FacilityYear.sql)) consumes these Step-05 KPI views:

- `dbo.vw_KPI_05_01_SeverityMix_FacilityYear`
- `dbo.vw_KPI_PayerMix_FacilityYear`
- `dbo.vw_KPI_UnplannedAdmissions_FacilityYear`
- `dbo.vw_KPI_DispositionOutcomes_FacilityYear`
- `dbo.vw_KPI_LOS_FacilityYear` (expected)
- `dbo.vw_KPI_Mortality_FacilityYear`
- `dbo.vw_KPI_CostPerCase_FacilityYear`

### Important LOS Dependency Gap

[`07_01_vw_Excel_KPI_Executive_FacilityYear.sql`](/07_Excel_Executive_Analytics/07_SQL/07_01_vw_Excel_KPI_Executive_FacilityYear.sql) expects `dbo.vw_KPI_LOS_FacilityYear`, but this view is not created in the current Step-05 LOS SQL file ([`05_05_SQL/05_05_Length_of_Stay.sql`](/05_KPI_Dev/05_05_LOS_LengthOfStay_KPI/05_05_SQL/05_05_Length_of_Stay.sql)).

This should be resolved before Step-07 execution by either:

- adding `CREATE OR ALTER VIEW dbo.vw_KPI_LOS_FacilityYear` in Step 05, or
- documenting and executing an alternative source that creates it.

---

## Governance Boundary with Step 07

- Step 05: KPI definition and validation
- Step 07: executive consumption only

Step 07 should consume governed KPI views, not redefine KPI formulas.

---

## Folder Structure

```text
05_KPI_Dev/
|-- README.md
|-- 05_01_Severity_Mix_Index_APR/
|   |-- 05_Excel/
|   |-- 05_SQL/
|   |-- screenshots/   (5 validation images)
|   `-- README.md
|-- 05_02_Payers_Mix_Reimb_Risk/
|   |-- 05_02_Excel/
|   |-- 05_02_SQL/
|   |-- screenshots/   (5 validation images)
|   `-- README.md
|-- 05_03_Unplanned_Admission_Rate/
|   |-- 05_03_Excel/
|   |-- 05_03_SQL/
|   |-- screenshots/   (8 validation images)
|   `-- README.md
|-- 05_04_Disposition_Outcomes/
|   |-- 05_04_Excel/
|   |-- 05_04_SQL/
|   |-- screenshots/   (4 validation images)
|   `-- README.md
|-- 05_05_LOS_LengthOfStay_KPI/
|   |-- 05_05_Excel/
|   |-- 05_05_SQL/
|   |-- screenshots/   (9 validation images)
|   `-- README.md
|-- 05_06_Mortality_Rate/
|   |-- 05_06_Excel/
|   |-- 05_06_SQL/
|   |-- screenshots/   (3 validation images)
|   `-- README.md
|-- 05_07_MCost_and_Margin_Pressure/
|   |-- 05_07_Excel/
|   |-- 05_07_SQL/
|   |-- screenshots/   (4 validation images)
|   `-- README.md
|-- 05_0x_folder_template/
|   |-- 05_0x_Excel/
|   |-- 05_0x_SQL/
|   `-- README.md
`-- inputs_and_dependencies.txt
```
