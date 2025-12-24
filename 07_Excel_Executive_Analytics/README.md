# 07 — Excel Executive Analytics

This step operationalizes the validated KPI framework for **executive self-service analysis in Excel**.

While Power BI is used for curated dashboards and storytelling, Excel remains the **primary analytical tool for many executives** in real enterprise environments.  
This folder demonstrates how the **same governed KPI definitions and semantic model** can be consumed directly in Excel — without re-implementing logic, without metric drift, and without BI-tool dependency.

> **Core idea:**  
> Excel is not used here to *define* metrics — it is used to *consume* them safely and confidently.

---

## Why this step exists

In many organizations:

- Executives are deeply fluent in Excel
- Strategic decisions are made inside spreadsheets
- Ad-hoc slicing, exporting, annotating, and scenario exploration happen **outside BI tools**
- BI publishing cycles are often slower than executive needs

This step acknowledges that reality and turns it into a **strength**, by:

- Reusing the validated KPI layer from Step 05
- Respecting the semantic model defined in Step 06
- Enabling executives to answer real questions **directly in Excel**
- Preserving governance, consistency, and auditability

Excel here is a **trusted analytical interface**, not a calculation engine.

---

<details>
<summary><strong>📑 Table of Contents</strong></summary>

- [07 — Excel Executive Analytics](#07--excel-executive-analytics)
  - [Why this step exists](#why-this-step-exists)
  - [Positioning of Excel in the Analytics Lifecycle](#positioning-of-excel-in-the-analytics-lifecycle)
  - [Design Principles](#design-principles)
  - [What Belongs in This Folder (and What Does Not)](#what-belongs-in-this-folder-and-what-does-not)
    - [✅ Belongs here](#-belongs-here)
    - [❌ Does NOT belong here](#-does-not-belong-here)
  - [Excel Consumption Patterns](#excel-consumption-patterns)
    - [Pattern A — SQL KPI Fact Consumption](#pattern-a--sql-kpi-fact-consumption)
    - [Pattern B — Semantic Model Consumption (optional)](#pattern-b--semantic-model-consumption-optional)
  - [Executive Dashboard Types](#executive-dashboard-types)
    - [1. Executive KPI Overview](#1-executive-kpi-overview)
    - [2. KPI Deep-Dive Dashboards](#2-kpi-deep-dive-dashboards)
    - [3. Ad-Hoc Exploration Templates](#3-ad-hoc-exploration-templates)
  - [Folder Structure](#folder-structure)

</details>

---

## Positioning of Excel in the Analytics Lifecycle

Excel appears **twice** in this project — intentionally and with different roles:

| Step | Role of Excel | Purpose |
|----|----|----|
| `05_Validation` | Validation tool | Prove KPI correctness |
| `07_Excel_Executive_Analytics` | Executive analytics client | Enable decision-making |

This folder does **not** repeat validation.  
It assumes KPIs are already correct and focuses on **usability and adoption**.

---

## Design Principles

The Excel assets in this folder follow strict principles:

1. **No KPI logic in Excel**
   - No hard-coded formulas for rates
   - No re-implementation of SQL logic
2. **Same grain as KPI outputs**
   - Facility-Year or Facility-Month (where applicable)
3. **Pivot-driven, not formula-driven**
   - PivotTables and PivotCharts are the primary mechanism
4. **Exploration without risk**
   - Executives can filter and slice
   - They cannot accidentally redefine metrics
5. **Visual clarity over density**
   - Executive-readable layouts
   - Minimal clutter, clear labels

Excel is treated as a **safe window** into the KPI layer.

---

## What Belongs in This Folder (and What Does Not)

### ✅ Belongs here

- Executive dashboards
- PivotTables & PivotCharts
- Slicers and timelines
- Facility and time comparisons
- Export-ready summary tables
- Templates for executive reuse

### ❌ Does NOT belong here

- Reconciliation checks
- Row-level audit tables
- Green/red validation flags
- SQL parity formulas
- Metric definitions

Those belong in `05_Validation`.

---

## Excel Consumption Patterns

Excel workbooks in this folder consume data using one of the following **approved patterns**:

### Pattern A — SQL KPI Fact Consumption
Excel connects (via Power Query or direct import) to:

- `Fact_KPI_*` tables produced in Step 05
- Governed dimensions (`Dim_Facility`, `Dim_Date`, etc.)

This pattern ensures:
- Deterministic results
- Easy reconciliation if needed
- No hidden transformations

### Pattern B — Semantic Model Consumption (optional)
Excel connects directly to the Power BI semantic model created in Step 06.

This allows:
- Use of pre-defined measures
- Identical behavior to Power BI visuals
- Zero metric duplication

Both patterns preserve **single-source-of-truth semantics**.

---

## Executive Dashboard Types

Typical Excel dashboards in this folder include:

### 1. Executive KPI Overview
High-level snapshot:
- LOS
- Unplanned Admission Rate
- Mortality Rate
- Margin Pressure

Used for:
- Monthly reviews
- Board prep
- Leadership briefings

### 2. KPI Deep-Dive Dashboards
Focused exploration of a single KPI:
- LOS distribution
- Disposition outcomes
- Payer mix and margin pressure

Used for:
- Root-cause analysis
- Facility comparisons
- Follow-up questions

### 3. Ad-Hoc Exploration Templates
Reusable Excel templates allowing executives to:
- Select facility
- Select time period
- Slice by category
- Export results

---

## Folder Structure

Recommended structure:

```text
07_Excel_Executive_Analytics/
│
├─ README.md
│
├─ Dashboards/
│   ├─ Executive_KPI_Overview.xlsx
│   ├─ LOS_Deep_Dive.xlsx
│   └─ Financial_Pressure_Analysis.xlsx
│
├─ Templates/
│   ├─ Executive_Pivot_Template.xlsx
│   └─ KPI_Exploration_Template.xlsx
│
└─ Screenshots/
    ├─ Executive_Overview.png
    └─ LOS_Distribution.png
```