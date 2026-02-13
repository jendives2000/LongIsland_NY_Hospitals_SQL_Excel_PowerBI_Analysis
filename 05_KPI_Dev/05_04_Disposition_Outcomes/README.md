# KPI 05.04 - Disposition Outcomes

## Purpose

Measures discharge outcome distribution (home, post-acute, transfer, death, other/unknown) at Facility-Year disposition grain.

## SQL Artifact

- `05_04_SQL/05_04_Disposition_Outcomes.sql`

## Governed View

- `dbo.vw_KPI_DispositionOutcomes_FacilityYear`

## Validation Artifact

- `05_04_Excel/05_04_Disposition_Outcomes_Counts_Rates_Validation.xlsx`

## Step-07 Consumption Note

Step 07 consumes:

- `dbo.vw_KPI_DispositionOutcomes_FacilityYear`

Encounter-level exports in the SQL script are validation artifacts, not executive integration sources.

## Visual Snapshot

<details>
<summary>Show Screenshots</summary>

![Screenshot](./screenshots/image.png)
![Screenshot](./screenshots/image-1.png)
![Screenshot](./screenshots/image-2.png)
![Screenshot](./screenshots/image-3.png)

</details>

---




