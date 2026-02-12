# 04 - Analytical Validation

## Purpose

This step validates that cleaned and modeled data from Steps 02 and 03 is reliable for KPI development and semantic modeling.

Validation is executed through SQL checks and Excel-based human review to confirm that transformations remain clinically plausible, financially coherent, and structurally consistent.

This step certifies data trust and analytical readiness. It does not finalize KPI definitions.

---

## Explainability-First Role in the Pipeline

Validation acts as a governance gate between modeling and KPI development.

It verifies:

- Transformation logic behaves as intended on real records
- Fact-dimension relationships resolve correctly
- Clinical and financial patterns remain interpretable after preprocessing
- Outlier behavior is understood before KPI interpretation

---

## Scope

### Inputs

- `dbo.LI_SPARCS_2015_25_Inpatient`
- `dbo.Fact_Encounter`
- Core dimensions from Step 03

### SQL Artifacts

- `04_SQL/04_curated_extracts.sql`
- `04_SQL/ethnicity_std_mapping_fixing.sql`
- `04_SQL/04_Dim_ClinicClass_Update.sql`
- `04_SQL/APR_Sev_Vs_LOS_original.sql`
- `04_SQL/04_7_Outlier_Anomaly_Scan.sql`
- `04_SQL/04_7_Costs_greater_Charges_Actions.sql`

### Excel Validation Packs

- `04_Excel/04_1_Monetary_Top100.xlsx`
- `04_Excel/04_2_Category_Mapping_Sample.xlsx`
- `04_Excel/04_3_BirthWeight_Sample.xlsx`
- `04_Excel/04_4_Zip3_Category_Sample.xlsx`
- `04_Excel/04_5_FactDim_Integrity_Sample.xlsx`
- `04_Excel/4_6_Clinical_Index_Validation.xlsx`
- `04_Excel/4_7_ZScore_Outlier_Scan_Validation.xlsx`
- `04_Excel/4_8_Distribution_Severity_Bins.xlsx`
- `04_Excel/04_7_Costs_Greater_Charges_Actions.xlsx`

### Evidence Artifacts

- `image.png` through `image-12.png`

---

## Validation Workstreams Executed

### 1. Curated Extract Validation (SQL -> Excel)

`04_curated_extracts.sql` exports targeted samples for manual QA:

- Monetary field checks (top charge records)
- Category mapping checks
- Birth weight casting checks
- ZIP category checks
- Fact-dimension join integrity checks

### 2. Ethnicity Mapping Bug Fix

`ethnicity_std_mapping_fixing.sql` corrects a mapping logic issue where `Not Span/Hispanic` could be misclassified by broad `LIKE` ordering.

### 3. Clinical Classification Enrichment

`04_Dim_ClinicClass_Update.sql` rebuilds `Dim_ClinicalClass` with APR-specific fields to improve severity- and mortality-oriented segmentation.

### 4. Clinical Plausibility Check

`APR_Sev_Vs_LOS_original.sql` validates that higher APR severity aligns with longer LOS trends using original LOS field logic.

### 5. Outlier and Anomaly Profiling

`04_7_Outlier_Anomaly_Scan.sql` performs:

- Z-score scans (`|Z| > 3`, `|Z| > 4`) for LOS, charges, costs
- IQR-based outlier diagnostics with severity bins
- Hard-rule checks (null/negative/zero and impossible patterns)
- Financial integrity check for `Total_Costs > Total_Charges`

### 6. Negative-Margin Drilldown

`04_7_Costs_greater_Charges_Actions.sql` profiles negative-margin encounters by payer and clinical class to distinguish realistic high-complexity cases from potential quality defects.

---

## Key Validation Outcomes

- Cleaned monetary and categorical transformations are materially stable for downstream use
- Fact-to-dimension joins demonstrate consistent key resolution in sampled records
- Clinical severity behavior shows expected directional LOS relationship
- Outlier concentration follows a heavy-tail pattern consistent with inpatient utilization data
- Cost-greater-than-charge records are isolated for governance review and financial context analysis

---

## Output Contract to Step 05

This step delivers a validation-certified base for KPI development:

- Curated QA evidence in SQL and Excel
- Corrected transformation logic where defects were found
- Documented anomaly behavior and review boundaries
- Confidence that KPI definitions can proceed on a controlled, auditable data foundation

---

## Position in End-to-End Lifecycle

- `00_DB_Creation`: database and ingestion readiness
- `01_Profiling`: diagnostics
- `02_Data_Cleaning`: deterministic remediation
- `03_Analytical_Data_Modeling`: dimensional and fact design
- `04_Analytical_Validation`: SQL + Excel reconciliation and plausibility checks (this step)
- `05_KPI_Dev`: KPI definition and certification
- `06_PBI_Semantic_Model`: semantic model and governed BI layer
- `07_Excel_Executive_Analytics`: executive consumption layer

---

## Folder Contents

```text
04_Analytical_Validation/
|-- README.md
|-- image.png
|-- image-1.png
|-- image-2.png
|-- image-3.png
|-- image-4.png
|-- image-5.png
|-- image-6.png
|-- image-7.png
|-- image-8.png
|-- image-9.png
|-- image-10.png
|-- image-11.png
|-- image-12.png
|-- 04_SQL/
|   |-- 04_curated_extracts.sql
|   |-- ethnicity_std_mapping_fixing.sql
|   |-- 04_Dim_ClinicClass_Update.sql
|   |-- APR_Sev_Vs_LOS_original.sql
|   |-- 04_7_Outlier_Anomaly_Scan.sql
|   `-- 04_7_Costs_greater_Charges_Actions.sql
`-- 04_Excel/
    |-- 04_1_Monetary_Top100.xlsx
    |-- 04_2_Category_Mapping_Sample.xlsx
    |-- 04_3_BirthWeight_Sample.xlsx
    |-- 04_4_Zip3_Category_Sample.xlsx
    |-- 04_5_FactDim_Integrity_Sample.xlsx
    |-- 4_6_Clinical_Index_Validation.xlsx
    |-- 4_7_ZScore_Outlier_Scan_Validation.xlsx
    |-- 4_8_Distribution_Severity_Bins.xlsx
    `-- 04_7_Costs_Greater_Charges_Actions.xlsx
```
