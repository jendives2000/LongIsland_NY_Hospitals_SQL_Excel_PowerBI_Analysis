# 07 - Excel Executive Analytics

## Purpose

This step operationalizes validated KPI outputs for executive self-service analysis in Excel.

It demonstrates how the same governed KPI definitions can be consumed outside Power BI without logic drift, shadow formulas, or interpretation risk.

---

## Portfolio Positioning

This folder showcases serious Data Analyst portfolio capability for:

- Healthcare executives: decision-ready KPI consumption
- Senior data analysts: reproducible metric lineage and reconciliation safety
- Recruiters: enterprise-grade governance from SQL to BI to Excel

---

## Explainability-First Principle (Project Rule)

Explainability-first is enforced as an operating rule, not a writing style.

In Step 07 this means:

- Context KPIs are read before outcome KPIs
- Excel consumes approved KPI outputs rather than redefining formulas
- Interpretation guardrails are explicit for executive users

---

## Lifecycle Role of Excel

Excel appears in two different roles in this repository:

- Step 05 (`05_KPI_Dev`): validation and reconciliation
- Step 07 (`07_Excel_Executive_Analytics`): executive consumption

Step 07 does not revalidate KPI definitions. It consumes governed outputs.

---

## SQL Integration Contract

Primary artifact:

- `07_SQL/07_01_vw_Excel_KPI_Executive_FacilityYear.sql`

Governed output consumed by workbook:

- `dbo.vw_Excel_KPI_Executive_FacilityYear`

Contract characteristics:

- Facility-Year grain
- Cross-KPI integration in one executive surface
- No KPI business logic embedded in Excel

---

## Consumption Rules

- No KPI formulas authored in workbook cells
- No Pivot calculated fields for KPI definitions
- PivotTables consume native SQL columns
- Visual tiles and scorecards read values from pivots only

These controls keep KPI truth consistent across SQL, Power BI, and Excel.

---

## Executive Artifacts

- Dashboard workbook: `Dashboards/Executive_KPI_Overview.xlsx`
- Reusable template: `Templates/Executive_Pivot_Template.xlsx`
- Executive interpretation guide: `Executive_Guide_How_to_Read_the_Report.md`

---

## Governance Boundary

- KPI logic authority: Step 05
- Semantic shaping authority: Step 06
- Executive Excel consumption: Step 07

Any KPI-definition change must start upstream in Step 05.

---

## Folder Contents

```text
07_Excel_Executive_Analytics/
|-- README.md
|-- Executive_Guide_How_to_Read_the_Report.md
|-- 07_SQL/
|   `-- 07_01_vw_Excel_KPI_Executive_FacilityYear.sql
|-- Dashboards/
|   `-- Executive_KPI_Overview.xlsx
`-- Templates/
    `-- Executive_Pivot_Template.xlsx
```
