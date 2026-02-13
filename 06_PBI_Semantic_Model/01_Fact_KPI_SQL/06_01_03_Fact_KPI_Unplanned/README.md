# KPI 06.01.03 - Fact_KPI_Unplanned

## Purpose

Creates intake-pressure semantic facts from unplanned-admission KPI outputs.

## SQL Artifact

- `06_01_03_Fact_KPI_Unplanned.sql`

## Output Table

- `dbo.Fact_KPI_Unplanned`

## Grain

- One row per Facility x Discharge Year

## Core Fields

- `Unplanned_Encounter_Count`
- `Total_Encounters`
- `Unplanned_Admission_Rate_validation` (reconciliation support)

## Key Relationships

- `Facility_Key` -> `Dim_Facility.Facility_Key`
- `Discharge_Year` -> `Dim_Year.Discharge_Year`

## Screenshot

- `screenshots/image.png`
