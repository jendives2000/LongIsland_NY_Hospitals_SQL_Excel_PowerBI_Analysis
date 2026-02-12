# 02 - Data Cleaning and Standardization

## Purpose

This step translates profiling findings into deterministic SQL remediations so the source table can support defensible KPI development, dimensional modeling, and BI consumption.

The objective is to standardize types and categories, reduce ambiguity, and enforce structural readiness for downstream star-schema design.

This step prepares data quality and semantics. It does not define KPI formulas.

---

## Explainability-First Role in the Pipeline

Cleaning is treated as governed transformation, not ad-hoc preprocessing.

Each remediation in this folder is directly traceable to issues surfaced in `01_Profiling` and is documented as explicit SQL logic. This reduces interpretation drift and preserves auditability across later KPI and semantic-model layers.

---

## Scope

### Input

- Source table: `dbo.LI_SPARCS_2015_25_Inpatient`

### SQL Artifacts

- `02_SQL/2_1_Currency_Formatting.sql`
- `02_SQL/2_2_Standardize_ZIP_data.sql`
- `02_SQL/2_3_Standardize_Unknown_cat.sql`
- `02_SQL/2_4_Admission_Category_Normalization.sql`
- `02_SQL/2_5_PatientDisposition_Cat_Standardiz.sql`
- `02_SQL/2_6_nvarcharMax_trimming.sql`
- `02_SQL/2_7_add_surrogate_PrimaryKey.sql`
- `02_SQL/2_8_payment_typology_grouping.sql`

### Evidence Artifacts

- `image.png` through `image-12.png`

---

## What Was Executed

### 1. Monetary Field Type Correction

`2_1_Currency_Formatting.sql` converts `Total_Charges` and `Total_Costs` from currency-formatted text to numeric (`DECIMAL(18,2)`) via add-convert-replace pattern.

### 2. ZIP Category Standardization

`2_2_Standardize_ZIP_data.sql` creates `Zip3_Category` and maps values into:

- `In-State Zip3`
- `Out-of-State`
- `Unknown`

### 3. Demographic Placeholder Standardization

`2_3_Standardize_Unknown_cat.sql` creates standardized fields:

- `Race_Std`
- `Ethnicity_Std`

and normalizes inconsistent placeholders and unknown states.

### 4. Admission Category Normalization

`2_4_Admission_Category_Normalization.sql` creates `Type_of_Admission_Std` and maps admission labels into:

- `Unplanned`
- `Elective`
- `Unknown`
- `Other`

### 5. Disposition Grouping

`2_5_PatientDisposition_Cat_Standardiz.sql` creates `Patient_Disposition_Grouped` and consolidates raw discharge labels into high-level buckets (`Home`, `Skilled Nursing / Rehab`, `Death`, `Unknown`, `Other`).

### 6. NVARCHAR(MAX) Right-Sizing

`2_6_nvarcharMax_trimming.sql` identifies unbounded text columns, profiles actual maximum lengths, and alters columns to bounded NVARCHAR sizes where appropriate.

### 7. Surrogate Key Introduction

`2_7_add_surrogate_PrimaryKey.sql` adds `Encounter_ID INT IDENTITY(1,1)` and enforces primary key constraint for relational integrity.

### 8. Payer Typology Grouping

`2_8_payment_typology_grouping.sql` creates `Payment_Typology_Group` and maps detailed payer descriptions into analytical groups:

- `Medicare`
- `Medicaid`
- `Commercial`
- `Self-Pay`
- `Other`
- `Unknown`

---

## Validation and Risk Notes

- Distribution sanity checks are embedded in each script to verify mapping behavior.
- `Other` bucket proportions are intentionally inspected for admission, disposition, and payer groupings to detect over-aggregation risk.
- Disposition grouping indicates that further decomposition of `Other` may be required in dimensional modeling to preserve operational interpretability.

---

## Output Contract to Step 03

This step produces a cleaned, model-ready base with:

- Numeric financial fields suitable for aggregation
- Standardized categorical columns for admission, disposition, demographic, ZIP, and payer analysis
- Bounded text widths for better storage/indexing behavior
- Stable surrogate key (`Encounter_ID`) for downstream joins and fact construction

This output is the structural handoff into `03_Analytical_Data_Modeling`.

---

## Position in End-to-End Lifecycle

- `00_DB_Creation`: database and ingestion readiness
- `01_Profiling`: data quality diagnostics
- `02_Data_Cleaning`: deterministic remediation and standardization (this step)
- `03_Analytical_Data_Modeling`: analytical schema and dimensions
- `04_Analytical_Validation`: reconciliation and QA
- `05_KPI_Dev`: KPI definition and certification
- `06_PBI_Semantic_Model`: semantic contract and governed measures
- `07_Excel_Executive_Analytics`: executive consumption layer

---

## Folder Contents

```text
02_Data_Cleaning/
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
`-- 02_SQL/
    |-- 2_1_Currency_Formatting.sql
    |-- 2_2_Standardize_ZIP_data.sql
    |-- 2_3_Standardize_Unknown_cat.sql
    |-- 2_4_Admission_Category_Normalization.sql
    |-- 2_5_PatientDisposition_Cat_Standardiz.sql
    |-- 2_6_nvarcharMax_trimming.sql
    |-- 2_7_add_surrogate_PrimaryKey.sql
    `-- 2_8_payment_typology_grouping.sql
```
