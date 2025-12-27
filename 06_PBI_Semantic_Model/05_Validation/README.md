# 05 — Validation (KPI Certification & Semantic Readiness)

This step formalizes **validation as a first-class artifact** in the analytics lifecycle.
It bridges **KPI development (Step 05)** and **semantic modeling for Power BI (Step 06)**, and answers the question: 
> “Are the KPI numbers mathematically and logically correct?”

**Key principle**:    
> Step 05 validates *metric correctness*.  
> Step 06 validates *semantic and BI correctness*.  
> Both are required, and they validate different risks.  

---

## Purpose of Step 05 Validation

Step 05 validation exists to **certify KPI definitions before they are allowed into a BI semantic model**. The validation is based on **explicit checks** that are **reconciliation-focused**. 

It proves trustworthiness, not usability.


Once a KPI passes Step 05:

* The **business definition is frozen**
* The **SQL logic is authoritative**
* Any future changes require re-entering Step 05

Once validated, KPIs are consumed by Power BI and Excel-based executive analytics.

---

## How Step 05 Differs from Step 06 Validation

| Area           | Step 05 — KPI Validation    | Step 06 — Semantic Validation |
| -------------- | --------------------------- | ----------------------------- |
| Primary Risk   | Incorrect metric logic      | Broken BI behavior            |
| Grain          | Encounter-level or detailed | Aggregated KPI facts          |
| Tooling        | SQL + Excel                 | SQL + Power BI                |
| Business logic | **Validated & frozen**      | **Not redefined**             |
| Output         | KPI dev scripts             | BI-ready fact tables          |

**Important:** Step 06 never redefines a KPI. If logic changes are needed, the process must return to Step 05.

---

## Required Artifacts for Step 05 Validation

Each KPI must include the following before progressing to Step 06:

### 1. Encounter-Level Validation Dataset

* Derived directly from `dbo.Fact_Encounter`
* Uses the same time anchor (typically Discharge Date)
* Includes all inclusion/exclusion logic

Purpose: ensures no aggregation hides data issues.

---

### 2. Reconciliation Totals

Each KPI must clearly identify:

* **Numerator definition**
* **Denominator definition**
* Any conditional logic (e.g., exclusions, buckets, groupings)

These totals are the *contract* that Step 06 must preserve.

---

### 3. Excel Pivot Validation

Validation must be reproducible outside SQL.

Minimum required checks:

* Total encounter counts
* Numerator totals
* Denominator totals
* Derived rate / average

The Excel result must **exactly match** the SQL KPI output.

---

### 4. Edge-Case Review

Each KPI must explicitly confirm handling of:

* NULL or Unknown categories
* Zero denominators
* Facilities with small volumes
* Outlier values (e.g., LOS extremes)

---

## Step 06 Validation Requirements (What Must Be Revalidated)

Once KPIs move into **Fact_KPI_* tables**, Step 06 validation is mandatory.
This does **not** revalidate definitions — it validates **semantic integrity**.

### Step 06 answers the question:

> **“Does this KPI behave exactly the same after being reshaped for Power BI?”**

---

## Step 06 Reconciliation Checklist (Required)

For each `Fact_KPI_*` table:

### 1. Totals Reconciliation

* Sum of KPI fact numerators = Step 05 numerator
* Sum of KPI fact denominators = Step 05 denominator
* No row loss due to joins or grouping

---

### 2. Dimensional Slicing Validation

Confirm results remain correct when slicing by:

* Facility
* Year (and Month, if applicable)
* KPI-specific dimensions (Payer, Disposition, LOS Bucket, etc.)

---

### 3. Power BI Measure Validation

All rates and averages must be calculated as **DAX measures**, not stored values.

Examples:

* Mortality Rate
* Payer Share
* Unplanned Admission Rate

Each measure must reconcile back to Step 05 SQL results.

---

## What to Validate Per KPI Fact (Step 06)

### Fact_KPI_SeverityMix

* Total_Encounters matches Step 05
* Weighted_Severity_Sum preserved
* Severity Mix Index recomputed correctly in DAX

---

### Fact_KPI_PayerMix

* Encounter_Count sums to total encounters
* Payer shares recompute correctly under Facility filters
* No payer categories lost or duplicated

---

### Fact_KPI_Unplanned

* Total_Encounters preserved
* Unplanned_Encounter_Count matches Step 05
* Rate correct under time and facility slicing

---

### Fact_KPI_Disposition

* Disposition counts sum to total encounters
* All disposition groups represented

---

### Fact_KPI_LOS_Summary / Distribution

* Encounter counts match Step 05
* Average LOS recomputed from stored values
* Bucket totals sum to encounter count

---

### Fact_KPI_Mortality

* Death_Count preserved
* Mortality Rate recomputed correctly

---

### Fact_KPI_FinancialPressure

* Total_Costs and Total_Charges preserved
* Negative margin counts correct
* Margin measures recompute accurately

---

## Documentation & Governance Requirements

Step 05 validation is not complete unless:

* KPI definition is documented in the Data Dictionary
* Grain is explicitly stated
* Numerator / denominator ownership is assigned
* Validation evidence is retained

---

## Exit Criteria for Step 05 Validation

A KPI is allowed to enter Step 06 **only when**:

* ✅ SQL logic is validated
* ✅ Excel reconciliation matches exactly
* ✅ Edge cases are reviewed
* ✅ Definitions are frozen and documented

---

## Final Principle

> **Step 05 validates truth.**
> **Step 06 validates trust.**

Both are required for healthcare-grade analytics.
Skipping either introduces unacceptable risk.
