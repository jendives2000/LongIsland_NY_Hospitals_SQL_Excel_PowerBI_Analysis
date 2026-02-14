# KPI 06.01.05 - Fact_KPI_LOS_Summary

## Purpose

Creates LOS summary semantic facts for throughput and capacity signals.

## SQL Artifact

- [`06_01_05_Fact_KPI_LOS_Summary.sql`](/06_PBI_Semantic_Model/01_Fact_KPI_SQL/06_01_05_Fact_KPI_LOS_Summary/06_01_05_Fact_KPI_LOS_Summary.sql)

## Output Table

- `dbo.Fact_KPI_LOS_Summary`

## Grain

- One row per Facility x Discharge Year

## Core Fields

- `Total_LOS_Days`
- `Encounter_Count`
- `Avg_LOS_validation`, `Min_LOS_validation`, `Max_LOS_validation` (reconciliation support)

## Key Relationships

- `Facility_Key` -> `Dim_Facility.Facility_Key`
- `Discharge_Year` -> `Dim_Year.Discharge_Year`

## Visual Snapshot

<details>
<summary>Show Screenshots</summary>





![Screenshot](/06_PBI_Semantic_Model/01_Fact_KPI_SQL/06_01_05_Fact_KPI_LOS_Summary/screenshots/fact_kpi_los_summary.png)

</details>

---

## Screenshot

- [`screenshots/fact_kpi_los_summary.png`](/06_PBI_Semantic_Model/01_Fact_KPI_SQL/06_01_05_Fact_KPI_LOS_Summary/screenshots/fact_kpi_los_summary.png)


