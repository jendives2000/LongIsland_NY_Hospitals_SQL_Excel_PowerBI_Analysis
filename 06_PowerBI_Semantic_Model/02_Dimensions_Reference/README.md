# 06.02 — Dimensions Reference

This folder documents the **conformed dimensions** used by the **Power BI Semantic Model (Step 06)**.

These dimensions provide the **shared slicing vocabulary** across all `Fact_KPI_*` tables and ensure:

* consistent filtering behavior
* reproducible KPI results
* clean star-schema relationships
* prevention of metric drift

> **Critical principle**
> Dimensions are *consumed* by the KPI Semantic Layer — they are **not redefined here**.

---
## Table of Contents

<details>
<summary>TOC</summary>

- [06.02 — Dimensions Reference](#0602--dimensions-reference)
  - [Table of Contents](#table-of-contents)
  - [Purpose of 06.02 — Dimensions Reference](#purpose-of-0602--dimensions-reference)
  - [What This Folder Contains](#what-this-folder-contains)
  - [Conformed Dimension Rules (Non-Negotiable)](#conformed-dimension-rules-non-negotiable)
  - [Dimensions Used by the KPI Semantic Model](#dimensions-used-by-the-kpi-semantic-model)
    - [Dimension Governance Notes](#dimension-governance-notes)
    - [Dim\_Year](#dim_year)
    - [Dim\_Date](#dim_date)
    - [Dim\_Facility](#dim_facility)
    - [Dim\_Payer](#dim_payer)
    - [Dim\_AdmissionType](#dim_admissiontype)
    - [Dim\_Disposition](#dim_disposition)
    - [Dim\_ClinicalClass](#dim_clinicalclass)
  - [Dimension Cardinality \& Usage Guidance](#dimension-cardinality--usage-guidance)
  - [Dimension × KPI Impact Matrix](#dimension--kpi-impact-matrix)
    - [Governance Rule](#governance-rule)
  - [Relationship Rules in Power BI](#relationship-rules-in-power-bi)
  - [Governance \& Change Control](#governance--change-control)
  - [Relationship to Other Steps](#relationship-to-other-steps)
  - [Final Principle](#final-principle)

</details>

---

## Purpose of 06.02 — Dimensions Reference

This step exists to make the dimensional layer:

* explicit
* documented
* governed

while avoiding one of the most common BI failures:

> *each KPI redefining its own version of Facility, Date, or Payer.*

The role of this folder is **documentation and governance**, not transformation.

---

## What This Folder Contains

Each dimension has a dedicated section describing:

* the business meaning of the dimension
* the surrogate key used in facts
* the attributes exposed to Power BI
* the KPIs that depend on it
* any special modeling notes

---

## Conformed Dimension Rules (Non-Negotiable)

All dimensions referenced here must satisfy the following:

1. **Single Definition**  
   One authoritative table per dimension (e.g., `Dim_Facility`).

2. **Stable Surrogate Keys**  
   Keys must not be regenerated or repurposed during refreshes.

3. **Shared Usage**  
   The same dimension must be reused across all KPI facts.

4. **Low Cardinality Attributes Only**  
   Only attributes useful for slicing should be exposed.

---

## Dimensions Used by the KPI Semantic Model


| Dimension | Primary Role | Surrogate Key | Anchor/Comments | Key Attributes| Used By |
|---------------|--------------|---------------|----------------|------------------------|-------------------|
| Dim_Year | Year-level time slicing | Discharge_Year | Used for all Facility × Year KPI facts | Year_Label | All Fact_KPI_* |
| Dim_Date | Date derivation & enrichment | Date_Key | Used only to derive Discharge_Year during fact construction | Year, Quarter, Month, Month_Number | Source-only (not directly related in PBI) |
| Dim_Facility | Organizational slicing & RLS | Facility_Key | Single authoritative facility definition | Facility_Name | All Fact_KPI_* |
| Dim_Payer | Financial & reimbursement analysis | Payer_Key | Grouped payer typology preferred | Payment_Typology_Group, Payment_Typology_1 | Fact_KPI_PayerMix |
| Dim_AdmissionType | Admission classification | AdmissionType_Key | Standardized admission type | AdmissionType_Std | Fact_KPI_Unplanned |
| Dim_Disposition | Outcome classification | Disposition_Key | Grouped for low cardinality | Disposition_Grouped | Fact_KPI_Disposition, Fact_KPI_Mortality |
| Dim_ClinicalClass | Clinical severity & risk stratification | ClinicalClass_Key | Used selectively to avoid over-slicing | APR_Severity_Code, APR_Severity_Description, APR_Risk_Of_Mortality_Desc | Severity Mix, LOS (optional), Mortality |

### Dimension Governance Notes

- All dimensions are **conformed and reused** across KPI facts.
- No KPI-specific logic is embedded in dimensions.
- Only **low-cardinality, analytically useful attributes** are exposed.
- Dimensions are **not rebuilt** as part of Step 06.
- Any change to a dimension requires impact analysis across all dependent KPIs.

### Dim_Year

| Dimension | Primary Role | Key | Time Anchor / Notes | Attributes for BI | Used By |
|----------|--------------|-----|---------------------|------------------|--------|
| `Dim_Year` | Year-level time slicing | `Discharge_Year` | Tiny conformed dimension for year-grain KPIs | `Year_Label` | All Fact_KPI_* |

**Notes**
- `Dim_Year` is the **authoritative time dimension** for all KPI facts modeled at **Facility × Year grain**.
- It intentionally replaces `Dim_Date` in the Power BI semantic model for these facts.
- This avoids forcing artificial `Date_Key` values into non-daily facts.


### Dim_Date

| Dimension | Primary Role | Key | Time Anchor / Notes | Attributes for BI | Used By |
|----------|--------------|-----|---------------------|------------------|--------|
| `Dim_Date` | Calendar reference & derivation | `Date_Key` | Used to derive Discharge_Year during fact construction | Year, Quarter, Month, Month_Number | Fact build (not semantic slicing) |

> `Dim_Date` is **not directly related** to year-grain KPI facts in Power BI.
> It is used upstream to derive `Discharge_Year` and remains available for future date-grain facts.

> Role-playing dates are avoided unless explicitly required.

---

### Dim_Facility

| Dimension| Primary Role | Key | Time Anchor / Notes | Attributes for BI | Used By|
|---------------|--------------|---------------|---------------------|--------------------------|-------------------|
| `Dim_Facility` | Organizational slicing & RLS | `Facility_Key` | Single authoritative facility definition | `Facility_Name` | All Fact_KPI_* |

This dimension is foundational and used by **all KPI facts**.

---

### Dim_Payer

| Dimension| Primary Role | Key | Time Anchor / Notes | Attributes for BI | Used By|
|---------------|--------------|---------------|---------------------|--------------------------|-------------------|
| `Dim_Payer` | Financial & reimbursement analysis | `Payer_Key` | Grouped payer typology preferred | `Payment_Typology_Group`, `Payment_Typology_1` | `Fact_KPI_PayerMix` |

Used primarily by:

* `Fact_KPI_PayerMix`

---

### Dim_AdmissionType

| Dimension| Primary Role | Key | Time Anchor / Notes | Attributes for BI | Used By|
|---------------|--------------|---------------|---------------------|--------------------------|-------------------|
| `Dim_AdmissionType` | Admission classification | `AdmissionType_Key` | Standardized admission categories | `AdmissionType_Std` | `Fact_KPI_Unplanned` |

---

### Dim_Disposition
| Dimension| Primary Role | Key | Time Anchor / Notes | Attributes for BI | Used By|
|---------------|--------------|---------------|---------------------|--------------------------|-------------------|
| `Dim_Disposition` | Outcome classification | `Disposition_Key` | Grouped for low cardinality | `Disposition_Grouped` | `Fact_KPI_Disposition`, `Fact_KPI_Mortality` |

---

### Dim_ClinicalClass

| Dimension| Primary Role | Key | Time Anchor / Notes | Attributes for BI | Used By|
|---------------|--------------|---------------|---------------------|--------------------------|-------------------|
| `Dim_ClinicalClass` | Clinical severity & risk stratification | `ClinicalClass_Key` | Used selectively to avoid over-slicing | `APR_Severity_Code`, `APR_Severity_Description`, `APR_Risk_Of_Mortality_Desc` | Severity Mix, LOS (optional), Mortality |

---

## Dimension Cardinality & Usage Guidance

| Dimension Name | Cardinality | Typical BI Usage | Recommended Exposure | Notes |
|---------------|------------|------------------|----------------------|-------|
| Dim_Year | Very Low | Primary time slicer | Always exposed | Canonical time dimension for KPI facts |
| Dim_Date | Low | Source derivation only | Hidden | Not used directly in year-grain KPI slicing |
| Dim_Facility | Low | Primary slicer, RLS | Always exposed | Central to governance and security |
| Dim_Payer | Medium | Distribution analysis | Expose grouped fields | Avoid raw payer IDs |
| Dim_AdmissionType | Low | Binary / categorical slice | Expose | Used only for Unplanned KPI |
| Dim_Disposition | Low | Outcome distribution | Expose grouped field | Do not expose raw disposition codes |
| Dim_ClinicalClass | Medium–High | Stratified clinical analysis | Conditional exposure | Avoid default use in financial KPIs |


---

## Dimension × KPI Impact Matrix

| Dimension | Severity Mix | Payer Mix | Unplanned | Disposition | LOS | Mortality | Financial Pressure |
|----------|-------------|-----------|-----------|-------------|-----|-----------|--------------------|
| Dim_Year | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| Dim_Date | — | — | — | — | — | — | — |
| Dim_Facility | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| Dim_Payer | — | ✔ | — | — | — | — | — |
| Dim_AdmissionType | — | — | ✔ | — | — | — | — |
| Dim_Disposition | — | — | — | ✔ | — | ✔ | — |
| Dim_ClinicalClass | ✔ | — | — | — | (Optional) | ✔ | — |

### Governance Rule

Any change to a dimension marked ✔ requires:
1. Impact analysis across affected KPIs
2. Step 06 semantic revalidation
3. Documentation update in this folder


---

## Relationship Rules in Power BI

All dimensions follow these modeling rules:

* one-to-many relationships (Dimension → Fact)
* single-direction filtering
* no relationships between fact tables
* one active date relationship per fact

This guarantees deterministic filtering and avoids ambiguous paths.

---

## Governance & Change Control

Any change to a dimension referenced here requires:

1. Impact analysis across all `Fact_KPI_*` tables
2. Confirmation that keys remain stable
3. Revalidation of affected KPIs (Step 06)
4. Update to this documentation

Dimension changes are **high-risk** and must be treated accordingly.

---

## Relationship to Other Steps

* **Step 06.01 — Fact KPI SQL**
  Consumes dimensions via surrogate keys.

* **Step 06.03 — Power BI Model**
  Implements relationships and measures using these dimensions.

* **Step 06.05 — Validation**
  Confirms KPI correctness *before* semantic modeling.

---

## Final Principle

> **Facts measure events.**
> **Dimensions provide context.**
> **Consistency across dimensions is what makes KPIs trustworthy.**

This folder exists to protect that consistency.
