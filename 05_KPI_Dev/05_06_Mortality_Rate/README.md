# KPI 05.06 - Mortality Rate

## Purpose

Measures in-hospital mortality rate by Facility-Year using standardized disposition outcomes.

## SQL Artifact

- [`05_06_SQL/05_06_Mortality_Rate.sql`](/05_KPI_Dev/05_06_Mortality_Rate/05_06_SQL/05_06_Mortality_Rate.sql)

## Governed View

- `dbo.vw_KPI_Mortality_FacilityYear`

## Validation Artifact

- [`05_06_Excel/05_06_Mortality_Rate.xlsx`](/05_KPI_Dev/05_06_Mortality_Rate/05_06_Excel/05_06_Mortality_Rate.xlsx)

## Step-07 Consumption Note

Step 07 consumes:

- `dbo.vw_KPI_Mortality_FacilityYear`

Encounter-level mortality exports are retained for validation and reconciliation.

## Visual Snapshot

<details>
<summary>Show Screenshots</summary>





![Screenshot](/05_KPI_Dev/05_06_Mortality_Rate/screenshots/mort_count_rate_validation.png)

</details>

---




