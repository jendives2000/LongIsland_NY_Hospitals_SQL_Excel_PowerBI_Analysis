# Long Island, NY Hospitals: Data Analytics & Business Intelligence

## Executive Summary

This repository demonstrates a comprehensive healthcare analytics initiative analyzing Long Island hospital performance metrics. The project combines SQL-based data engineering, Excel-driven analysis, and Power BI visualization to surface actionable insights on hospital operations, capacity utilization, clinical outcomes, and resource allocation—directly supporting strategic decision-making for healthcare leadership.

The analysis is structured to **establish operating context first, then interpret outcome performance** within that context—enabling healthcare leaders to distinguish true performance from operational variation.

**Analytical Framework:**
- **Operating Context:** Patient acuity (Severity Mix), arrival patterns (Unplanned Intake), payer composition
- **Outcome Metrics:** Financial pressure (Cost & Margin), clinical risk (Mortality), throughput efficiency (Length of Stay), patient disposition (Exit Flow)

## Project Scope & Business Value

This analysis addresses core healthcare executive needs through a context-driven lens:

**Understanding Hospital Operating Reality:**
- **Severity Mix (Context):** What mix of patient acuity are we treating? (Direct impact on cost, outcomes, staffing)
- **Unplanned Intake (Context):** What proportion of patients arrive unscheduled vs. planned? (Capacity pressure, operational complexity)
- **Payer Mix (Context):** What is our reimbursement exposure? (Financial sustainability, margin pressure)

**Interpreting Outcome Performance:**
- **Cost & Margin Pressure (Financial Stress):** Are we sustainable given our patient population?
- **Mortality (Outcome Risk):** How does clinical performance compare, adjusted for case mix?
- **Length of Stay (Throughput):** How efficiently are we managing patient flow?
- **Disposition (Exit Flow):** Where are patients going post-discharge? (Readmission risk, continuity of care)

## Repository Structure

```
LongIsland_NY_Hospitals_SQL_Excel_PowerBI_Analysis/
├── Step_0_DB_Creation/          # Database schemas and data pipeline setup
├── data/                         # Processed analytical datasets (CSV/Excel)
├── notebooks/                    # Analysis and exploratory work
├── powerbi/                      # Interactive dashboards and reports (.pbix)
└── README.md                     # This file
```

## Data & Methodology

- **Data Source:** Long Island hospital system operational data. Year 2015 only.
- **Data:** SQL for database + data extraction, and data validation made in Excel
- **Analysis:** Explainability-first, non-causal analysis in line with descriptive analytics of advanced healthcare analytics. Each KPI analysis is added with a diagnosis preview, listing potential domains to invest further analysis in.
- **Visualization:** Power BI report organized by operating context, then outcome metrics. Each KPI page comprises a landing page and 3 to 4 visuals
- **Governance:** Anonymized data; no PII or sensitive patient information included

**Key Principle:**   
All KPIs should be interpreted as contextual signals, not absolute performance rankings. Diagnostic Preview for each KPI lists potential domains where typical further analysis could be done. 

## Technical Stack

| Component | Tool |
|-----------|------|
| Data Warehouse | SSMS22 SQL Server / PostgreSQL |
| Analysis | Excel, Power BI |
| Visualization | Power BI Desktop |
| Version Control | Git/GitHub |

## Getting Started

### 1. Clone & Setup
```bash
git clone https://github.com/jendives2000/LongIsland_NY_Hospitals_SQL_Excel_PowerBI_Analysis.git
cd LongIsland_NY_Hospitals_SQL_Excel_PowerBI_Analysis
```

### 2. Database Initialization
Review and execute scripts in `Step_0_DB_Creation/` to establish the analytical data mart.

### 3. Review Analysis
- Examine processed datasets in `data/`
- Review analytical notebooks in `notebooks/` for methodology and assumptions
- Open Power BI files in `powerbi/` for interactive dashboards

### 4. Navigate the Power BI Report
**Start with Context Pages (establish baseline understanding):**
1. **Severity Mix (Context)** — Patient acuity distribution; shapes all downstream outcomes
2. **Unplanned Intake (Context)** — Emergency vs. scheduled admission patterns; operational pressure indicator
3. **Payer Mix (Context)** — Insurance composition; financial sustainability driver

**Then Review Outcome Metrics (interpret within context):**
4. **Cost & Margin Pressure (Financial Stress)** — Unit economics and reimbursement adequacy
5. **Mortality (Outcome Risk)** — Clinical outcomes adjusted for case complexity
6. **Length of Stay (Throughput)** — Care efficiency and operational performance
7. **Disposition (Exit Flow)** — Post-acute placement and continuity of care

**Refer back to context pages when reviewing outcomes to distinguish population differences from performance variation.**

## Key Insights & Deliverables

- **Executive Dashboard:** Multi-page Power BI report with guided navigation order
- **Context-Driven Analysis:** Operating environment established before outcome interpretation
- **Analytical Notebooks:** Documented methodology, assumptions, and limitations
- **Data Dictionary:** Field definitions and business rule transparency
- **Decision-Support Framing:** Structured to reduce misinterpretation and support informed leadership decisions

## Data Privacy & Compliance

- ✓ All patient-identifiable information (PII) removed or anonymized
- ✓ HIPAA-conscious data handling and governance practices
- ✓ Data minimization principles applied
- ✓ Version control excludes raw or sensitive datasets
- ✓ Recommended `.gitignore` includes large binary files (`.xlsx`, `.pbix`)

## Best Practices Implemented

- **Version Control:** Git history for reproducibility and audit trail
- **Documentation:** Inline comments and data dictionaries for clarity
- **Code Quality:** Modular SQL scripts and organized notebooks
- **Data Validation:** Integrity checks and reconciliation procedures
- **Analytical Rigor:** Context-first interpretation to prevent false conclusions
- **Scalability:** Designed for expansion to multi-site hospital networks

## Recommendations for Healthcare Leaders

This project framework can be extended to:
- Multi-hospital network benchmarking with context-adjusted outcome comparison
- Predictive modeling for patient demand and resource forecasting
- Quality improvement initiatives grounded in root-cause investigation
- Financial impact modeling and scenario planning
- Integration with EHR data for enhanced clinical outcome correlation

## Author & Contact

**Project Owner:** jendives2000  
**Purpose:** Portfolio demonstration of healthcare analytics competency  
**Audience:** Healthcare executives, data analysts, clinical operations leaders, recruiters

For questions or collaboration inquiries, please contact via GitHub or professional networks.

---

## License

MIT License — See LICENSE file for details

**Generated:** 2025  
**Last Updated:** 2025
