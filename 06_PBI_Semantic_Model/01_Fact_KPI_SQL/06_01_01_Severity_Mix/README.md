# KPI 06.01.01 - Fact_KPI_SeverityMix

## Purpose

Creates the severity context fact used to anchor downstream KPI interpretation.

## SQL Artifact

- [`06_01_01_Fact_KPI_SeverityMix.sql`](/06_PBI_Semantic_Model/01_Fact_KPI_SQL/06_01_01_Severity_Mix/06_01_01_Fact_KPI_SeverityMix.sql)

## Output Table

- `dbo.Fact_KPI_SeverityMix`

## Grain

- One row per Facility x Discharge Year

## Core Fields

- `Weighted_Severity_Sum`
- `Total_Encounters`
- `Severity_Mix_Index_validation` (reconciliation support)

## Key Relationships

- `Facility_Key` -> `Dim_Facility.Facility_Key`
- `Discharge_Year` -> `Dim_Year.Discharge_Year`

## Visual Snapshot

<details>
<summary>Show Screenshots</summary>





![Screenshot](./screenshots/fact_kpi_severity_mix_preview.png)

</details>

---

## Screenshot

- [`screenshots/fact_kpi_severity_mix_preview.png`](/06_PBI_Semantic_Model/01_Fact_KPI_SQL/06_01_01_Severity_Mix/screenshots/fact_kpi_severity_mix_preview.png)


