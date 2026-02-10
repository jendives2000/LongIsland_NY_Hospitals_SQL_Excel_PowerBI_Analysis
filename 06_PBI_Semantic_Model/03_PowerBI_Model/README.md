# KPI Data Dictionary & Semantic Model Documentation

## Healthcare Performance Analytics — Long Island & New York Hospitals

---

## Overview

This semantic model delivers hospital performance analytics across seven clinical and financial domains, built for healthcare executives, senior analysts, and system-level decision-makers. It supports peer group benchmarking and statistical guardrails against small-sample distortion — all within a single, governed Power BI dataset.

The model contains **227 measures** organized across **10 domain-specific measure tables**, connected to **7 fact tables** and **8 dimensions** through **21 relationships**. Every measure carries a production-grade description, making the model fully self-documenting and auditable.

A live data dictionary — generated directly from the semantic model using DAX metadata functions — ensures documentation never drifts from the model itself.

---

<details>
<summary><b>Table of Contents</b></summary>

- [KPI Data Dictionary \& Semantic Model Documentation](#kpi-data-dictionary--semantic-model-documentation)
  - [Healthcare Performance Analytics — Long Island \& New York Hospitals](#healthcare-performance-analytics--long-island--new-york-hospitals)
  - [Overview](#overview)
  - [Design Principles](#design-principles)
  - [Fact Tables](#fact-tables)
  - [Dimensions](#dimensions)
    - [Peer Group Infrastructure](#peer-group-infrastructure)
  - [Relationship Wiring](#relationship-wiring)
  - [Measure Architecture](#measure-architecture)
    - [Domain Tables](#domain-tables)
    - [Display Folder Convention](#display-folder-convention)
    - [Measure Patterns](#measure-patterns)
    - [Conditional Formatting Threshold](#conditional-formatting-threshold)
  - [Statistical Guardrails](#statistical-guardrails)
  - [Severity as Context, Not Performance](#severity-as-context-not-performance)
  - [Live Data Dictionary](#live-data-dictionary)
    - [Architecture](#architecture)
    - [How to Use](#how-to-use)
  - [Certified KPI Measures](#certified-kpi-measures)
    - [Core KPIs (in `_KPI_Measures`)](#core-kpis-in-_kpi_measures)
    - [Domain KPIs](#domain-kpis)
  - [Visual Encoding Standards](#visual-encoding-standards)
    - [Pressure × Volume Scatter Pattern](#pressure--volume-scatter-pattern)
    - [Conditional Formatting](#conditional-formatting)
  - [Governance \& Change Control](#governance--change-control)
  - [Project Structure](#project-structure)
  - [Technical Notes](#technical-notes)

</details>

---

## Design Principles

| Principle | Implementation |
|-----------|----------------|
| **Star schema** | Conformed dimensions shared across all fact tables; no snowflaking |
| **One-to-many, single-direction** | All relationships filter from dimension to fact (one sanctioned exception documented below) |
| **Statistical reliability** | 30-encounter minimum guardrails suppress unreliable rates from small samples |
| **Excel compatibility** | All measures evaluate correctly in Excel-connected PivotTables |
| **No visual-level calculations** | All business logic lives in certified DAX measures, not in report visuals |
| **Self-documenting** | Every visible measure, table, and column carries a business-language description |

---

## Fact Tables

Seven KPI fact tables, each at facility × year grain (unless noted), sourced from SQL views over hospital discharge data.

| Fact Table | Grain | Core Metrics |
|------------|-------|--------------|
| `Fact_KPI_SeverityMix` | Facility × Year | Weighted severity sums, encounter counts |
| `Fact_KPI_Mortality` | Facility × Year | Death counts, total encounters |
| `Fact_KPI_Unplanned` | Facility × Year | Unplanned admission counts, total encounters |
| `Fact_KPI_LOS_Summary` | Facility × Year | Total LOS days, encounter counts |
| `Fact_KPI_FinancialPressure` | Facility × Year | Charges, costs, margins, negative margin encounters |
| `Fact_KPI_PayerMix` | Facility × Year × Payer | Encounter counts, charges, costs by payer category |
| `Fact_KPI_Disposition` | Facility × Year × Disposition | Encounter counts by discharge destination |

A supplemental detail view, `vw_Fact_KPI_SeverityMix_BySeverity`, breaks severity data to Facility × Year × APR Severity Level for distribution analysis.

---

## Dimensions

| Dimension | Grain | Role |
|-----------|-------|------|
| `Dim_Facility` | One row per hospital | Primary organizational hierarchy — name, county, health service area, peer group assignment |
| `Dim_Year` | One row per discharge year | **Primary time dimension** for all fact tables |
| `Dim_Payer` | One row per payer category | Payment typology groups (Medicare, Medicaid, Commercial, Self-Pay, Other) |
| `Dim_Disposition` | One row per disposition category | Discharge destinations (Home, SNF/Rehab, Death, Other) |
| `Dim_ClinicalClass` | One row per APR-DRG severity × ROM | APR severity levels and risk of mortality classifications |
| `Dim_PeerGroup` | One row per peer group | Hospital comparison cohorts (Academic/Tertiary, Large Community, Mid-Size Community, Rural/East-End, Specialty-Dominant) |
| `Dim_Date` | One row per calendar date | Connected only to `vw_Fact_KPI_SeverityMix_BySeverity` for date-level severity analysis |
| `Dim_AdmissionType` | One row per admission type | Hidden; available for future use |

### Peer Group Infrastructure

Peer group benchmarking uses a **bridge table pattern** to enable many-to-many facility-to-peer-group comparisons:

```
Dim_PeerGroup ←(1:*) Bridge_Facility_PeerGroup (*:1)→ Dim_Facility
```

**Note on bi-directional relationship**: The `Bridge_Facility_PeerGroup → Dim_Facility` relationship uses bi-directional cross-filtering. This is the only bi-directional relationship in the model. Peer group assignment is also denormalized into `Dim_Facility (PeerGroup_Key, PeerGroup_Name, PeerGroup_Sort)`, which most peer group median measures use directly. The bridge table and bi-directional filter exist as an alternative path for calculations that need to iterate across peer group membership independently of the facility filter context.

---

## Relationship Wiring

All seven core fact tables connect to `Dim_Facility` via `Facility_Key` (many-to-one, single-direction).

Time filtering uses `Discharge_Year → Dim_Year.Discharge_Year`. Active year relationships exist for `Disposition` and `PayerMix`; remaining facts have inactive year relationships available for explicit USERELATIONSHIP calls.

Additional dimension relationships:

| Fact Table | Dimension | Key |
|------------|-----------|-----|
| `Fact_KPI_PayerMix` | `Dim_Payer` | `Payer_Key` |
| `Fact_KPI_Disposition` | `Dim_Disposition` | `Disposition_Key` |
| `vw_Fact_KPI_SeverityMix_BySeverity` | `Dim_ClinicalClass` | `ClinicalClass_Key` |
| `vw_Fact_KPI_SeverityMix_BySeverity` | `Dim_Date` | `Discharge_Date_Key` |

---

## Measure Architecture

### Domain Tables

All business logic lives in **10 domain-specific measure tables** (prefixed with `_`), not in fact or dimension tables. Each table owns the measures for its analytical domain.

| Measure Table | Measures | Domain |
|---------------|----------|--------|
| `_KPI_Measures` | 7 | Core KPIs — Severity Mix Index, Mortality Rate, Unplanned Admission Rate, Average LOS, Margin Pressure, Margins |
| `_Severity` | 30 | Severity mix analysis, extreme severity %, peer group severity benchmarking |
| `_LOS` | 35 | Average LOS, excess LOS, bed-day utilization, Pareto analysis, what-if sensitivity |
| `_Unplanned` | 24 | Unplanned admission rates, pressure zone segmentation, peer group UA benchmarking |
| `_Mortality` | 18 | Mortality rates, risk of mortality, peer group mortality benchmarking |
| `_Financial_Basic` | 23 | Margin pressure, cost-per-encounter, negative margin analysis, peer group financial benchmarking |
| `_PayerMix` | 40 | Payer concentration (HHI), risk payer exposure, payer-specific margins, reimbursement risk |
| `_Disposition` | 20 | Discharge patterns, post-acute rates, transfer rates, peer group disposition benchmarking |
| `_Guardrails` | 19 | Volume-guarded KPI variants and Has Volume flags |
| `_Volume_&_Denominators` | 10 | Base encounter counts from each fact table |

### Display Folder Convention

Within each measure table, measures are organized into display folders:

| Folder | Contents |
|--------|----------|
| **Base** | Primary business-facing measures (rates, shares, totals) |
| **PeerGroup Benchmarks** | Peer group medians — the "how do we compare" measures |
| **Helper** | Flags, conditional formatting, intermediate calculations for visuals |
| **Has Volume** | Guardrail flags (in `_Guardrails`) |
| **Extreme Level** | Extreme severity analysis (in `_Severity`) |
| **Risk Payer** | Medicaid + Self-Pay exposure measures (in `_PayerMix`) |
| **Concentration** | HHI and payer concentration measures (in `_PayerMix`) |
| **Financial Risk** | Payer-specific cost/margin analysis (in `_PayerMix`) |
| **System Metrics** | System-wide aggregate benchmarks (in `_PayerMix`) |
| **Share Metrics** | Disposition share percentages (in `_Disposition`) |
| **Variance** | Delta vs. peer median measures (in `_Disposition`) |
| **Cross-PG Benchmarks** | System-wide medians ignoring peer groups (in `_Disposition`) |

### Measure Patterns

**Guarded measures** return BLANK when encounter volume falls below 30, preventing misleading rates from small samples. Named with `(Guarded)` suffix. Example: `Mortality Rate (Guarded)` returns BLANK if facility has fewer than 30 encounters.

**Peer group medians** come in two variants:

| Variant | Naming | Behavior |
|---------|--------|----------|
| **Base** | `PeerGroup [KPI] Median` | Requires a single peer group in filter context. Returns blank if multiple or no peer groups selected. Use in visuals where peer group is on the axis or in a slicer. |
| **FacilitySafe** | `PeerGroup [KPI] Median (FacilitySafe)` | Removes facility filter to calculate median across the peer group. Works per facility row without requiring peer group in the filter context. Use in facility-level tables and conditional formatting. |

**Flag measures** (1/0 integers) power conditional formatting and counting logic. Named `Is Above…`, `Is Below…`, `Has Volume`, etc.

**Display measures** replace BLANK with 0 for card visuals that cannot render blanks. Named with `(Display)` or `(0 safe)` suffix.

### Conditional Formatting Threshold

The `Excess LOS Materiality Threshold (Days)` table is a Power BI what-if parameter that lets report users adjust the threshold for LOS excess conditional formatting. The `Materiality Threshold Value` measure reads the selected value (default: 0.25 days) and feeds `Excess LOS Color (WhatIf)`, which assigns red shades to facilities exceeding the threshold and blue shades to those below.

---

## Statistical Guardrails

The `_Guardrails` table enforces a **30-encounter minimum** across all rate-based KPIs. This is a standard practice in healthcare analytics to prevent small-sample distortion.

**How it works:**
- Each KPI domain has a `[Domain] Has Volume` flag that returns 1 if encounters ≥ 30, else 0
- Guarded measure variants check the flag and return BLANK when volume is insufficient
- Visuals bound to guarded measures automatically suppress unreliable data points

**Domains covered:** Severity Mix, Mortality, LOS, Unplanned Admissions, Financial Pressure, Payer Mix (both payer-level and facility-year-level), Disposition (both category-level and facility-year-level).

---

## Severity as Context, Not Performance

Severity Mix Index is a **descriptive contextual signal**, not a performance indicator. It reflects the acuity of patients a hospital treats, not the quality of care delivered.

**Interpretation guidance for executives:**
- Higher SMI indicates sicker, more complex patient populations
- SMI should be read alongside — not compared against — outcome metrics (mortality, LOS, cost)
- A hospital with high SMI and high mortality is a different story than one with low SMI and high mortality
- Peer group benchmarking controls for this by comparing facilities against cohorts with similar case-mix profiles

This principle extends to all contextual measures in the model. Measures that describe patient population characteristics are separated from those that assess operational or clinical outcomes.

---

## Live Data Dictionary

### Architecture

The data dictionary is generated from the semantic model itself using DAX `INFO.VIEW()` metadata functions, ensuring zero documentation drift.

**Layer 1 — Metadata Extraction (hidden calculated tables):**

| Table | Source | Purpose |
|-------|--------|---------|
| `_Meta_Measures` | `INFO.VIEW.MEASURES()` | All measures with expressions, descriptions, data types |
| `_Meta_Tables` | `INFO.VIEW.TABLES()` | Table names, row counts, properties |
| `_Meta_Columns` | `INFO.VIEW.COLUMNS()` | Column definitions, data types, relationships |
| `_Meta_Relationships` | `INFO.VIEW.RELATIONSHIPS()` | Relationship cardinalities and filter directions |

**Layer 2 — Unified Dictionary:**

The `_DataDictionary` calculated table unions all four metadata sources into a single searchable structure with standardized fields: Type, Name, Description, Location, Expression, DataType, and DisplayFolder. Hidden objects and `_Meta_*` tables are filtered out automatically.

**Layer 3 — Report Interface:**

A dedicated report page surfaces the dictionary with slicers by object type, a search box for measure lookup, and a detail view showing full DAX expressions and business definitions.

### How to Use

**Finding a KPI:** Open the Data Dictionary page → filter by Type = Measure → search by name → review Description for business definition and Expression for calculation logic.

**Understanding relationships:** Filter by Type = Relationship → identify source/target tables, cardinality, and filter direction.

**Exploring columns:** Filter by Type = Column → use Location field to browse by parent table → check DataType and Description.

---

## Certified KPI Measures

The following measures are the primary business-facing indicators exposed to report consumers. All live in `_KPI_Measures` or their respective domain tables.

### Core KPIs (in `_KPI_Measures`)

| Measure | Description |
|---------|-------------|
| Severity Mix Index | Weighted average APR severity (1–4). Context signal, not performance. |
| Mortality Rate | In-hospital deaths / encounters. Not risk-adjusted. |
| Unplanned Admission Rate | Share of emergency/unplanned admissions. |
| AVG LOS | Average length of stay in days. |
| Margin Pressure | Cost-to-charge ratio. Above 1.0 = operating at a loss. |
| FP Margin | Total margin (charges − costs) from financial fact. |
| PM Margin | Total margin from payer mix fact. |

### Domain KPIs

| Domain | Key Business Measures |
|--------|----------------------|
| **Severity** | Extreme Severity %, Peer Group Median Extreme %, SMI Range |
| **Mortality** | PeerGroup Mortality Rate Median, Cross-PG Mortality Rate Median, Major-Extreme ROM Share |
| **Unplanned** | PeerGroup UA Rate Median, Median Unplanned % (Selected) |
| **LOS** | Total Bed-Days, Share of Bed-Days, Excess LOS Days, Median Excess LOS (Days) |
| **Financial** | Neg Margin Rate, AVG Cost / Encounter, Margin Pressure Burden, PeerGroup Margin Pressure Median |
| **Payer Mix** | Risk Payer Share %, Payer HHI (Facility), Top Payer Share %, PeerGroup Risk Payer Share Median |
| **Disposition** | Home Discharge Share %, Post-Acute Discharge Share %, Acute Transfer Share %, PeerGroup Post-Acute Share Median |

---

## Visual Encoding Standards

### Pressure × Volume Scatter Pattern

Several report pages use a consistent bubble chart pattern for identifying high-priority facilities:

| Channel | Encoding | Example |
|---------|----------|---------|
| **X-axis** | Rate or ratio metric | Unplanned Admission Rate, Margin Pressure |
| **Y-axis** | Volume (encounter count) | Total Encounters, Payer Encounters |
| **Bubble size** | Burden or absolute impact | Unplanned Encounter Count, Margin Pressure Burden |
| **Color** | Peer group assignment | Dim_Facility[PeerGroup_Name] |

Threshold reference lines (dashed) mark analytical boundaries — for example, 40% UA rate and 3,000 encounters define a "low-pressure zone" where intervention is less urgent.

### Conditional Formatting

Color-coding measures (e.g., `Excess LOS Color (WhatIf)`, `HHI Color`, `Post-Acute Share Label Color`) use hex color strings evaluated via SWITCH logic. These drive conditional formatting rules in report visuals without requiring visual-level calculated fields.

---

## Governance & Change Control

**Measure ownership:** All business logic is centralized in DAX measures. No calculated columns, no visual-level measures, no report-level calculations.

**Version control:** The model is saved as a `.pbip` (Power BI Project) file, enabling Git-based version control of TMDL definition files.

**Description standard:** Every visible measure carries a description that states what is calculated, at what grain, and any suppression or guardrail logic. Complex measures include interpretation cues where misuse risk is high.

**Naming conventions:**
- Measure tables prefixed with `_` (underscore)
- Guarded variants suffixed with `(Guarded)`
- FacilitySafe variants suffixed with `(FacilitySafe)`
- Display/card-safe variants suffixed with `(Display)` or `(0 safe)`
- Hidden technical tables prefixed with `_Meta_`

---

## Project Structure

```
06_PBI_Semantic_Model/
├── 01_Fact_KPI_SQL/
├── 02_Dimensions_Reference/
├── 03_PowerBI_Model/
│   └── PBI_Project/
│       ├── PowerBI_project.Report/
│       │   ├── .pbi
│       │   └── definition/
│       │       ├── bookmarks/
│       │       └── pages/
│       │           └── <page_id>/
│       │               └── visuals/
│       ├── StaticResources/
│       │   ├── RegisteredResources/
│       │   ├── SharedResources/
│       │   └── BaseThemes/
│       └── PowerBI_project.SemanticModel/
│           ├── .pbi
│           └── definition/
│               ├── cultures/
│               └── tables/
├── 04_KPI_Data_Dictionary/
└── 05_Validation/
```

---

## Technical Notes

**DAX version:** `INFO.VIEW()` functions require Power BI Desktop or Premium capacity with dynamic metadata support.

**Refresh behavior:** `_DataDictionary` and `_Meta_*` tables refresh automatically on model deployment. No independent schedule required.

**Excel connectivity:** All measures evaluate correctly when connected via Analyze in Excel. Guarded measures return BLANK (displayed as empty cells) when volume thresholds are not met.

**Compatibility level:** Model uses current Power BI Desktop compatibility level. Peer group bridge pattern and INFO.VIEW functions are supported in all recent versions.