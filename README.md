# Long Island, NY Hospitals

## Healthcare Data Analytics & Business Intelligence

## Executive Summary

This repository presents an end-to-end healthcare analytics initiative analyzing Long Island hospital performance across clinical, operational, and financial dimensions. The project integrates SQL-based data engineering, Excel-based validation, and a Power BI semantic model to surface **explainable, decision-relevant signals** for healthcare leadership.

The analysis is deliberately structured to **establish operating context first**, and only then interpret outcome metrics within that context. This design reduces misinterpretation and helps decision-makers distinguish structural operating conditions from true performance differences.

**Analytical Framework**

* **Operating Context**

  * Patient acuity and case mix (Severity Mix)
  * Intake dynamics (Unplanned Admissions)
  * Reimbursement exposure (Payer Mix)

* **Outcome Signals**

  * Financial stress (Cost & Margin Pressure)
  * Clinical risk exposure (Mortality)
  * Throughput efficiency (Length of Stay)
  * Exit flow distribution (Disposition)

This is a **descriptive, explainability-first analysis**, not a causal or predictive model.

---

## Project Scope & Business Value

This project addresses core questions faced by healthcare executives and analytics teams.

### Establishing Operating Reality (Context KPIs)

* **Severity Mix**
  What level of patient acuity is being treated, and how comparable is case mix across facilities?

* **Unplanned Intake**
  To what extent is system demand driven by unscheduled admissions, and how much baseline pressure does this impose?

* **Payer Mix**
  What reimbursement structures shape downstream financial and operational outcomes?

### Interpreting Outcomes Within Context

* **Cost & Margin Pressure**
  Financial sustainability under observed case mix and payer exposure.

* **Mortality (Outcome Risk)**
  Distribution of mortality exposure interpreted within severity, intake, and throughput context.

* **Length of Stay (Throughput)**
  Efficiency and congestion signals after accounting for demand and patient complexity.

* **Disposition (Exit Flow)**
  How inpatient episodes resolve across discharge destinations and downstream capacity.

All outcome metrics are interpreted **relative to established context**, not as isolated performance scores.

---

## Repository Structure

The repository follows a **pipeline-oriented structure**, progressing from raw data preparation through KPI development and executive-ready analytics.

```
LongIsland_NY_Hospitals_SQL_Excel_PowerBI_Analysis/
├── 00_DB_Creation/              # Database schemas and initial load scripts
├── 01_Profiling/                # Data profiling and exploratory SQL
├── 02_Data_Cleaning/            # Cleaning, normalization, and standardization
├── 03_Analytical_Data_Modeling/ # Analytical star schema and peer-group framework
├── 04_Analytical_Validation/    # SQL and Excel-based reconciliation checks
├── 05_KPI_Dev/                  # KPI-specific SQL logic and Excel validation packs
├── 06_PBI_Semantic_Model/       # Fact KPI layer, dimensions, Power BI semantic model, data dictionary
└── 07_Excel_Executive_Analytics/# Executive Excel dashboards, screenshots, and templates
```

This structure mirrors how enterprise healthcare analytics teams separate **data engineering**, **KPI logic**, **validation**, and **semantic modeling**.

---

## Data & Methodology

* **Data Source**
  Long Island hospital system operational data (2015 snapshot).
  The dataset is sufficient to demonstrate cross-facility structural patterns but is not intended for time-series inference.

* **Analytical Approach**
  Explainability-first, non-causal descriptive analysis designed to surface structural signals rather than infer causality.
  Each KPI includes a *Diagnostic Preview* highlighting domains where deeper analysis would typically be warranted.

* **Validation & Governance**

  * SQL-level checks and Excel reconciliation
  * Explicit KPI definitions and business rules
  * Anonymized data; no patient-identifiable information included

**Key Principle**
All KPIs are treated as **contextual signals**, not absolute rankings or performance judgments.

---

## Technical Stack

| Layer                      | Tooling                       |
| -------------------------- | ----------------------------- |
| Data Engineering           | SQL Server (SSMS), PostgreSQL |
| Validation & QA            | Excel                         |
| Semantic Model & Reporting | Power BI (PBIP project)       |
| Version Control            | Git / GitHub                  |

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/jendives2000/LongIsland_NY_Hospitals_SQL_Excel_PowerBI_Analysis.git
cd LongIsland_NY_Hospitals_SQL_Excel_PowerBI_Analysis
```

### 2. Database Setup

Execute scripts in `00_DB_Creation/` to establish schemas and base tables.
Subsequent folders (`01_Profiling` through `03_Analytical_Data_Modeling`) reflect the logical build-up of the analytical model.

### 3. Review the Analysis

* **Primary analytical narrative**
  Open the Power BI project in
  `06_PBI_Semantic_Model/03_PowerBI_Model/`
  This contains the semantic model, report structure, and KPI interpretation.

* **KPI logic and validation**
  Review `05_KPI_Dev/` for KPI-specific SQL logic and Excel validation artifacts.

* **Quality assurance**
  Refer to `04_Analytical_Validation/` and `06_PBI_Semantic_Model/05_Validation/` for reconciliation and QA outputs.

* **Executive Excel outputs**
  See `07_Excel_Executive_Analytics/` for Excel-based executive views.

---

## Power BI Report Navigation

**Recommended reading order**

1. **Severity Mix (Context)**
2. **Unplanned Intake (Context)**
3. **Payer Mix (Context)**
4. **Cost & Margin Pressure**
5. **Mortality (Outcome Risk)**
6. **Length of Stay (Throughput)**
7. **Disposition (Exit Flow)**

Outcome pages assume prior context unless explicitly stated otherwise.

---

## Key Deliverables

* Enterprise-style Power BI semantic model and report
* KPI-level SQL logic with validation lineage
* Data dictionary and business rule documentation
* Diagnostic previews to guide further investigation
* Executive-ready Power BI and Excel artifacts

---

## Data Privacy & Compliance

* Patient data anonymized; no PII present
* HIPAA-conscious handling principles applied
* Raw or sensitive data excluded from version control
* Repository designed for auditability and reproducibility

---

## Intended Audience & Use

* Healthcare executives and operational leaders
* Senior data analysts and analytics engineers
* Healthcare BI and decision-support teams
* Recruiters evaluating healthcare analytics capability

This repository is a **portfolio demonstration** of how to design, validate, and communicate healthcare analytics in an enterprise setting.

---

## Author

**Jean-Yves Tran**
Healthcare Data Analyst
📧 [jy.tran@datascience-jy.com](mailto:jy.tran@datascience-jy.com)

---

## License

MIT License — see LICENSE file for details

**Generated:** 2025
**Last Updated:** February 2026

---
