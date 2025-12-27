# Dim_Year

## Purpose
Provides a **conformed time dimension** for KPI facts modeled at
**Facility × Discharge Year** grain.

Used when day or month granularity is not present or required.

## Primary Key
- `Discharge_Year` (INT, natural key)

## Attributes
- `Discharge_Year` — calendar year
- `Year_Label` — display label (e.g. "2015")
- `Year_Sort` — numeric sort key

## Used By
- `Fact_KPI_SeverityMix`
- `Fact_KPI_Unplanned`
- `Fact_KPI_LOS_Summary`
- `Fact_KPI_Mortality`
- `Fact_KPI_FinancialPressure`
- `Fact_KPI_PayerMix`
- `Fact_KPI_Disposition`

## Notes
- This dimension intentionally replaces `Dim_Date` for **year-grain KPI facts**
- `Dim_Date` is used only when facts contain a true `Date_Key`
