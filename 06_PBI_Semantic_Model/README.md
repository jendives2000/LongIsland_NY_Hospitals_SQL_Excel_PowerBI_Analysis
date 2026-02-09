# 06 — Power BI Semantic Model

This folder formalizes a **Power BI–ready semantic model** on top of the validated KPI layer from `05_KPI_Dev`.

The KPI Integration Layer provides a stable, documented set of **KPI fact tables and shared dimensions** that:

* Ensures consistent metric definitions across all dashboards
* Eliminates duplicated logic and inconsistent calculations
* Enables reproducible results across Power BI, SQL, and Excel validation
* Supports rapid dashboard development without reworking the model

All narrative and measure definitions in this layer are grounded in the healthcare explainability frameworks referenced in the main repository README.

---

<details>
<summary><strong>Table of Contents</strong></summary>

- [06 — Power BI Semantic Model](#06--power-bi-semantic-model)
  - [Why This Layer Exists](#why-this-layer-exists)
  - [KPI Integration Layer](#kpi-integration-layer)
  - [1. KPI Facts](#1-kpi-facts)
    - [Guidelines](#guidelines)
    - [How Facts Connect to Dimensions](#how-facts-connect-to-dimensions)
  - [2. Dimensions](#2-dimensions)
    - [Guidelines](#guidelines-1)
    - [Role-Playing Dates](#role-playing-dates)
  - [3. Star Schema for BI](#3-star-schema-for-bi)
    - [Guidelines](#guidelines-2)
    - [Recommended Relationship Rules](#recommended-relationship-rules)
  - [4. KPI Mapping](#4-kpi-mapping)
  - [Best Practices](#best-practices)
    - [Grain \& Additivity](#grain--additivity)
    - [Measures vs Columns](#measures-vs-columns)
    - [Naming Conventions](#naming-conventions)
    - [Performance \& Refresh](#performance--refresh)
    - [Governance \& Documentation](#governance--documentation)
    - [Validation Workflow](#validation-workflow)
  - [Completion Criteria](#completion-criteria)
  - [Folder Structure](#folder-structure)

</details>

---

## Why This Layer Exists

KPIs from `05_KPI_Dev` have been reconciled and validated. To bridge between SQL outputs and executive dashboards, we need a semantic model that guarantees:

* **Consistent grain** (what a row represents)
* **Predictable relationships** (how dimensions filter facts)
* **Reusable dimensions** (one definition across all KPIs)
* **Correct measure aggregation** (rates computed from stored totals, not summed precomputed rates)

Without this layer, BI becomes fragile:

* Metric logic duplicated across visuals
* Filter paths ambiguous or conflicting
* Totals inconsistent across reports
* New visuals require new logic instead of reusing measures

The semantic model is the **governance contract** ensuring:

* **Single source of truth** for each metric
* **One relationship path** per analytical question
* **Reproducible results** across tools (Power BI, Excel, SQL)

---

## KPI Integration Layer

The KPI Integration Layer sits between:

* **SQL KPI scripts** (source of metric truth)
* **Power BI dashboards** (metric consumption and storytelling)

It contains:

* A curated set of **KPI fact tables** (each at a clear, documented grain)
* **Conformed dimensions** (Facility, Date, Payer, Severity, Disposition)
* **Semantic measures** (defined once, reused across all pages)

<details>
<summary><strong>Technical definition</strong></summary>

A KPI Integration Layer is a curated semantic representation that:

* Enforces dimensional consistency (same definitions across all KPIs)
* Prevents metric drift (measures owned by layer, not recreated in visuals)
* Optimizes for BI query patterns (star schema, low-cardinality design)
* Enables deterministic validation (Excel pivot reconciliation matches SQL outputs exactly)

</details>

---

## 1. KPI Facts

KPI facts are **analysis-ready tables** designed for Power BI consumption. They balance:

* **Aggregation** (small enough to load and refresh quickly)
* **Richness** (detailed enough to support slicing and drill-down)
* **Reconciliation** (storing both numerators and denominators for rates)

### Guidelines

* **Define grain explicitly** in table documentation.
  * Example: "One row per Facility–Year–Severity_Bucket"
* Prefer **aggregated KPI fact tables** for dashboard consumption.
  * Encounter-level exports exist for validation, not for default visuals.
* Include **reconciliation totals** alongside derived metrics.
  * Example: Store death count + total encounters separately, so mortality rate can recompute correctly under filtering.
* Keep fact tables **narrow** (integer keys + essential numeric columns).
* Avoid storing precomputed rates or averages as the only measure.
  * Store raw totals; let Power BI DAX compute derived metrics.

### How Facts Connect to Dimensions

Facts connect to dimensions through **surrogate keys**:

* `Facility_Key` → `Dim_Facility`
* `Year`, `Month_Number` → `Dim_Date`
* `ClinicalClass_Key` or severity group → `Dim_ClinicalClass` (if reused across facts)
* Low-cardinality category attributes (e.g., `LOS_Bucket`, `Disposition_Grouped`) can be:
  * Stored directly in the fact as columns, or
  * Modeled as small dimensions if reused broadly

---

## 2. Dimensions

Dimensions provide the **consistent slicing vocabulary** for the entire KPI suite. Reusing the same dimensions across all facts guarantees predictable filter behavior.

### Guidelines

* Dimensions should be **conformed** (shared, consistent definitions).
* Use a single `Dim_Date` with standard attributes:
  * Year, Quarter, Month_Number, Month_Name
* Keep dimension **keys stable** (avoid regenerating during refresh).
* Add only attributes that support slicing and storytelling.
  * Avoid sparse "junk dimensions" with many unused columns.

Dimensions are owned by the Core Data Model. The KPI Integration Layer consumes but does not redefine them.

### Role-Playing Dates

This project primarily anchors KPIs on **discharge date**. If multiple date roles are needed:

* Create role-playing views (e.g., `Dim_Date_Discharge`, `Dim_Date_Admission`) without duplicating the physical table, or
* Use a single `Dim_Date` with separate foreign keys (only when those keys exist in the source facts)

---

## 3. Star Schema for BI

A star schema is the most reliable structure for Power BI:

* **Facts in the center** (KPI outputs)
* **Dimensions radiating outward** (Facility, Date, Payer, Severity, Disposition, etc.)

This design:

* Minimizes filter-path ambiguity
* Prevents many-to-many relationship conflicts
* Improves query performance
* Makes visual logic straightforward

### Guidelines

* Use **one-to-many** relationships from dimensions to facts.
* Prefer **single-direction** filtering (Dimensions → Facts).
* Avoid many-to-many relationships unless unavoidable.
* Keep clear separation between:
  * **Semantic measures** (DAX calculations)
  * **Physical columns** (SQL materialized values)

### Recommended Relationship Rules

* Dimensions filter facts (one direction only).
* No direct relationships between facts.
* For cross-fact visuals:
  * Use conformed dimensions + measures
  * Avoid fact-to-fact bridges unless strictly necessary

---

## 4. KPI Mapping

The table below maps the 7 KPIs to BI-ready fact tables, their grain, and primary dimensions.

Naming convention: `Fact_KPI_*` prevents confusion between encounter-level sources and KPI-level outputs.

| KPI                                  | Fact Table                                  | Grain                                          | Core Measures                                  | Primary Dimensions              |
| ------------------------------------ | ------------------------------------------- | ---------------------------------------------- | ---------------------------------------------- | ------------------------------- |
| Severity Mix (Context)               | `Fact_KPI_SeverityMix`                      | Facility–Year                                  | Severity Mix Index, Encounter Count            | Date, Facility, ClinicalClass   |
| Payer Mix (Context)                  | `Fact_KPI_PayerMix`                         | Facility–Year–PayerGroup                       | Payer Encounters, Payer Share %                | Date, Facility, Payer           |
| Unplanned Intake (Context)           | `Fact_KPI_Unplanned`                        | Facility–Year                                  | Unplanned Count, Total Encounters, Rate        | Date, Facility                  |
| Length of Stay (Throughput)          | `Fact_KPI_LOS_Summary` + Distribution       | Summary: Facility–Year; Distribution: Bucket  | Avg/Min/Max LOS, Bucket Counts & Shares        | Date, Facility, LOS Bucket      |
| Mortality (Outcome Risk)             | `Fact_KPI_Mortality`                        | Facility–Year                                  | Death Count, Total Encounters, Rate            | Date, Facility                  |
| Cost & Margin Pressure (Financial)   | `Fact_KPI_FinancialPressure`                | Facility–Year                                  | Avg MCost, Total Costs, Margin Pressure        | Date, Facility                  |
| Disposition (Exit Flow)              | `Fact_KPI_Disposition`                      | Facility–Year–DispositionCategory              | Disposition Count, Disposition Share %         | Date, Facility, Disposition     |

<details>
<summary><strong>Why some KPIs have multiple fact tables</strong></summary>

Some KPIs naturally produce multiple analysis-ready views:

* **LOS** has both a *summary view* (avg/min/max) and a *distribution view* (bucketed counts).

Separating them improves:

* Model clarity (each fact has one grain)
* Performance (smaller, focused tables)
* Visual design (summary cards vs distribution charts can use different grains)

</details>

---

## Best Practices

### Grain & Additivity

Before building measures, document:

* **Grain is explicit** for every fact table.
* Measures are classified as:
  * **Additive** (counts, sums—safe to aggregate across all dimensions)
  * **Semi-additive** (snapshots—safe to aggregate across some dimensions)
  * **Non-additive** (rates, averages—must compute from stored numerators/denominators, not sum precomputed values)

For rates and averages in Power BI:

* Compute from stored totals rather than summing precomputed rates.

---

### Measures vs Columns

Use SQL to materialize:

* Surrogate keys
* Low-cardinality descriptive categories
* Reconciliation totals (numerators and denominators for rates)

Use Power BI DAX measures for:

* Ratios and rates (computed from totals)
* Weighted averages (dynamic aggregations)
* Time-based selections (YTD, prior year, etc.)

This separation reduces drift and keeps the model extensible.

---

### Naming Conventions

Recommended conventions:

* **Facts**: `Fact_KPI_*` (e.g., `Fact_KPI_SeverityMix`)
* **Dimensions**: `Dim_*` (e.g., `Dim_Facility`)
* **Measures**: `m_*` (e.g., `m_MortalityRate`, `m_AvgLOS`)
* **Columns**:
  * Keys end with `_Key`
  * Prefer measure definitions over rate columns

---

### Performance & Refresh

* Prefer aggregated KPI facts for visuals.
* Keep encounter-level exports separate (used for validation, not default consumption).
* Use incremental refresh where possible (date-partitioned facts).
* Minimize cardinality:
  * Store `Month_Number` rather than full dates when month-level slicing is sufficient.

---

### Governance & Documentation

* Document metric ownership and definitions in the Data Dictionary (folder `04_KPI_Data_Dictionary`).
* Implement Row-Level Security (RLS) by Facility if sharing beyond local analysis.
* Treat measure changes as API changes—version and communicate updates.
* Maintain a changelog for all semantic model modifications.

---

### Validation Workflow

Validation uses **Excel pivot reconciliation** against encounter-level exports:

1. Export the encounter-level dataset defined in each KPI folder (see `05_KPI_Dev`).
2. Build pivots to compute:
   * Totals (counts, sums)
   * Derived metrics (rates, averages)
3. Confirm exact match to KPI fact outputs.

<details>
<summary><strong>Troubleshooting reconciliation mismatches</strong></summary>

* Confirm you used the same time anchor (discharge year/month).
* Confirm NULL/Unknown categories are included.
* Confirm no filters were applied in Excel (especially outlier exclusions).
* Compare numerator/denominator totals separately before reviewing derived ratios.
* Cross-check measure definitions against the KPI README in `05_KPI_Dev`.

</details>

---

## Completion Criteria

This step is complete when:

* All KPI facts load into Power BI without relationship ambiguity or circular dependencies.
* All KPI measures reconcile exactly to SQL outputs (verified by Excel pivot validation).
* New dashboards can be built by reusing existing measures without writing new metric logic.
* A new KPI can be added by:
  * Creating one KPI fact table (SQL)
  * Reusing existing conformed dimensions
  * Adding measures (DAX) without restructuring the model

---

## Folder Structure

```text
06_PBI_Semantic_Model/
│
├── README.md
│
├── 01_Fact_KPI_SQL/
│   ├── README.md
│   ├── Fact_KPI_SeverityMix.sql
│   ├── Fact_KPI_PayerMix.sql
│   ├── Fact_KPI_Unplanned.sql
│   ├── Fact_KPI_Disposition.sql
│   ├── Fact_KPI_LOS_Summary.sql
│   ├── Fact_KPI_LOS_Distribution.sql
│   ├── Fact_KPI_Mortality.sql
│   └── Fact_KPI_FinancialPressure.sql
│
├── 02_Dimensions_Reference/
│   ├── README.md
│   ├── Dim_Date.md
│   ├── Dim_Facility.md
│   ├── Dim_Payer.md
│   ├── Dim_AdmissionType.md
│   ├── Dim_Disposition.md
│   └── Dim_ClinicalClass.md
│
├── 03_PowerBI_Model/
│   ├── README.md
│   ├── Relationships.md
│   ├── Measures_DAX.md
│   ├── RLS_Design.md
│   └── PowerBI_Model_Checklist.md
│
├── 04_KPI_Data_Dictionary/
│   ├── README.md
│   ├── KPI_Data_Dictionary.md
│   ├── KPI_Definitions.md
│   └── KPI_Ownership_and_Governance.md
│
└── 05_Validation/
    ├── README.md
    ├── Reconciliation_Checklist.md
    ├── Excel_Pivot_Validation_Guide.md
    └── Known_Issues_and_Resolutions.md
```
