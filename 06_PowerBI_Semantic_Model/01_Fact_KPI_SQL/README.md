# 06.01 — Fact KPI SQL (Semantic Model Layer)

This folder defines the **KPI fact tables** that form the core of the **Power BI semantic model**.

It represents the transition from:
- KPI *logic & validation* (Step 05)
to
- KPI *governance-ready facts* consumed by Power BI, Excel, and downstream analytics.

---

<details>
<summary><strong>📑 Table of Contents</strong></summary>

- [06.01 — Fact KPI SQL (Semantic Model Layer)](#0601--fact-kpi-sql-semantic-model-layer)
  - [What This Folder Contains](#what-this-folder-contains)
  - [Design Principles (Healthcare Analytics Standards)](#design-principles-healthcare-analytics-standards)
  - [Time Dimension Rule (Dim\_Year vs Dim\_Date)](#time-dimension-rule-dim_year-vs-dim_date)
    - [Dim\_Year (Tiny Conformed Dimension)](#dim_year-tiny-conformed-dimension)
  - [Fact KPI Inventory](#fact-kpi-inventory)
    - [FACT 05.01 — `Fact_KPI_SeverityMix`](#fact-0501--fact_kpi_severitymix)
    - [FACT 05.02 — `Fact_KPI_PayerMix`](#fact-0502--fact_kpi_payermix)
    - [FACT 05.03 — `Fact_KPI_Unplanned`](#fact-0503--fact_kpi_unplanned)
    - [FACT 05.04 — `Fact_KPI_Disposition`](#fact-0504--fact_kpi_disposition)
    - [FACT 05.05 — `Fact_KPI_LOS_Summary`](#fact-0505--fact_kpi_los_summary)
    - [FACT 05.06 — `Fact_KPI_Mortality`](#fact-0506--fact_kpi_mortality)
    - [FACT 05.07 — `Fact_KPI_FinancialPressure`](#fact-0507--fact_kpi_financialpressure)
  - [KPI Data Dictionary (Governance Contract)](#kpi-data-dictionary-governance-contract)
    - [Additivity Notes](#additivity-notes)
  - [Relationship to Power BI Semantic Model](#relationship-to-power-bi-semantic-model)
  - [Change Management Rule](#change-management-rule)

</details>


---

## What This Folder Contains

This folder contains **one production fact table per KPI**, each implemented as:

- A **dedicated T-SQL file** (`Fact_KPI_*.sql`)
- A **clearly defined analytical contract**:
  - explicit grain
  - stable numerators and denominators
  - conformed dimensions
- A structure optimized for:
  - Power BI star schema modeling
  - Excel pivot reconciliation
  - auditability and governance

**Important:**  
This README documents *what each fact represents*.  
All SQL implementation details live in their own `.sql` files.

---

## Design Principles (Healthcare Analytics Standards)

All Fact_KPI tables follow these rules:

- **Explicit grain** (no ambiguity)
- **One KPI per fact table**
- **Facility-anchored aggregation**
- **Discharge-year alignment** across KPIs
- **No embedded business logic in Power BI**
- **Reconciliation-safe metrics**
- **Conformed dimensions reused across facts**

This ensures:
- consistent interpretation across dashboards
- safe Excel validation
- future extensibility (new years, new facilities)

---

## Time Dimension Rule (Dim_Year vs Dim_Date)

All KPI facts in this folder are modeled at **Facility × Discharge Year** grain (2015 scope).

Therefore, time is modeled using a **tiny conformed dimension**:

- `dbo.Dim_Year` (PK: `Discharge_Year`)

This avoids forcing a `Date_Key` into facts that are not at daily grain.

`Dim_Date` is used only when a fact table is built at **month/day grain** and contains a true `Date_Key`.

### Dim_Year (Tiny Conformed Dimension)

**Purpose**  
Provides governed time slicing for **year-grain KPI facts**.

**Primary Key**
- `Discharge_Year` (INT)

**Suggested Attributes**
- `Discharge_Year` (PK)
- `Year_Label` (optional)


---

## Fact KPI Inventory

### FACT 05.01 — `Fact_KPI_SeverityMix`

**Purpose**  
Establishes the **clinical acuity baseline** required to interpret all downstream KPIs fairly.

**Grain**  
- One row per **Facility × Discharge Year** - 2015

**Primary Measures**
- Total encounters
- Weighted severity sum
- Severity Mix Index (stored for validation, recomputed in DAX)

**Key Dimensions**
- Facility
- Year (`Dim_Year`)

**Analytical Role**
- Context KPI (not performance)
- Used to explain LOS, mortality, and cost differences

---

### FACT 05.02 — `Fact_KPI_PayerMix`

**Purpose**  
Quantifies **payer distribution and reimbursement exposure** by facility.

**Grain**  
- One row per **Facility × Discharge Year × Payment Typology Group**

**Primary Measures**
- Encounter count per payer group
- Payer-group numerator and denominator (reconciliation-safe)

**Key Dimensions**
- Facility
- Year (`Dim_Year`)
- Payer

**Analytical Role**
- Financial exposure context
- Explains structural margin pressure

---

### FACT 05.03 — `Fact_KPI_Unplanned`

**Purpose**  
Measures **acute intake pressure** driven by unplanned admissions.

**Grain**  
- One row per **Facility × Discharge Year**

**Primary Measures**
- Total encounters
- Unplanned encounter count

**Key Dimensions**
- Facility
- Year (`Dim_Year`)

**Analytical Role**
- Intake pressure indicator
- Interpreted before LOS and cost KPIs

---

### FACT 05.04 — `Fact_KPI_Disposition`

**Purpose**  
Describes **how inpatient encounters conclude**, connecting care to downstream systems.

**Grain**  
- One row per **Facility × Discharge Year × Disposition Group**

**Primary Measures**
- Disposition encounter count

**Key Dimensions**
- Facility
- Year (`Dim_Year`)
- Disposition

**Analytical Role**
- Flow completion KPI
- Interpreted alongside LOS and mortality

---

### FACT 05.05 — `Fact_KPI_LOS_Summary`

**Purpose**  
Summarizes **inpatient length-of-stay behavior** at an executive level.

**Grain**  
- One row per **Facility × Discharge Year**

**Primary Measures**
- Encounter count
- Average LOS
- Minimum LOS
- Maximum LOS

**Key Dimensions**
- Facility
- Year (`Dim_Year`)

**Analytical Role**
- Throughput and capacity signal
- Requires severity and intake context

---

### FACT 05.06 — `Fact_KPI_Mortality`

**Purpose**  
Measures **in-hospital mortality exposure**.

**Grain**  
- One row per **Facility × Discharge Year**

**Primary Measures**
- Total encounters
- Death count

**Key Dimensions**
- Facility
- Year (`Dim_Year`)

**Analytical Role**
- Outcome risk KPI
- Always interpreted with Severity Mix

---

### FACT 05.07 — `Fact_KPI_FinancialPressure`

**Purpose**  
Surfaces **cost intensity and margin stress** at the system level.

**Grain**  
- One row per **Facility × Discharge Year**

**Primary Measures**
- Encounter count
- Total costs
- Total charges
- Average medical cost per encounter
- Negative-margin encounter count

**Key Dimensions**
- Facility
- Year (`Dim_Year`)

**Analytical Role**
- Financial sustainability indicator
- Contextualized by payer mix and severity

---

## KPI Data Dictionary (Governance Contract)

| KPI                           | Fact Table                 | Grain                     | Additive Numerator(s)       | Additive Denominator(s) | Primary Dimensions          | Owner              |
| ----------------------------- | -------------------------- | ------------------------- | --------------------------- | ----------------------- | --------------------------- | ------------------ |
| Severity Mix Index            | Fact_KPI_SeverityMix       | Facility–Year             | Weighted_Severity_Sum       | Total_Encounters        | Year, Facility              | Clinical Analytics |
| Payer Mix                     | Fact_KPI_PayerMix          | Facility–Year–Payer       | Encounter_Count             | Total_Encounters        | Year, Facility, Payer       | Finance            |
| Unplanned Admission Rate      | Fact_KPI_Unplanned         | Facility–Year             | Unplanned_Encounter_Count   | Total_Encounters        | Year, Facility              | Quality            |
| Disposition Outcomes          | Fact_KPI_Disposition       | Facility–Year–Disposition | Disposition_Count           | Total_Encounters        | Year, Facility, Disposition | Operations         |
| Length of Stay (Avg LOS)      | Fact_KPI_LOS_Summary       | Facility–Year             | **Total_LOS_Days**          | **Encounter_Count**     | Year, Facility              | Ops / Clinical     |
| LOS Distribution              | Fact_KPI_LOS_Distribution  | Facility–Year–LOS_Bucket  | Bucket_Count                | Encounter_Count         | Year, Facility              | Ops / Clinical     |
| Mortality Rate                | Fact_KPI_Mortality         | Facility–Year             | Death_Count                 | Total_Encounters        | Year, Facility              | Quality            |
| Financial Pressure (Avg Cost) | Fact_KPI_FinancialPressure | Facility–Year             | **Total_Costs**             | **Encounter_Count**     | Year, Facility              | Finance            |
| Financial Pressure (Margin)   | Fact_KPI_FinancialPressure | Facility–Year             | Total_Charges − Total_Costs | Total_Charges           | Year, Facility              | Finance            |

### Additivity Notes
- All authoritative KPIs are derived from additive components.
- Non-additive values (averages, rates, indexes) are computed in Power BI as measures.
- Columns suffixed with `_validation` exist only for SSMS and reconciliation and are hidden in Power BI.


---

## Relationship to Power BI Semantic Model

These fact tables are:
- **Imported as facts** in Power BI
- Related to **conformed dimensions**:
  - `Dim_Facility`
  - `Dim_Year` (year-grain KPI facts)
  - `Dim_Date` (only for date-grain facts, if introduced later)
  - `Dim_Payer`
  - `Dim_Disposition`
- Used to build:
  - certified measures
  - executive dashboards
  - Excel-connected pivot models

No business logic is duplicated in Power BI.

---

## Change Management Rule

This folder defines the **executive KPI contract**.

Any change requires:
1. SQL versioning
2. Excel reconciliation
3. Power BI model update
4. README update

Unversioned KPI changes are not permitted.

---

**This folder represents a production-grade healthcare KPI semantic layer.**
