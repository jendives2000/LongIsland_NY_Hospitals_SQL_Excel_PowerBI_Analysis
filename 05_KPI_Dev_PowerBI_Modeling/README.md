# 🏥 Step 05 — Healthcare KPI Development & Power BI Modeling

With Step 04 completed, the dataset is not only clean and modeled but also
**validated for clinical and financial plausibility**.

Step 05 turns that validated data into **decision-ready healthcare KPIs** and
a **Power BI semantic model** that stakeholders can actually use.

This is where the project transitions from *"Is the data trustworthy?"* to
*"What is this hospital system doing well, and where is it at risk?"*.

---

## 🎯 Objectives

- Build reusable **SQL KPI views** on top of the star schema.
- Quantify performance across **LOS, mortality, unplanned admissions, payer mix, and margin**.
- Validate KPI logic in **Excel** before surfacing it in BI tools.
- Design a **Power BI data model** that follows healthcare best practices.
- Prepare **portfolio-ready dashboards** for executives, clinicians, and finance leaders.

---

## 🧱 Inputs & Dependencies

Step 05 relies on:

- Fact table:
  - `dbo.Fact_Encounter`
- Dimensions:
  - `dbo.Dim_Date`
  - `dbo.Dim_Facility`
  - `dbo.Dim_Payer`
  - `dbo.Dim_AdmissionType`
  - `dbo.Dim_Disposition`
  - `dbo.Dim_ClinicalClass`

Key fields used:

- Fact:
  - `Encounter_ID`
  - `Discharge_Date_Key`
  - `Facility_Key`
  - `Payer_Key`
  - `AdmissionType_Key`
  - `Disposition_Key`
  - `ClinicalClass_Key`
  - `Length_of_Stay_Int`
  - `Total_Charges`
  - `Total_Costs`
- Dim_Date:
  - `Date_Key`, `Year`, `Month`, `Quarter`
- Dim_Facility:
  - `Facility_Key`, `Facility_Name`
- Dim_Payer:
  - `Payer_Key`, `Payment_Typology_1`, `Payment_Typology_Group`
- Dim_AdmissionType:
  - `AdmissionType_Key`, `AdmissionType_Std`
- Dim_Disposition:
  - `Disposition_Key`, `Disposition_Grouped`
- Dim_ClinicalClass:
  - `ClinicalClass_Key`
  - `APR_Severity_Code`, `APR_Severity_Description`
  - `APR_Risk_Of_Mortality_Desc`
  - `APR_DRG_Code`, `APR_DRG_Description`

> Note: All KPIs are defined against the **validated, anomaly-aware data**
> produced in Step 04 (outlier handling, costs>charges analysis, etc.).

---
## Optimized sequence for clean SQL logic, analytical coherence, and scalable KPI development

Before building the full KPI catalog, it's critical to establish an order that supports:

- Correct SQL dependencies (views that rely on earlier logic)
- Analytical clarity (KPIs interpreted in the right clinical/financial context)
- Reusable modeling patterns (severity mix, payer mix, and disposition will be reused in later KPIs)

The list of the KPI Catalog below is the optimized build sequence.

---
## 📊 KPI Catalog

This step implements the *business* KPIs introduced in Step 04:

### 1. Severity Mix Index (APR)

**Question:**  
Are we treating more complex, high-acuity cases?

Using APR Severity of Illness:

- `APR_Severity_Code` 1–4
- Higher score = more complex patients

“APR Severity of Illness” is a score from 1 to 4 that says how sick/complex the patient is:
- 1 = Minor
- 2 = Moderate
- 3 = Major
- 4 = Extreme

It helps: 
- Explaining why performance metrics differ between hospitals (“Our patients are sicker”)
- Justifying higher funding or specialist staffing
- Benchmarking hospitals on a risk-adjusted basis (fair comparison)

We compute:

- Encounter counts by severity
- Average severity score per facility-year
- Severity mix index used later for case-mix comparisons:  
  This is basically a summary score of how severe the patient population is, per hospital-year.

**View:**

- `dbo.vw_KPI_SeverityMix_FacilityYear`

---







---

### 2. Payer Mix & Reimbursement Risk

**Question:**  
Where is financial exposure concentrated? Are costs and volumes dominated by
certain payer groups?

“Payer mix” = how many patients belong to each payer category, such as:
- Medicare
- Medicaid
- Commercial insurance
- Self-pay / uninsured
“Payment_Typology_Group” is your cleaned/standardized payer category.

We want to know:
- Which payer groups bring the most volume
- Which bring the most cost
- Which bring losses

This helps:
- Answer if this payer makes a policy change, how much risk are we exposed to?
- Identify concentration risk (too dependent on a low-paying payer)
- Decide which service lines to promote or adjust
- Prioritize negotiations with key payers
- Prepare for policy or reimbursement changes

We summarize:

- **Encounters and share by `Payment_Typology_Group`:** Shows volume exposure.  
- **Avg cost and charges per payer group:** Shows whether some payers get more expensive patients or lower prices.  
- **Negative-margin rate per payer group:** Highlights payers that are financially unsustainable.  

