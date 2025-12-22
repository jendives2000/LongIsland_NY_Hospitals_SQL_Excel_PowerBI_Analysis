# 06 — PowerBI Semantic Model

This step formalizes a **Power BI–ready semantic model** on top of the validated KPI layer from `05_KPI_Dev_PowerBI_Modeling`.

The key idea is to introduce a **KPI Integration Layer**: a stable, documented set of **KPI fact tables + shared dimensions** that makes dashboards fast to build, easy to validate, and hard to break.

---

## Why this step exists

KPI SQL scripts prove metrics are correct, but BI tools need more than correctness:

* consistent **grain** (what a row means)
* predictable **relationships**
* reusable **dimensions**
* measures that behave correctly under slicing and filtering

Without a semantic model, BI becomes:

* duplicated metric logic
* inconsistent totals
* fragile visuals
* slow performance

The semantic model is the “contract” that guarantees:

* **one definition per metric**
* **one relationship path per slice**
* **reproducible results** across Power BI, Excel validation, and SQL outputs

---

<details>
<summary><strong>Table of Contents</strong></summary>

- [06 — PowerBI Semantic Model](#06--powerbi-semantic-model)
  - [Why this step exists](#why-this-step-exists)
  - [KPI Integration Layer](#kpi-integration-layer)
  - [1. KPI Facts](#1-kpi-facts)
    - [Guidelines](#guidelines)
    - [How Facts Connect to Dimensions](#how-facts-connect-to-dimensions)
  - [2. Dimensions](#2-dimensions)
    - [Guidelines](#guidelines-1)
    - [Role-Playing Dates](#role-playing-dates)
  - [3. Star Schema for BI Tool](#3-star-schema-for-bi-tool)
    - [Guidelines](#guidelines-2)
    - [Recommended Relationship Rules](#recommended-relationship-rules)
  - [4. Mapping KPIs](#4-mapping-kpis)
  - [Best-Practice Additions](#best-practice-additions)
    - [Grain \& Additivity Rules](#grain--additivity-rules)
    - [Measures vs Columns](#measures-vs-columns)
    - [Naming Conventions](#naming-conventions)
    - [Performance \& Refresh](#performance--refresh)
    - [Security \& Governance](#security--governance)
    - [Validation Workflow](#validation-workflow)
  - [Completion Criteria](#completion-criteria)

</details>

---

## KPI Integration Layer

The KPI Integration Layer sits between:

* **SQL KPI scripts** (metric truth)
* **Power BI dashboards** (metric consumption)

It contains:

* a small number of **KPI fact tables** (each at a clear grain)
* a shared set of **conformed dimensions** (Facility, Date, etc.)
* a consistent set of **measures** (Avg LOS, Mortality Rate, Margin Pressure, …)

<details>
<summary>Technical definition</summary>

A KPI Integration Layer is a curated semantic representation that:

* enforces dimensional consistency (conformed dimensions)
* prevents metric drift (single source of measure logic)
* optimizes BI query patterns (star schema, low-cardinality columns)
* enables deterministic reconciliation (Excel/SQL matching)

</details>

---

## 1. KPI Facts

KPI facts are **analysis-ready tables** designed for BI. They should be small enough to refresh quickly but rich enough to support slicing and drill-down.

### Guidelines

* **Define the grain explicitly** in the table header.

  * Example: “One row per Facility–Year–LOS_Bucket”.
* Prefer **aggregated KPI fact tables** for dashboards.

  * Encounter-level extracts exist for validation, not for default BI consumption.
* Include **reconciliation totals**.

  * Example: when computing ratios, store numerator and denominator totals as columns.
* Keep fact tables **narrow**.

  * Use integer keys + a small set of numeric columns.
* Avoid storing “rates” only.

  * Store counts/totals so measures can recompute rates correctly under filtering.

### How Facts Connect to Dimensions

Facts connect to dimensions through **surrogate keys**:

* `Facility_Key` → `Dim_Facility`
* `Discharge_Date_Key` or derived `Year`/`Month_Number` → `Dim_Date`
* `ClinicalClass_Key` or derived severity group → `Dim_ClinicalClass` (if used as a slicer)
* Category attributes used in pivots (e.g., `LOS_Bucket`, `Disposition_Grouped`) can be:

  * kept as low-cardinality columns in the fact, or
  * modeled as small dimensions if they are reused broadly.

---

## 2. Dimensions

Dimensions provide the **slicing vocabulary** for the entire KPI suite. The goal is to reuse the same dimensions across facts to guarantee consistent filters.

### Guidelines

* Dimensions should be **conformed** (shared, consistent definitions across all KPI facts).
* Use a single `Dim_Date` with standard fields:

  * Year, Quarter, Month_Number, Month_Name
* Keep dimension keys stable:

  * avoid regenerating keys during refresh
* Add only attributes that are useful for slicing.

  * Avoid “junk dimensions” with many sparse columns.

### Role-Playing Dates

Some models need multiple dates (admit vs discharge). This project primarily anchors KPIs on **discharge**.

If multiple date roles are required:

* create role-playing views (e.g., `Dim_Date_Discharge`, `Dim_Date_Admission`) **without duplicating the table physically**, or
* use one `Dim_Date` and separate foreign keys (only when those keys exist).

---

## 3. Star Schema for BI Tool

A star schema is the most reliable structure for BI:

* **Facts in the center** (KPI outputs)
* **Dimensions around the edges** (Facility, Date, Payer, Severity, …)

This minimizes ambiguity, prevents filter path conflicts, and improves performance.

### Guidelines

* Use **one-to-many** relationships from dimensions to facts.
* Prefer **single-direction** filtering (Dimensions → Facts).
* Avoid many-to-many unless strictly necessary.
* Keep a clean separation between:

  * **semantic measures** (DAX)
  * **physical columns** (SQL outputs)

### Recommended Relationship Rules

* Dimensions filter facts (single direction).
* No relationships between facts.
* If you need cross-fact visuals:

  * use conformed dimensions + measures
  * avoid bridging fact-to-fact tables unless unavoidable.

---

## 4. Mapping KPIs

The table below proposes a practical mapping from the 7 KPIs to BI-ready fact tables and their primary dimensions.

> Note: Naming is intentionally explicit (Fact_KPI_*). This prevents confusion between encounter-level sources and KPI-level outputs.

| KPI                                  | Proposed Fact Table                                  | Grain (What 1 Row Means)                                       | Core Measures (examples)                               | Dimensions (slicers)                                 |
| ------------------------------------ | ---------------------------------------------------- | -------------------------------------------------------------- | ------------------------------------------------------ | ---------------------------------------------------- |
| 05.01 Severity Mix Index             | `Fact_KPI_SeverityMix`                               | Facility–Year (optionally Month)                               | Severity Mix Index, Encounter Count                    | Date, Facility, ClinicalClass (optional)             |
| 05.02 Payer Mix & Reimbursement Risk | `Fact_KPI_PayerMix`                                  | Facility–Year–PayerGroup                                       | Payer Encounters, Payer Share                          | Date, Facility, Payer                                |
| 05.03 Unplanned Admission Rate       | `Fact_KPI_Unplanned`                                 | Facility–Year (optionally Month)                               | Unplanned Count, Total Encounters, Unplanned Rate      | Date, Facility                                       |
| 05.04 Disposition Outcomes           | `Fact_KPI_Disposition`                               | Facility–Year–DispositionCategory                              | Disposition Count, Disposition Share                   | Date, Facility, Disposition                          |
| 05.05 Length of Stay (LOS)           | `Fact_KPI_LOS_Summary` + `Fact_KPI_LOS_Distribution` | Summary: Facility–Year; Distribution: Facility–Year–LOS_Bucket | Avg/Min/Max LOS; Bucket Counts/Shares                  | Date, Facility, LOS Bucket, ClinicalClass (Severity) |
| 05.06 Mortality Rate                 | `Fact_KPI_Mortality`                                 | Facility–Year (optionally Month)                               | Death Count, Total Encounters, Mortality Rate          | Date, Facility                                       |
| 05.07 MCost & Margin Pressure        | `Fact_KPI_FinancialPressure`                         | Facility–Year (optionally Month)                               | Avg MCost, Total Costs, Total Charges, Margin Pressure | Date, Facility                                       |

<details>
<summary>Technical note — why some KPIs have multiple fact tables</summary>

Some KPIs naturally produce multiple BI-friendly views:

* LOS has a *summary view* (avg/min/max) and a *distribution view* (buckets).

Splitting them improves:

* model clarity (each fact has one grain)
* performance (smaller tables)
* visual design (summary cards vs distribution charts)

</details>

---

## Best-Practice Additions

### Grain & Additivity Rules

Before building any measures, verify:

* **Grain is explicit** in every fact table.
* Measures are classified as:

  * **Additive** (counts, sums)
  * **Semi-additive** (snapshots)
  * **Non-additive** (rates, averages)

For rates and averages in Power BI:

* compute from stored numerators/denominators rather than summing precomputed rates.

---

### Measures vs Columns

* Use SQL to materialize:

  * keys
  * descriptive low-cardinality categories
  * reconciliation totals
* Use Power BI measures (DAX) for:

  * ratios (rates)
  * weighted averages
  * dynamic time selections

This reduces drift and keeps the model extensible.

---

### Naming Conventions

Recommended conventions:

* Facts: `Fact_KPI_*`
* Dimensions: `Dim_*`
* Measures: `m_*` (e.g., `m_MortalityRate`, `m_AvgLOS`)
* Columns:

  * keys end with `_Key`
  * rates end with `_Rate` (prefer measures)

---

### Performance & Refresh

* Prefer aggregated KPI facts for visuals.
* Keep encounter-level exports out of the default model.
* Use incremental refresh where possible (date-partitioned facts).
* Reduce cardinality:

  * store `Month_Number` rather than full dates when month slicing is enough

---

### Security & Governance

If distributing beyond local analysis:

* implement Row-Level Security (RLS) by Facility where appropriate
* document metric definitions and ownership
* version KPI changes (measure changes should be treated like API changes)

---

### Validation Workflow

Validation is performed using **Excel Pivot reconciliation** against encounter-level exports:

1. Export the encounter-level dataset defined in each KPI README.
2. Build pivots to compute:

   * totals (counts, sums)
   * derived metrics (rates, averages)
3. Confirm exact match to KPI fact outputs.

<details>
<summary>What to do when reconciliation fails</summary>

* Confirm you used the same time anchor (discharge year/month).
* Confirm NULL / Unknown categories are included.
* Confirm no filters were applied in Excel (especially outliers).
* Compare numerator/denominator totals first, then the derived ratio.

</details>

---

## Completion Criteria

This step is complete when:

* All KPI facts load into Power BI without relationship ambiguity.
* All KPI measures reconcile to SQL outputs.
* Dashboards can be built without writing new metric logic.
* A new KPI can be added by:

  * creating one KPI fact table
  * reusing existing dimensions
  * adding measures, not reworking the model
