# 06.01.02 — `Fact_KPI_PayerMix`

**Purpose**  
Quantifies **payer distribution and reimbursement exposure** by facility.

**Grain**  
- One row per **Facility × Discharge Year × Payment Typology Group**

**Primary Measures**
- Numerator `Payer_Encounter_Count`: Encounter count per payer group: 
  - Commercial / Medicaid / Medicare / Self-Pay
- Denominator `Total_Encounters_Facility_Year` (reconciliation-safe)
- Metric: `Payer_Encounter_Share_validation` (stored for validation, recomputed in DAX)

<details>
<summary>🖼 See the Output Screenshot</summary>

![Fact_KPI_PayerMix](./screenshots/image.png)

</details>

**Key Dimensions**
- Facility
- Date (Year)
- Payer

**Analytical Role**
- Financial exposure context
- Explains structural margin pressure

---