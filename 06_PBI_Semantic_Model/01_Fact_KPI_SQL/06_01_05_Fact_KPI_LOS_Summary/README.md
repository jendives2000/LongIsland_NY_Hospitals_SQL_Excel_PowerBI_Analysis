# 06.01.05 — `Fact_KPI_LOS_Summary`

**Purpose**  
Summarizes **inpatient length-of-stay behavior** at an executive level.

**Grain**  
- One row per **Facility × Discharge Year**

**Primary Measures**
- Numerator: `Total_LOS_Days`
- Denominator: `Encounter_Count`
- Metrics: `Avg_LOS_validation`, `Min_LOS_validation`, `Max_LOS_validation` (stored for validation, recomputed in DAX)


<details>
<summary>🖼 See the Output Screenshot</summary>

![Fact_KPI_LOS_Summary](./screenshots/image.png)


</details>

**Key Dimensions**
- Facility
- Date (Year)

**Analytical Role**
- Throughput and capacity signal
- Requires severity and intake context

---