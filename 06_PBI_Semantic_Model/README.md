# 06 - Power BI Semantic Model

## Purpose

This folder formalizes the KPI semantic layer used to communicate healthcare performance signals to executives and analytics stakeholders.

It converts validated KPI logic into a governed BI contract that is reusable, auditable, and decision-ready.

---

## Portfolio Value

This step demonstrates enterprise BI capability across:

- Metric governance and semantic modeling discipline
- Explainability-safe KPI interpretation
- Cross-tool consistency (SQL, Power BI, Excel)
- Documentation quality for executive and recruiter review

---

## Explainability-First Principle (Project Rule)

Explainability-first is a project operating principle.

In Step 06, this is enforced by:

- Context-first reading order (case mix, intake, reimbursement before outcomes)
- Separation of contextual signals from performance judgments
- Recalculation of rates from additive totals (no misleading aggregation shortcuts)

---

## Inputs and Dependencies

- Step 05 governed KPI outputs from [`05_KPI_Dev`](/05_KPI_Dev/README.md)
- Conformed dimensions (`Dim_Facility`, `Dim_Year`, `Dim_Payer`, `Dim_Disposition`, others as used)
- PBIP artifacts in [`03_PowerBI_Model/PBI_Project`](/06_PBI_Semantic_Model/03_PowerBI_Model/PBI_Project/)

---

## Folder Contracts

- [`01_Fact_KPI_SQL`](/06_PBI_Semantic_Model/01_Fact_KPI_SQL/README.md): SQL scripts that materialize `Fact_KPI_*` tables
- [`02_Dimensions_Reference`](/06_PBI_Semantic_Model/02_Dimensions_Reference/README.md): dimension documentation and usage rules
- [`03_PowerBI_Model`](/06_PBI_Semantic_Model/03_PowerBI_Model/README.md): semantic model and report artifacts (includes report structure guide)
- [`04_KPI_Data_Dictionary`](/06_PBI_Semantic_Model/04_KPI_Data_Dictionary/README.md): metadata and business-definition contract
- [`05_Validation`](/06_PBI_Semantic_Model/05_Validation/README.md): semantic parity and reconciliation controls

---

## Governance Boundary

- Step 05 defines KPI truth.
- Step 06 shapes and serves KPI truth.
- Step 06 does not redefine KPI formulas.

Any KPI logic change must return to Step 05.

---

## Folder Structure

```text
06_PBI_Semantic_Model/
|-- README.md
|-- 01_Fact_KPI_SQL/
|   |-- 06_01_01_Severity_Mix/
|   |-- 06_01_01_xxx/
|   |-- 06_01_02_Fact_KPI_PayerMix/
|   |-- 06_01_03_Fact_KPI_Unplanned/
|   |-- 06_01_04_Fact_KPI_Disposition/
|   |-- 06_01_05_Fact_KPI_LOS_Summary/
|   |-- 06_01_06_Fact_KPI_Mortality/
|   |-- 06_01_07_Fact_KPI_FinancialPressure/
|   `-- README.md
|-- 02_Dimensions_Reference/
|   |-- Dim_Year/
|   `-- README.md
|-- 03_PowerBI_Model/
|   |-- PBI_Project/
|   |-- screenshots/   (1 validation images)
|   |-- PowerBI_Report_Structure.md
|   `-- README.md
|-- 04_KPI_Data_Dictionary/
|   `-- README.md
`-- 05_Validation/
    `-- README.md
```
