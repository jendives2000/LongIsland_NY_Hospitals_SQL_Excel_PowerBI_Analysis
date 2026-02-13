# 06.01 - Fact KPI SQL

## Purpose

This folder materializes governed semantic facts from Step 05 KPI outputs.

Each fact table is designed for executive-safe BI use with:

- Explicit grain
- Additive components for reliable aggregation
- Stable conformed keys
- Validation columns for traceability

---

## Upstream Contract

Step 05 remains the KPI logic authority.

Step 06 scripts reshape approved outputs into semantic-model facts without redefining business formulas.

---

## Fact Inventory

- `06_01_01_Severity_Mix/06_01_01_Fact_KPI_SeverityMix.sql` -> `dbo.Fact_KPI_SeverityMix`
- `06_01_02_Fact_KPI_PayerMix/06_01_02_Fact_KPI_PayerMix.sql` -> `dbo.Fact_KPI_PayerMix`
- `06_01_03_Fact_KPI_Unplanned/06_01_03_Fact_KPI_Unplanned.sql` -> `dbo.Fact_KPI_Unplanned`
- `06_01_04_Fact_KPI_Disposition/06_01_04_Fact_KPI_Disposition.sql` -> `dbo.Fact_KPI_Disposition`
- `06_01_05_Fact_KPI_LOS_Summary/06_01_05_Fact_KPI_LOS_Summary.sql` -> `dbo.Fact_KPI_LOS_Summary`
- `06_01_06_Fact_KPI_Mortality/06_01_06_Fact_KPI_Mortality.sql` -> `dbo.Fact_KPI_Mortality`
- `06_01_07_Fact_KPI_FinancialPressure/06_01_07_Fact_KPI_FinancialPressure.sql` -> `dbo.Fact_KPI_FinancialPressure`

---

## Time Grain Rule

The core KPI facts use year grain (`Discharge_Year`) with `Dim_Year`.

`Dim_Date` is used only where true date-grain fact behavior is required.

---

## Consumption Rule

Validation columns (for example `*_validation`) are transparency artifacts.

Executive rates and ratios should be computed in DAX from additive totals.
