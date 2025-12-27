# 06.01.01 — `Fact_KPI_SeverityMix`
- SQL File: [here](.)
  
**Purpose**  
Establishes the **clinical acuity baseline** required to interpret all downstream KPIs fairly.

**Grain**  
- One row per **Facility × Discharge Year** - 2015

**Time Dimension**
- This fact is modeled at **year grain** and relates to a tiny conformed dimension:
  - `Dim_Year` (PK: `Discharge_Year`)
- A full `Dim_Date` is intentionally not used, as no day or month granularity exists in this KPI.


**Primary Measures**
- Numerator: `Weighted_Severity_Sum`
- Denominator: `Total_Encounters`
- Metric: `Severity_Mix_Index_validation` (stored for validation, recomputed in DAX)

<details>
<summary>🖼 See the Output Screenshot</summary>

![Fact_KPI_SeverityMix](./screenshots/image.png)


</details>

**Key Dimensions**
- Facility (`Dim_Facility`)
- Year (`Dim_Year`)

**Relationship Contract**
- `Fact_KPI_SeverityMix.Facility_Key` → `Dim_Facility.Facility_Key`
- `Fact_KPI_SeverityMix.Discharge_Year` → `Dim_Year.Discharge_Year`


**Analytical Role**
- Context KPI (not performance)
- Used to explain LOS, mortality, and cost differences

---