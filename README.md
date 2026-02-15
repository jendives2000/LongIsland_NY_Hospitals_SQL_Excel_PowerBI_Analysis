# Long Island, NY Hospitals

## Healthcare Data Analytics & Business Intelligence
![Tool: Power BI](https://img.shields.io/badge/Tool-Power%20BI-F2C811?style=flat-square&labelColor=2b2f3a&logo=powerbi&logoColor=000000)
![Tool: SQL Server](https://img.shields.io/badge/Tool-SQL%20Server-CC2927?style=flat-square&labelColor=2b2f3a&logo=microsoftsqlserver&logoColor=ffffff)
![Tool: Excel](https://img.shields.io/badge/Tool-Excel-217346?style=flat-square&labelColor=2b2f3a&logo=microsoftexcel&logoColor=ffffff)
![Language: T-SQL](https://img.shields.io/badge/Language-T--SQL-0078D4?style=flat-square&labelColor=2b2f3a)
![Language: DAX](https://img.shields.io/badge/Language-DAX-0078D4?style=flat-square&labelColor=2b2f3a)
![Domain: Healthcare](https://img.shields.io/badge/Domain-Healthcare-84BD00?style=flat-square&labelColor=2b2f3a)
## Executive Summary

This repository presents an end-to-end healthcare analytics initiative analyzing Long Island hospital performance across clinical, operational, and financial dimensions. The project integrates SQL-based data engineering, Excel-based validation, and a Power BI semantic model to surface **explainable, decision-relevant signals** for healthcare leadership.

The analysis is deliberately structured to **establish operating context first**, and only then interpret outcome metrics within that context. This design reduces misinterpretation and helps decision-makers distinguish structural operating conditions from true performance differences.

**Analytical Framework**

* **Operating Context**

  * Patient acuity and case mix (Severity Mix)
  * Intake dynamics (Unplanned Admissions)
  * Reimbursement exposure (Payer Mix)

* **Outcome Signals**

  * Throughput efficiency (Length of Stay)
  * Clinical risk exposure (Mortality)
  * Financial stress (Cost & Margin Pressure)
  * Exit flow distribution (Disposition)

This is an advanced **descriptive, explainability-first analysis**, not a causal or predictive model.

---

<details>
<summary><b>Table of Contents</b></summary>

- [Long Island, NY Hospitals](#long-island-ny-hospitals)
  - [Healthcare Data Analytics \& Business Intelligence](#healthcare-data-analytics--business-intelligence)
  - [Executive Summary](#executive-summary)
  - [Project Scope \& Business Value](#project-scope--business-value)
    - [Establishing Operating Reality (Context KPIs)](#establishing-operating-reality-context-kpis)
    - [Interpreting Outcomes Within Context](#interpreting-outcomes-within-context)
  - [Repository Structure](#repository-structure)
  - [Data \& Methodology](#data--methodology)
  - [Technical Stack](#technical-stack)
  - [Getting Started](#getting-started)
    - [1. Clone the Repository](#1-clone-the-repository)
    - [2. Database Setup](#2-database-setup)
      - [**Note \& Attribution about the Data:**](#note--attribution-about-the-data)
    - [3. Review the Analysis](#3-review-the-analysis)
  - [Power BI Report Navigation](#power-bi-report-navigation)
  - [Key Deliverables](#key-deliverables)
  - [Data Privacy \& Compliance](#data-privacy--compliance)
  - [Intended Audience \& Use](#intended-audience--use)
  - [Author](#author)
  - [License](#license)

</details>

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

* **Length of Stay (Throughput)**  
  Efficiency and congestion signals after accounting for demand and patient complexity.

* **Mortality (Outcome Risk)**  
  Distribution of mortality exposure interpreted within severity, intake, and throughput context.

* **Cost & Margin Pressure**  
  Financial sustainability under observed case mix and payer exposure.

* **Disposition (Exit Flow)**  
  How inpatient episodes resolve across discharge destinations and downstream capacity.

All outcome metrics are interpreted **relative to established context**, not as isolated performance scores.

---

## Repository Structure

The repository follows a **pipeline-oriented structure**, progressing from raw data preparation through KPI development and executive-ready analytics.

```
LongIsland_NY_Hospitals_SQL_Excel_PowerBI_Analysis/
├── 00_DB_Creation/                  # Database schemas and initial load scripts
├── 01_Profiling/                    # Data profiling and exploratory SQL
├── 02_Data_Cleaning/                # Cleaning, normalization, and standardization
├── 03_Analytical_Data_Modeling/     # Analytical star schema and peer-group framework
├── 04_Analytical_Validation/        # SQL and Excel-based reconciliation checks
├── 05_KPI_Dev/                      # KPI-specific SQL logic and Excel validation packs
├── 06_PBI_Semantic_Model/           # Fact KPI layer, dimensions, Power BI semantic model, data dictionary
├── 07_Excel_Executive_Analytics/    # Executive Excel dashboards, screenshots, and templates
└── Live_Report                      # Online access to the Report
```

This structure mirrors how enterprise healthcare analytics teams separate **data engineering**, **KPI logic**, **validation**, and **semantic modeling**.

---

## Data & Methodology

* **Data Source**  
  Long Island hospital system operational data (2015 snapshot).
  The dataset is sufficient to demonstrate cross-facility structural patterns but is not intended for time-series inference.

* **Analytical Approach**  
  Explainability-first, non-causal advanced descriptive analysis designed to surface structural signals and not to infer causality.
  Each KPI includes a *Diagnostic Preview* highlighting domains where deeper analysis would typically be warranted.  
  
  All narrative and explainability text in this project is grounded in established healthcare explainability, communication, and governance frameworks, adapted into a context-first, non-causal analytical design suitable for executive and system-level decision support.

* **Validation & Governance**  

  * SQL-level checks and Excel reconciliation
  * Explicit KPI definitions and business rules
  * Anonymized data; no patient-identifiable information included

**Key Principle**  
**Contextual signals** KPIs are treated first, output KPIs second. There is  no absolute rankings or performance judgments.

---

## Technical Stack

| Layer                      | Tooling                       |
| -------------------------- | ----------------------------- |
| Data Engineering           | SQL Server (SSMS22), TSQL |
| Validation & QA           | Excel                         |
| Semantic Model & Reporting | Power BI (PBIP project)       |
| Version Control            | Git / GitHub, VsCode                 |

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/jendives2000/LongIsland_NY_Hospitals_SQL_Excel_PowerBI_Analysis.git
cd LongIsland_NY_Hospitals_SQL_Excel_PowerBI_Analysis
```

### 2. Database Setup

Download the original dataset and execute scripts in [`00_DB_Creation/`](/00_DB_Creation/README.md) to establish schemas and base tables.
Subsequent folders ([`01_Profiling`](/01_Profiling/README.md) through [`03_Analytical_Data_Modeling`](/03_Analytical_Data_Modeling/README.md)) reflect the logical build-up of the analytical model.

#### **Note & Attribution about the Data:**  
* [Data Access page](https://health.data.ny.gov/Health/Hospital-Inpatient-Discharges-SPARCS-De-Identified/82xm-y6g8/about_data)  
* First published on July 11, 2017  
The New York State Department of Health, which is the source provider of the data used in this work, makes no representation, warranty or guarantee relating to the data or analyses derived from these data.

### 3. Review the Analysis

* **Primary analytical narrative**  
  Open the Power BI project in  
  [`06_PBI_Semantic_Model/03_PowerBI_Model/`](/06_PBI_Semantic_Model/README.md)  
  This contains the semantic model, report structure, and KPI interpretation.

  The report is also available for consumption.  
  Access the live report by clicking [here](https://jendives2000.github.io/LongIsland_NY_Hospitals_SQL_Excel_PowerBI_Analysis/Live_Report/).  
  The live report was made available for consumption via the Github page feature and an index .html file, both were set up in this repo. Access the folder [here](/Live_Report/README.md).

* **KPI logic and validation**  
  Review [`05_KPI_Dev/`](/05_KPI_Dev/README.md) for KPI-specific SQL logic and Excel validation artifacts.

* **Quality assurance**  
  Refer to [`04_Analytical_Validation/`](/04_Analytical_Validation/README.md) and [`06_PBI_Semantic_Model/05_Validation/`](/06_PBI_Semantic_Model/05_Validation/README.md) for reconciliation and QA outputs.

* **Executive Excel outputs**  
  See [`07_Excel_Executive_Analytics/`](/07_Excel_Executive_Analytics/README.md) for Excel-based executive views.

---

## Power BI Report Navigation

**Recommended reading order**

1. **Severity Mix (Context)**
2. **Unplanned Intake (Context)**
3. **Payer Mix (Context)**
4. **Length of Stay (Throughput)**
5. **Mortality (Outcome Risk)**
6. **Cost & Margin Pressure**
7. **Disposition (Exit Flow)**

Outcome pages assume prior context.

---

## Key Deliverables

* Enterprise-style Power BI semantic model and report
* KPI-level SQL logic with validation lineage
* Data dictionary and business rule documentation with comprehensive metadata integration
  * Clear measure definitions and business rule documentation across all KPI domains to support faster onboarding and reduce interpretation risk
* Diagnostic previews to initiate further investigations
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

⭐ If you found this project insightful, feel free to connect or reach out!