# 01 - Data Profiling

## Purpose

This step establishes the baseline data quality and structural risk profile of the inpatient source before cleaning, modeling, and KPI development.

The objective is to identify quality defects early, distinguish true data issues from import artifacts, and define a defensible remediation plan for downstream analytics.

This step is descriptive and diagnostic. It does not define KPI logic.

---

## Explainability-First Role in the Pipeline

Profiling is used here as a governance checkpoint:

- Confirm what is analytically reliable before transformation
- Surface defects that would bias clinical, operational, or financial interpretation
- Convert findings into explicit cleaning actions consumed by `02_Data_Cleaning`

This prevents hidden quality problems from propagating into KPI and BI layers.

---

## Scope

### Input

- Source table: `dbo.LI_SPARCS_2015_25_Inpatient`

### SQL Artifacts

- `01_SQL/Columns_Profiling.sql`
- `01_SQL/BirthWeight_correction.sql`

### Evidence Artifact

- `image.png` (re-profiling evidence after Birth Weight type correction)

---

## What Was Executed

`Columns_Profiling.sql` performs schema-driven, column-by-column profiling and writes results to `#ColumnProfile`.

For each column, it computes:

- Minimum value
- Maximum value
- Null count
- Distinct count
- Mode (most frequent value)
- Numeric-only metrics where applicable:
  - Mean
  - Median
  - Standard deviation
  - Zero-value count

Note: this script computes null counts, not explicit null percentages.

`BirthWeight_correction.sql` remediates an import typing issue by converting `Birth_Weight` from text to integer semantics, then restores the canonical column name.

---

## Key Findings and Analytical Risk

- Monetary fields imported as text with symbols (`Total_Charges`, `Total_Costs`), blocking reliable financial aggregation
- Geographic quality gaps (`Zip_Code_3_digits` nulls and non-numeric placeholders)
- Inconsistent categorical labels in operational fields (`Type_of_Admission`, `Patient_Disposition`)
- High-cardinality clinical descriptors requiring dimensional handling in the analytical model
- Missing surrogate encounter identifier at this stage
- Text-width and unbounded text patterns affecting performance and governance

### Birth Weight Clarification

A perceived max value issue (900) was traced to lexical comparison from text typing, not source-data truncation. After conversion to numeric typing, distribution behavior aligned with expected clinical ranges. Evidence is documented in `image.png`.

---

## Output Contract to Step 02

This step produces a remediation contract consumed by `02_Data_Cleaning`:

- Currency normalization for cost/charge fields
- Category normalization for admission/disposition semantics
- Placeholder and unknown handling for demographic and geographic fields
- Text trimming and width control
- Surrogate key introduction
- Payer-group standardization support

---

## Position in End-to-End Lifecycle

- `00_DB_Creation`: source ingestion and base schema setup
- `01_Profiling`: quality diagnostics and issue identification (this step)
- `02_Data_Cleaning`: deterministic remediation and standardization
- `03_Analytical_Data_Modeling`: star-schema-aligned analytical structures
- `04_Analytical_Validation`: SQL and Excel reconciliation checks
- `05_KPI_Dev`: KPI definition and certification
- `06_PBI_Semantic_Model`: BI semantic contract and governed measures
- `07_Excel_Executive_Analytics`: executive consumption layer

---

## Folder Contents

```text
01_Profiling/
|-- README.md
|-- image.png
`-- 01_SQL/
    |-- Columns_Profiling.sql
    `-- BirthWeight_correction.sql
```
