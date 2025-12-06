# Step 02 — What We need to Clean and Why

Each of the cleaning steps below connects directly to the issues identified during profiling.  
This ensures the data is 
- medically meaningful, 
- analysis-ready, 
- and aligns with hospital reporting standards.

---

## 1️⃣ Currency Formatting → Convert to DECIMAL  
**Fields Impacted:** `Total_Charges`, `Total_Costs`  
**SQL file:** [here](./02_SQL/2_1_Currency_Formatting.sql) 

These columns included dollar signs ('$') and commas from the original CSV.  
SQL sees those as **text**, meaning:

- You cannot add, average, or compare costs  
- Any financial analysis would be incorrect

➡ Fixing this allows us to calculate **spending**, **profitability**, and **resource utilization**.

![Currency Formatting](image.png)

---

## 2️⃣ Geographic Anomalies → Standardize ZIP information  
**Field Impacted:** `Zip_Code_3_digits`  
**SQL file:** [here](./02_SQL/2_2_Standardize_ZIP_data.sql)  

ZIP codes were shortened to 3 digits and included special values like `OOS` (Out-Of-State).  
Without standardization:

- Patients could appear to live “in-state” incorrectly  
- Regional analysis could be misleading  

➡ We now have clear, actionable groups:
- **In-state**
- **Out-of-state**
- **Unknown**

Useful for:
- Hospital service area planning  
- Equity & access reporting  

![Standardize ZIP information](image-1.png)

---

## 3️⃣ Demographic Placeholders → Standardize “Unknown” categories  
**Fields Impacted:** `Race`, `Ethnicity`  
**SQL file:** [here](./02_SQL/2_3_Standardize_Unknown_cat.sql) 

Some classifications don’t reflect true demographics (e.g., “Unknown”, “Not-Spanish/Hispanic” meaning default rather than patient response).  
Without correction:

- Community health disparities become **misinterpreted**

➡ Standardizing unknown or non-response improves:
- Public health equity monitoring  
- Federal demographic reporting compliance  

![Standardize “Unknown” categories ](image-2.png)

---

## 4️⃣ Category Normalization → Cleaner clinical + operational groups  
**Fields Impacted:** `Type_of_Admission`, `Patient_Disposition`  
**SQL Sub-Steps:** [Type of Admission], [Patient Disposition]  

Original categories were too detailed or inconsistent:  
Examples: “Urgent”, “EMERGENCY”, “Elective”, “Home or Self Care”, “Skilled Nursing Home”  

➡ Grouping into clearer, industry-standard buckets supports:
- ED vs Elective performance tracking  
- Discharge planning quality measures  
- Readmission & mortality analytics  

### Types of Admissions  
![Admissions Category Normalization](image-3.png)

### Validation of Standardized Admission Categories

After grouping unplanned vs elective admissions in Step 02.5, we validated the distribution:

| Type_of_Admission_Std | Records |
|----------------------|--------:|
| Unplanned            | 250,145 |
| Elective             | 58,001  |
| Other                | 30,893  |

#### 📏 Is “Other” too large?

We measure this as:

Other % = (30,893 / (250,145 + 58,001 + 30,893)) × 100  
Other % = (30,893 / 339,039) × 100  
Other % ≈ **9.2%**

A practical rule of thumb in analytics:

> If "Other" is **more than about 10%**, it usually means our grouping is too coarse and we are hiding useful detail.

Here, **9.2% is acceptable**. It tells us that:
- Most activity is clearly classified as **Unplanned** or **Elective**
- “Other” represents a smaller set of special admission types (e.g., newborns, transfers, psych cases) that we can optionally explore later, but they do not dominate the dataset.

In the dashboarding phase (Power BI), this split will be visualized as:
- A **pie chart** showing the share of Unplanned vs Elective vs Other
- A **bar chart** showing absolute counts for each category

These checks confirm that our category normalization is **clinically reasonable** and that the “Other” bucket does **not** hide a problematic amount of information.

---

## 5️⃣ Text Overflow → VARCHAR(Max) only when needed  
**Fields Impacted:** Description fields (Diagnosis/Procedure descriptions, etc.)  
**SQL Sub-Step:** Will be applied in schema optimization  

Some text fields were set to unlimited length (`-1`), which:

- Slows down indexing and storage  
- Hurts dashboard query speed  

➡ We will trim them to realistic limits for efficiency and performance.

---

## 6️⃣ Missing Primary Key → Generate Encounter ID  
**Fields Impacted:** All rows  
**SQL Sub-Step:** 2.3  

The dataset did not include a unique encounter identifier.  
This makes it impossible to:

- Track a patient visit consistently  
- Create proper relationships for BI modeling  

➡ A surrogate key (`Encounter_ID`) enables:
- Fact/Dimension modeling
- Traceability and de-duplication

---

## 7️⃣ Payer Granularity → Group Payment Typology codes  
**Fields Impacted:** `Payment_Typology_1`  
**SQL Sub-Step:** 2.7  

There are many insurer codes with similar meaning  
(e.g., multiple variations of commercial insurance).

➡ Grouping makes financial analysis more insightful:
- Medicare vs Medicaid vs Commercial vs Self-Pay  
- Reimbursement rate & cost burden comparisons  

---

# Deliverable Result from Step 02

> **A clean, structured analytical dataset with consistent numeric types, standardized categories, and a primary key — ready for star schema modeling and BI consumption.**
