# 07 — Excel Executive Analytics

This step operationalizes the validated KPI framework for **executive self-service analysis in Excel**.

While Power BI is used for curated dashboards and storytelling, Excel remains the **primary analytical tool for many executives** in real enterprise environments.

This folder demonstrates how the **same governed KPI definitions and semantic model** can be consumed directly in Excel — without re-implementing logic, without metric drift, and without BI-tool dependency.

> **Core idea:**  
> Excel is not used here to define metrics — it is used to consume them safely and confidently.

---

## Why this step exists

In many organizations:

- Executives are deeply fluent in Excel  
- Strategic decisions are made inside spreadsheets  
- Ad-hoc slicing, exporting, annotating, and scenario exploration happen outside BI tools  
- BI publishing cycles are often slower than executive needs  

This step turns that operational reality into a governance strength by:

- Reusing the validated KPI layer from Step 05  
- Respecting the semantic structure defined in Step 06  
- Enabling executive exploration without metric mutation  
- Preserving traceability and auditability  

Excel here is a **trusted analytical surface**, not a calculation engine.

---

<details>
<summary><strong>📑 Table of Contents</strong></summary>

- [07 — Excel Executive Analytics](#07--excel-executive-analytics)
  - [Why this step exists](#why-this-step-exists)
  - [Positioning of Excel in the Analytics Lifecycle](#positioning-of-excel-in-the-analytics-lifecycle)
  - [Architecture Overview](#architecture-overview)
  - [Explainability-First Design Principles](#explainability-first-design-principles)
    - [1. No KPI Logic in Excel](#1-no-kpi-logic-in-excel)
    - [2. Grain Preservation](#2-grain-preservation)
    - [3. Pivot-Driven Consumption](#3-pivot-driven-consumption)
    - [4. Interpretive Guardrails](#4-interpretive-guardrails)
    - [5. Transparent Data Lineage](#5-transparent-data-lineage)
  - [Governance \& Trust Guarantees](#governance--trust-guarantees)
  - [Explainability Audit Results](#explainability-audit-results)
    - [Check 1 — No KPI formulas](#check-1--no-kpi-formulas)
    - [Check 2 — No Pivot Calculated Fields](#check-2--no-pivot-calculated-fields)
    - [Check 3 — End-to-End Refresh Integrity](#check-3--end-to-end-refresh-integrity)
    - [Check 4 — Spot Reconciliation](#check-4--spot-reconciliation)
  - [Excel Consumption Pattern](#excel-consumption-pattern)
    - [Pattern A — SQL KPI Fact Consumption](#pattern-a--sql-kpi-fact-consumption)
  - [Executive Artifacts](#executive-artifacts)
    - [Executive Dashboard](#executive-dashboard)
    - [Reusable Template](#reusable-template)
    - [Interpretive Guide](#interpretive-guide)
  - [Folder Structure](#folder-structure)
  - [Final Position](#final-position)

</details>

---

## Positioning of Excel in the Analytics Lifecycle

Excel appears twice in this project, intentionally:

| Step | Role of Excel | Purpose |
|------|--------------|----------|
| `05_Validation` | Validation tool | Prove KPI correctness |
| `07_Excel_Executive_Analytics` | Executive analytics client | Enable safe decision-making |

Step 07 does not repeat validation.  
It assumes KPI correctness and focuses on usability, exploration, and adoption.

---

## Architecture Overview

Excel consumes a **thin integration SQL view**, defined in:

```
07_SQL/07_01_vw_Excel_KPI_Executive_FacilityYear.sql
```

The view:

- Preserves one row per Facility-Year
- Integrates all governed KPI outputs
- Includes PeerGroup context for slicing
- Contains zero KPI logic
- Standardizes column naming for executive pivots

All KPI calculations occur upstream in Step 05.  
Excel receives only pre-computed results.

---

## Explainability-First Design Principles

### 1. No KPI Logic in Excel

- No formulas computing rates  
- No pivot calculated fields  
- No derived business logic  
- No Excel-based transformations  

Excel cannot redefine truth.

---

### 2. Grain Preservation

- One row per Facility-Year  
- PeerGroup added without duplicating rows  
- Integration view validated for uniqueness  

---

### 3. Pivot-Driven Consumption

- Native columns only  
- SUM and AVERAGE aggregation only  
- GETPIVOTDATA used strictly for read-back display  
- Charts pull values from PivotTables only  

---

### 4. Interpretive Guardrails

Dashboard includes static guidance:

- Read as distribution and structural exposure, not ranking  
- Interpret outcome KPIs after context KPIs  
- Metrics originate from validated SQL logic  

---

### 5. Transparent Data Lineage

Data Flow:

```
SQL KPI Views
    ↓
07_01_vw_Excel_KPI_Executive_FacilityYear.sql
    ↓
Excel 01_Data sheet
    ↓
PivotTable
    ↓
GETPIVOTDATA
    ↓
Charts & Scoreboard
```

No transformation layer exists inside Excel.

---

## Governance & Trust Guarantees

This folder guarantees:

- All metrics originate from validated SQL logic  
- Excel outputs reconcile exactly to SQL view values  
- No hidden business rules exist in spreadsheets  
- Metric definitions remain consistent across:
  - SQL  
  - Power BI  
  - Excel  

---

## Explainability Audit Results

**Status: PASSED (All 4 Checks)**

### Check 1 — No KPI formulas

- `01_Data` contains only flat SQL output  
- `02_Pivots` contains only native pivot aggregations  
- `03_Dashboard` uses GETPIVOTDATA read-backs only  
- No cell computes or transforms a KPI  

---

### Check 2 — No Pivot Calculated Fields

All value fields reference native SQL columns directly.

---

### Check 3 — End-to-End Refresh Integrity

- SQL view refresh updates entire workbook  
- Slicers propagate through pivot safely  
- No recalculation logic introduced  

---

### Check 4 — Spot Reconciliation

Example: Nassau University Medical Center (2015)

All KPI values match SQL output exactly, including:

- Severity_Mix_Index  
- Unplanned_Admission_Rate  
- Avg_LOS  
- Mortality_Rate  
- Margin_Pressure_Ratio  
- NegMargin_Rate  
- Total_Costs  
- Total_Charges  

Governance contract fully honored.

---

## Excel Consumption Pattern

### Pattern A — SQL KPI Fact Consumption

Excel connects directly to:

```
dbo.vw_Excel_KPI_Executive_FacilityYear
```

Defined in:

```
07_SQL/07_01_vw_Excel_KPI_Executive_FacilityYear.sql
```

Benefits:

- Deterministic results  
- Minimal refresh surface  
- No cross-table Excel joins  
- No metric duplication  
- Easy SQL reconciliation  

---

## Executive Artifacts

### Executive Dashboard

```
Dashboards/Executive_KPI_Overview.xlsx
```

High-level cross-KPI view:

- Severity Mix  
- Unplanned Admission Rate  
- Avg LOS  
- Mortality Rate  
- Margin Pressure  
- Negative Margin Rate  

---

### Reusable Template

```
Templates/Executive_Pivot_Template.xlsx
```

- Pre-wired SQL connection  
- Controlled slicers  
- No KPI logic  

---

### Interpretive Guide

```
Templates/Executive_Guide_How_to_Read_the_Report.md
```

- Structural interpretation guidance  
- Reinforces explainability-first discipline  

---

## Folder Structure

```text
07_Excel_Executive_Analytics/
│
├─ 07_SQL/
│   └─ 07_01_vw_Excel_KPI_Executive_FacilityYear.sql
│
├─ Dashboards/
│   └─ Executive_KPI_Overview.xlsx
│
├─ Templates/
│   ├─ Executive_Pivot_Template.xlsx
│   └─ Executive_Guide_How_to_Read_the_Report.md
│
├─ Screenshots/
│
└─ README.md
```

---

## Final Position

Step 07 proves that:

* Governance survives outside BI tooling
* KPI definitions remain immutable across environments
* Executive exploration does not introduce metric drift
* The architecture is tool-agnostic and production-ready

Excel becomes a **controlled analytical interface**, not a shadow calculation engine.