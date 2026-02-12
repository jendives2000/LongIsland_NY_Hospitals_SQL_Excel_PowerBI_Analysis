# 03 - Analytical Data Modeling

## Purpose

This step builds the analytical model used by downstream validation, KPI development, and semantic modeling.

It converts cleaned source data into a star-schema-aligned structure with reusable dimensions, encounter-level fact logic, and explicit peer-group context for fair comparison.

This step defines structural analytical contracts. It does not define KPI formulas.

---

## Explainability-First Role in the Pipeline

Modeling decisions are explicit and reusable:

- Dimensions hold context (facility, payer, disposition, admission type, clinical class, date, peer group)
- Fact tables hold events and numeric signals
- Peer comparison context is modeled as data, not hard-coded into KPI SQL or DAX

This reduces interpretation risk and prevents logic drift across KPI domains.

---

## Scope

### Input

- Cleaned source table from Step 02:
  - `dbo.LI_SPARCS_2015_25_Inpatient`

### SQL Artifacts

- `03_SQL/3_1_dim_facility.sql`
- `03_SQL/3_2_dim_admissionType.sql`
- `03_SQL/3_3_dim_disposition.sql`
- `03_SQL/3_4_dim_payers.sql`
- `03_SQL/3_5_dim_clinical_class.sql`
- `03_SQL/3_6_dim_date.sql`
- `03_SQL/3_6b_2015_synthetic_dates.sql`
- `03_SQL/3_6c_dim_peergroup.sql`
- `03_SQL/3_6d_bridge_facility_peergroup.sql`
- `03_SQL/3_7_Fact_Table_inpatient_stay.sql`

### Peer Grouping Submodule

- `03_Facility_Peer_Grouping_Framework/README.md`
- `03_Facility_Peer_Grouping_Framework/seed_dim_peergroup_and_bridge.sql`

### Evidence Artifacts

- `image.png` through `image-9.png`
- `03_Facility_Peer_Grouping_Framework/image.png`
- `03_Facility_Peer_Grouping_Framework/image-1.png`

---

## Model Objects Created

### Core Dimensions

- `Dim_Facility`
- `Dim_AdmissionType`
- `Dim_Disposition`
- `Dim_Payer`
- `Dim_ClinicalClass`
- `Dim_Date`
- `Dim_PeerGroup`
- `Bridge_Facility_PeerGroup` (factless bridge)

### Encounter Fact Layer

- `Fact_Encounter` (encounter grain)

`Fact_Encounter` carries key references plus core numerics (`LOS_Sim`, `Total_Charges`, `Total_Costs`, `ED_Flag`) and is prepared for analytical aggregation.

---

## Date Modeling Note (Important)

This folder contains two date strategies:

1. `3_6_dim_date.sql`
- Creates a multi-year date dimension (2015-2025)
- Links encounters through year-anchor logic

2. `3_6b_2015_synthetic_dates.sql`
- Creates synthetic admission/discharge dates
- Rebuilds `Dim_Date` at daily 2015 grain
- Supports portfolio time slicing when only year-level source timing exists

Given the available dataset snapshot, analytical interpretation remains 2015-based. Synthetic dates are modeling utilities, not real clinical timestamps.

---

## Peer Grouping as a First-Class Modeling Construct

Peer-group context is modeled in SQL through:

- `Dim_PeerGroup` (taxonomy)
- `Bridge_Facility_PeerGroup` (facility-to-group assignments)

This keeps peer logic out of KPI formulas and enables consistent filtering across downstream KPI facts.

Detailed governance and assignment logic are documented in:

- `03_Facility_Peer_Grouping_Framework/README.md`

---

## Output Contract to Step 04 and Step 05

This step provides the structural contract consumed by:

- `04_Analytical_Validation` for reconciliation and integrity checks
- `05_KPI_Dev` for KPI logic built on standardized dimensions and encounter grain

Required assumptions for downstream layers:

- Dimension keys are populated and stable
- Peer-group assignments are seeded and auditable
- Fact encounter grain is preserved

---

## Position in End-to-End Lifecycle

- `00_DB_Creation`: database and ingestion readiness
- `01_Profiling`: diagnostics
- `02_Data_Cleaning`: deterministic remediation
- `03_Analytical_Data_Modeling`: dimensional and fact design (this step)
- `04_Analytical_Validation`: SQL and Excel reconciliation
- `05_KPI_Dev`: KPI definition and certification
- `06_PBI_Semantic_Model`: BI semantic contract
- `07_Excel_Executive_Analytics`: executive consumption layer

---

## Folder Contents

```text
03_Analytical_Data_Modeling/
|-- README.md
|-- image.png
|-- image-1.png
|-- image-2.png
|-- image-3.png
|-- image-4.png
|-- image-5.png
|-- image-6.png
|-- image-7.png
|-- image-8.png
|-- image-9.png
|-- 03_SQL/
|   |-- 3_1_dim_facility.sql
|   |-- 3_2_dim_admissionType.sql
|   |-- 3_3_dim_disposition.sql
|   |-- 3_4_dim_payers.sql
|   |-- 3_5_dim_clinical_class.sql
|   |-- 3_6_dim_date.sql
|   |-- 3_6b_2015_synthetic_dates.sql
|   |-- 3_6c_dim_peergroup.sql
|   |-- 3_6d_bridge_facility_peergroup.sql
|   `-- 3_7_Fact_Table_inpatient_stay.sql
`-- 03_Facility_Peer_Grouping_Framework/
    |-- README.md
    |-- seed_dim_peergroup_and_bridge.sql
    |-- image.png
    `-- image-1.png
```
