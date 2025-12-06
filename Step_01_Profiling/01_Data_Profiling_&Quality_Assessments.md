# 🧩 Step 01 — Data Profiling & Quality Assessment (SQL Server)

To ensure clinical and financial insights derived from the SPARCS 2015 inpatient dataset are accurate and trustworthy, I performed a comprehensive **column-level data profiling** directly in SQL Server.  
The SQL code is [here]().

This step supports two primary goals:

- Understand completeness, consistency, and validity across all fields  
- Identify data quality issues requiring cleaning before BI modeling  

---

## ✔️ What Was Done

Using dynamic SQL and schema-driven profiling, I systematically analyzed:

- **34 columns** of inpatient discharge data stored in SQL Server  
- Metrics generated for each column:
  - Minimum & maximum values
  - NULL counts & NULL %
  - Distinct counts
  - Mode (most frequent value)
  - Numeric-specific metrics (where applicable)

Profiling was executed **before** cleaning, in line with industry frameworks:  
**CRISP-DM**, **DAMA-DMBOK**, **Healthcare Data Quality Lifecycle**

Output stored into: `#ColumnProfile`

---

## 📊 Profiling Results — Key Findings & Red Flags

| Category | Red Flag Identified | Why It Matters in Healthcare | Impact |
|---------|-------------------|-----------------------------|--------|
| Data Type | `Total_Charges`, `Total_Costs` are stored as **NVARCHAR with `$` formatting** | Prevents accurate cost/charge analytics | 🔥 Critical |
| Missingness | `Zip_Code_3_digits`: **2,890 NULLs** + non-numeric “OOS” | Location and socio-economic stratification become unreliable | 🔥 High |
| Category Quality | Demographics contain **“Unknown”, “Multi-ethnic”, “Not Span/Hispanic”** as mode values | Masking disparities → reduces equity insight quality | 🔥 High |
| Business Rule Violations | `Birth_Weight` max = **900g** → unusually low upper bound | Potential unit/measurement issue | ⚠️ Medium |
| Clinical Grouping | Many clinical fields have **very high cardinality** (Diagnosis, Procedure descriptions) | Requires modeling into separate Dim tables | ⚠️ Medium |
| Standardization Needed | `Type_of_Admission` has varying labels e.g. “Elective”, “Urgent” | Affects ED vs Elective trends | ⚠️ Medium |
| Structural | No primary key or encounter identifier | Hard to ensure encounter uniqueness | ⚠️ Medium |
| Performance | Text columns with `-1` max length (unbounded) | Poor indexing & storage efficiency | ⚠️ Medium |

> Summary: financial, demographic, and geographic fields require targeted remediation before insights can be trusted.

---

## 🧭 Step 01 Output → Interpretation

This profiling confirms:

- The dataset is **clinically rich** but **requires careful standardization**
- LOS, ED utilization, and payer mix analytics are viable after cleaning
- Demographics and location must be **handled carefully** in equity lenses

This step enables a data-driven cleaning and modeling plan rather than assumptions.

---

# 🛠️ Step 02 — Required Data Cleaning Actions

| Issue | Resolution Strategy | Fields Impacted |
|------|-------------------|----------------|
| Currency formatting | Strip `$` and commas → convert to DECIMAL | `Total_Charges`, `Total_Costs` |
| Geographic anomalies | Standardize “OOS”, validate ZIP masks | `Zip_Code_3_digits` |
| Demographic placeholders | Convert to consistent unknown category | `Race`, `Ethnicity` |
| Category normalization | Align labels and group into high-level categories | `Type_of_Admission`, `Patient_Disposition` |
| Text overflow | Apply explicit VARCHAR(Max) only where needed | Description fields |
| Missing primary key | Create surrogate encounter key | All rows |
| Payer granularity | Group Payment Typologies into standard payer buckets | Payment Typology fields |

Deliverable from Step 02:  
> A cleaned analytical model (views or tables) aligned with a **star schema**, ready for BI.

---

## 📌 Current Status

| Stage | Status | Notes |
|-------|--------|------|
| Step 00 — Data Ingestion & Setup | ✅ Complete | Dataset successfully imported |
| **Step 01 — Profiling & Quality Assessment** | 🟩 Complete | Issues clearly identified |
| Step 02 — Cleaning & Standardization | 🔜 Next | SQL transformations required |
| Step 03 — Dimensional Modeling | Planned | Build star schema |
| Step 04 — Power BI Insights | Planned | KPI storytelling |

---

## 📁 Suggested Repository Structure

