# Dim_Year

## Purpose

Provides the conformed year dimension used by Facility-Year KPI facts.

This keeps time slicing explicit without forcing daily-grain date joins.

## Primary Key

- `Discharge_Year` (INT)

## Typical Attributes

- `Discharge_Year`
- `Year_Label`
- `Year_Sort`

## Used By

- `Fact_KPI_SeverityMix`
- `Fact_KPI_PayerMix`
- `Fact_KPI_Unplanned`
- `Fact_KPI_Disposition`
- `Fact_KPI_LOS_Summary`
- `Fact_KPI_Mortality`
- `Fact_KPI_FinancialPressure`

## Rule

Use `Dim_Year` for year-grain facts.

Use `Dim_Date` only when a fact has true date-grain keys.
