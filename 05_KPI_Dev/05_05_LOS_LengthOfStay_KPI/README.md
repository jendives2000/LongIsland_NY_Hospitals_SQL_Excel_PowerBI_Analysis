# KPI 05.05 - Length of Stay (LOS)

## Purpose

Measures LOS distribution and summary behavior by Facility-Year, with severity stratification for contextual interpretation.

## SQL Artifact

- [`05_05_SQL/05_05_Length_of_Stay.sql`](/05_KPI_Dev/05_05_LOS_LengthOfStay_KPI/05_05_SQL/05_05_Length_of_Stay.sql)

## Current Output State

This SQL script currently returns LOS KPI result sets and encounter-level validation output, but does not create the expected governed view.

## Expected Governed View (Step-07 dependency)

- `dbo.vw_KPI_LOS_FacilityYear` (expected by Step 07)

## Validation Artifact

- [`05_05_Excel/05_05_LOS_Bucket_APR_Sev_Validation.xlsx`](/05_KPI_Dev/05_05_LOS_LengthOfStay_KPI/05_05_Excel/05_05_LOS_Bucket_APR_Sev_Validation.xlsx)

## Step-07 Consumption Note

Step 07 references:

- `dbo.vw_KPI_LOS_FacilityYear`

Dependency gap: this view is not created in [`05_05_Length_of_Stay.sql`](/05_KPI_Dev/05_05_LOS_LengthOfStay_KPI/05_05_SQL/05_05_Length_of_Stay.sql) and must be added or sourced before Step-07 integration.

## Visual Snapshot

<details>
<summary>Show Screenshots</summary>

![Screenshot](./screenshots/image.png)
![Screenshot](./screenshots/image-1.png)
![Screenshot](./screenshots/image-2.png)
![Screenshot](./screenshots/image-3.png)
![Screenshot](./screenshots/image-4.png)
![Screenshot](./screenshots/image-5.png)
![Screenshot](./screenshots/image-6.png)
![Screenshot](./screenshots/image-7.png)
![Screenshot](./screenshots/image-8.png)

</details>

---




