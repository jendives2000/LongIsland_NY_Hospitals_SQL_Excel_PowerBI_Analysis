# KPI 05.0X - Template

## Purpose

Define one KPI module with a governed SQL contract, validation artifact, and explicit Step-07 consumption boundary.

## Required Sections

1. KPI purpose and executive question
2. Data dependencies (fact and dimensions)
3. SQL artifact path(s)
4. Governed view name(s)
5. Validation artifact path(s)
6. Step-07 consumption note
7. Known limitations and interpretation guardrails

## Minimum Contract

- Encounter-level validation output (if needed)
- Stable governed KPI view for downstream consumption
- Consistent grain declaration (for example Facility-Year)

## Step-07 Consumption Note (Template)

Step 07 should consume only governed KPI views from this module.

Validation outputs are for QA/reconciliation and should not replace governed KPI view sources in executive integration.

## Example Fill-In

- SQL artifact: `05_0x_SQL/05_0x_<KPI_Name>.sql`
- Governed view: `dbo.vw_KPI_<KPI_Name>_FacilityYear`
- Validation workbook: `05_0x_Excel/05_0x_<KPI_Name>_Validation.xlsx`