**View:**

- `dbo.vw_KPI_PayerMix_FacilityYear`

---






---

### 3. Unplanned Admission Rate

**Question:**  
What proportion of encounters arrive via **unplanned routes** (Emergency / Urgent),
straining ED and inpatient capacity?

**Logic (assumption for this project):**

- `AdmissionType_Std` ∈ (`'Emergency'`, `'Urgent'`) → **Unplanned**
- All other standardized admission types → **Planned**

They are not scheduled elective surgeries or planned procedures.

These patients:
- Are harder to predict
- Can overload ED and inpatient beds
- Are often sicker or more unstable

**View:**

- `dbo.vw_KPI_UnplannedAdmissions_FacilityYear`

---

### 4. Disposition Outcomes

**Question:**  
Do patients safely return to the community? How many die in hospital or move to
institutional care?

“Disposition” = where the patient goes at discharge.

**Logic (example groups):**

- `Disposition_Grouped` = `Home / Self Care`
- `Disposition_Grouped` = `Skilled Nursing / Rehab`
- `Disposition_Grouped` = `Died` / `Expired`
- Other groupings (transfers, AMA, etc.)

“AMA” = Left Against Medical Advice (patient leaves early, against doctor recommendation)

**View:**

- `dbo.vw_KPI_Disposition_FacilityYear`

---

### 5. Length of Stay (LOS) KPIs

**Question:**  
How long do patients stay, and how does this vary by facility and case-mix?

“Length of Stay” = number of days a patient spends in the hospital from admission to discharge.

“Case-mix” = the mix of patient types, especially how sick/complex they are (for example: more mild vs more severe cases).
If a hospital treats many severe cases, its LOS will naturally be higher.

- **Avg LOS** - How long patients stay on average
- **Min / Max LOS** - How spread out LOS is (short vs long stays)
- **LOS distribution** by facility and year
- **LOS by APR Severity of Illness** - How LOS differs by APR Severity of Illness (a 1–4 scale where 4 = very sick)

**Views:**

- `dbo.vw_KPI_LOS_FacilityYear`
- `dbo.vw_KPI_LOS_BySeverity`

---

### 6. Mortality Rate

**Question:**  
What is in-hospital mortality, and how does it vary by facility and case-mix?

“In-hospital mortality” = patients who died during their hospital stay.  
We want to know:
- Overall rate per hospital and year
- How that rate changes when we separate by severity (to be fair)

Assumptions:

- `Disposition_Grouped` includes a value such as `'Died'` or `'Expired'`
  for in-hospital deaths.

**Views:**

- `dbo.vw_KPI_Mortality_FacilityYear`
- (Optional) `dbo.vw_KPI_Mortality_BySeverity`

---

### 7. Cost per Encounter & Margin Pressure

**Question:**  
Which facilities / payers deliver **high-value** vs **high-cost** care?

We want to see:
- How much it costs to treat patients
- How much the hospital charges
- Whether some combinations of facility/payer are losing money

“Margin pressure” = stress on profit margins, especially when cost > revenue.

We compute:

- Avg `Total_Costs` and `Total_Charges`:
  - `Total_Costs`: internal estimate of how much resources were used (staff, drugs, equipment).
  - `Total_Charges`: what the hospital billed.
- Cost-per-encounter: 
  - Simply: Total_Costs / Encounter_Count.
  - Shows how much the hospital spends per patient on average.
- Cost-to-charge ratio:
  - Total_Costs / Total_Charges.
    - If ≈ 0.5 → charges are double the costs.
    - If ≈ 1 → charges ≈ costs.
  - Used to understand pricing vs cost structure.
- Negative-margin rate (where `Total_Costs > Total_Charges`)

**Views:**

- `dbo.vw_KPI_CostPerCase_FacilityYear`
- `dbo.vw_KPI_NegativeMargin_Profile`

---

## 🗂 Folder Structure for Step 05

Recommended structure in the repo:

```text
/05_Healthcare_KPIs_and_PowerBI
│
├─ /05_SQL
│   ├─ 05_1_KPI_LOS_Views.sql
│   ├─ 05_2_KPI_Unplanned_Admissions.sql
│   ├─ 05_3_KPI_Disposition.sql
│   ├─ 05_4_KPI_SeverityMix.sql
│   ├─ 05_5_KPI_Mortality.sql
│   ├─ 05_6_KPI_CostPerCase_Margin.sql
│   └─ 05_7_KPI_PayerMix.sql
│
├─ /05_Excel
│   ├─ 05_1_LOS_KPI_Validation.xlsx
│   ├─ 05_2_UnplannedAdmissions_Validation.xlsx
│   ├─ 05_3_Mortality_Validation.xlsx
│   ├─ 05_4_CostPerCase_Validation.xlsx
│   └─ 05_5_PayerMix_Validation.xlsx
│
└─ /05_PowerBI
    └─ LI_Hospitals_KPIs.pbix
