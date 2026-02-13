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

- Step 05 governed KPI outputs from `05_KPI_Dev`
- Conformed dimensions (`Dim_Facility`, `Dim_Year`, `Dim_Payer`, `Dim_Disposition`, others as used)
- PBIP artifacts in `03_PowerBI_Model/PBI_Project`

---

## Folder Contracts

- `01_Fact_KPI_SQL`: SQL scripts that materialize `Fact_KPI_*` tables
- `02_Dimensions_Reference`: dimension documentation and usage rules
- `03_PowerBI_Model`: semantic model and report artifacts (includes report structure guide)
- `04_KPI_Data_Dictionary`: metadata and business-definition contract
- `05_Validation`: semantic parity and reconciliation controls

---

## Governance Boundary

- Step 05 defines KPI truth.
- Step 06 shapes and serves KPI truth.
- Step 06 does not redefine KPI formulas.

Any KPI logic change must return to Step 05.

---

## Folder Contents

```text
06_PBI_Semantic_Model/
|-- README.md
|-- 01_Fact_KPI_SQL/
|-- 02_Dimensions_Reference/
|-- 03_PowerBI_Model/
|-- 04_KPI_Data_Dictionary/
`-- 05_Validation/
```
