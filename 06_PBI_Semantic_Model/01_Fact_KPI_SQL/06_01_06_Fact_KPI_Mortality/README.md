# 06.01.06 — `Fact_KPI_Mortality`

**Purpose**  
Measures **in-hospital mortality exposure**.

**Grain**  
- One row per **Facility × Discharge Year**

**Primary Measures**
- Numerator: `Death_Count`
- Denominator: `Total_Encounters`
- Metric: `Mortality_Rate_validation` (stored for validation, recomputed in DAX)

<details>
<summary>🖼 See the Output Screenshot</summary>

![Fact_KPI_Mortality](./screenshots/image.png)


</details>

**Key Dimensions**
- Facility
- Date (Year)

**Analytical Role**
- Outcome risk KPI
- Always interpreted with Severity Mix

---