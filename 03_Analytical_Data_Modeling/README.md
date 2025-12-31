# Analytical Data Modeling

This folder contains the **core analytical data model** for the project.  
It defines the dimensional structures, fact tables, and semantic layers used to support all downstream KPI development, benchmarking, and executive reporting.

The goal of this layer is to ensure that **all analytics are structurally sound, clinically fair, and analytically defensible** before any visualization or interpretation occurs.

---

## Table of Contents

- [Analytical Data Modeling](#analytical-data-modeling)
  - [Table of Contents](#table-of-contents)
  - [Purpose of This Layer](#purpose-of-this-layer)
  - [Modeling Principles](#modeling-principles)
  - [Dimensional Schema Overview](#dimensional-schema-overview)
  - [Peer Grouping as a Core Modeling Concept](#peer-grouping-as-a-core-modeling-concept)
  - [SQL Artifacts in This Folder](#sql-artifacts-in-this-folder)
    - [Core Dimensions](#core-dimensions)
    - [Dimension Tables](#dimension-tables)
    - [Temporal Data Availability (Important)](#temporal-data-availability-important)
    - [Peer Grouping Dimensions and Bridge](#peer-grouping-dimensions-and-bridge)
      - [`3_6c_dim_peergroup.sql`](#3_6c_dim_peergroupsql)
      - [`3_6d_bridge_facility_peergroup.sql`](#3_6d_bridge_facility_peergroupsql)
    - [Fact Tables](#fact-tables)
  - [Relationship to KPI Development](#relationship-to-kpi-development)
  - [Downstream Consumption (Power BI)](#downstream-consumption-power-bi)
  - [Summary](#summary)

---

## Purpose of This Layer

The Analytical Data Modeling layer:

- Establishes the **canonical star schema**
- Defines **dimensions, facts, and bridges**
- Encodes **business and clinical context** that must be consistent across all KPIs
- Prevents KPI logic from compensating for structural modeling gaps

This layer is intentionally **independent of Power BI**, DAX, or visualization concerns.

---

## Modeling Principles

All objects in this layer follow these principles:

1. **Star schema first**  
   Facts connect only to dimensions. Context is expressed via dimensions, not measures.

2. **Semantic correctness over convenience**  
   Modeling decisions reflect healthcare reality, not visualization shortcuts.

3. **Reusability across KPIs**  
   A dimension added here must support multiple analytical questions.

4. **Explicit comparison context**  
   Peer groups, severity, and payer context are modeled explicitly rather than inferred ad hoc.

---

## Dimensional Schema Overview

At a high level, the model consists of:

- Encounter-level fact tables
- Clinical, administrative, and temporal dimensions
- Factless bridges to support many-to-many analytical context

This structure enables consistent KPI evaluation across:
- Facilities
- Time
- Clinical severity
- Payer mix
- Peer comparison lenses

---

## Peer Grouping as a Core Modeling Concept

Peer grouping is a **first-class component** of the analytical data model.

Hospitals cannot be meaningfully compared without accounting for:
- Teaching and referral role
- Acuity and case mix
- Specialty concentration
- Rural vs urban constraints
- Safety-net mission

For this reason, peer grouping is implemented at the **data model level**, not inside KPI SQL or Power BI measures.

---

## SQL Artifacts in This Folder

### Core Dimensions

These scripts create the primary descriptive dimensions used by all facts:

- `3_1_dim_facility.sql`
- `3_2_dim_admissionType.sql`
- `3_3_dim_disposition.sql`
- `3_4_dim_payers.sql`
- `3_5_dim_clinical_class.sql`
- `3_6_dim_date.sql`
- `3_6b_2015_synthetic_dates.sql`

### Dimension Tables

| Dimension | What it describes | Why it matters | SQL Script |
|----------|------------------|----------------|------------|
| Dim_Facility | Hospital identity & region | Facility comparison & care distribution | [3_1_dim_facility.sql](./03_SQL/3_1_dim_facility.sql) |
| Dim_AdmissionType | How and why the stay began | Unplanned burden & ED flow analysis | [3_2_dim_admissionType.sql](./03_SQL/3_2_dim_admissionType.sql) |
| Dim_Disposition | Where the patient went after discharge | Care continuity, readmissions, population tracking | [3_3_dim_disposition.sql](./03_SQL/3_3_dim_disposition.sql) |
| Dim_Payer | Insurance category | Cost burden & reimbursement analysis | [3_4_dim_payers.sql](./03_SQL/3_4_dim_payers.sql) |
| Dim_ClinicalClass | APR-DRG clinical grouping | Risk stratification & case-mix comparison | [3_5_dim_clinical_class.sql](./03_SQL/3_5_dim_clinical_class.sql) |
| Dim_Date | Calendar date dimension (synthetically extended) | Time-series analysis & temporal slicing | [3_6_dim_date.sql](./03_SQL/3_6_dim_date.sql) |
| Dim_Year | Reporting year abstraction | Explicit yearly slicing and KPI scoping | Derived from Dim_Date |
| Dim_PeerGroup | Hospital peer taxonomy (PG-A → PG-E) | Fair benchmarking and executive interpretation | [3_6c_dim_peergroup.sql](./03_SQL/3_6c_dim_peergroup.sql) |


### Temporal Data Availability (Important)

Although the `Dim_Date` table is synthetically populated across multiple years
(to support future extensibility and consistent time intelligence),
**actual encounter data exists only for the 2015 reporting year**.

As a result:

- All KPIs reflect **2015-only inpatient activity**
- Multi-year trends are **not interpreted as longitudinal performance**
- The extended date range exists to support:
  - reusable time-intelligence logic
  - future data integration
  - consistent dimensional modeling patterns

This distinction is intentional and explicitly documented to avoid analytical misinterpretation.


---

### Peer Grouping Dimensions and Bridge

The following scripts extend the model to support **peer-based benchmarking**:

#### `3_6c_dim_peergroup.sql`
- SQL file: [here](./03_SQL/3_6c_dim_peergroup.sql)
  
Creates the `dbo.Dim_PeerGroup` dimension.

- Grain: one row per peer group
- Purpose: define the canonical peer group taxonomy (PG-A through PG-E)
- Role: analytical comparison lens used across all KPIs

This table contains **no facility data** and no KPI logic. I populated the table with the seed SQL code in this [folder](./03_Facility_Peer_Grouping_Framework/README.md).

#### `3_6d_bridge_facility_peergroup.sql`
- SQL file: [here](./03_SQL/3_6d_bridge_facility_peergroup.sql)
  
Creates the `dbo.Bridge_Facility_PeerGroup` factless bridge.

- Grain: one row per Facility–PeerGroup assignment
- Purpose: resolve the many-to-many relationship between facilities and peer groups
- Contains only foreign keys (`Facility_Key`, `PeerGroup_Key`)

This bridge enables peer-group slicing without duplicating fact rows or embedding logic in measures.

---

### Fact Tables
- SQL file: [`3_7_Fact_Table_inpatient_stay.sql`](./03_SQL/3_7_Fact_Table_inpatient_stay.sql)

This script creates the encounter-level fact table used by all inpatient KPIs.

Fact tables:
- Contain measurable events
- Do not encode peer logic
- Inherit comparison context exclusively via dimensions and bridges

---

## Relationship to KPI Development

KPI SQL files (in `05_KPI_Dev`) **assume this model already exists**.

Specifically:
- KPIs never define peer groups
- KPIs never join facilities directly to peer logic
- KPIs rely on dimensional filters propagated through the model

This separation ensures:
- KPI consistency
- Easier validation
- Clear ownership of business logic

---

## Downstream Consumption (Power BI)

In Power BI:

- All dimensions and facts are imported as-is
- `Dim_PeerGroup` is exposed as a slicer
- Filters propagate via  
  `Dim_PeerGroup → Bridge_Facility_PeerGroup → Dim_Facility → Facts`
- No peer logic exists in DAX

Power BI acts as a **presentation layer**, not a modeling workaround.

---

## Summary

The Analytical Data Modeling layer defines **how the organization reasons about hospital performance**.

By explicitly modeling peer groups, severity, and structural context here, the project ensures that every KPI is:

- Comparable
- Clinically grounded
- Statistically defensible
- Executive-ready
