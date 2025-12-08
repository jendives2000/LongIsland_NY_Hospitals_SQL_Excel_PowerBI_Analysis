/*==========================================================
  04.1 – EXCEL VALIDATION EXPORTS
  How to use:
  - Run each query
  - Right-click in the Results grid → Save Results As... → CSV
  - Open the CSV in Excel and store it under:
      /04_Analytical_Validation/Excel_Checks/
==========================================================*/


/*--------------------------------------------------------
  04.1.1 – Monetary Check (Top 100 encounters by charges)
  WHAT:
    - Export top 100 rows with highest Total_Charges.
  WHY:
    - Verify currency cleaning:
        * No '$'
        * No commas inside numbers
        * Reasonable magnitudes (no crazy outliers).
---------------------------------------------------------*/

SELECT TOP (100)
    f.Encounter_ID,
    d.Year,
    d.Full_Date          AS Discharge_Date,
    fac.Facility_Name,
    p.Payment_Typology_Group,
    f.LOS_Sim            AS Length_of_Stay,
    f.Total_Charges,
    f.Total_Costs
FROM dbo.Fact_Encounter AS f
JOIN dbo.Dim_Date      AS d   ON f.Discharge_Date_Key = d.Date_Key
JOIN dbo.Dim_Facility  AS fac ON f.Facility_Key       = fac.Facility_Key
JOIN dbo.Dim_Payer     AS p   ON f.Payer_Key          = p.Payer_Key
ORDER BY f.Total_Charges DESC;

-- Save as: 04_1_Monetary_Top100.csv



/*--------------------------------------------------------
  04.1.2 – Category Mapping Check (Random sample)
  WHAT:
    - Export a random sample of rows focusing on standardized
      categories: admission type, disposition, race, ethnicity,
      payer group.
  WHY:
    - Visually verify that mappings look logical and consistent.
---------------------------------------------------------*/

SELECT TOP (200)
    s.Encounter_ID,
    s.Type_of_Admission,
    s.Type_of_Admission_Std,
    s.Patient_Disposition,
    s.Patient_Disposition_Grouped,
    s.Race,
    s.Race_Std,
    s.Ethnicity,
    s.Ethnicity_Std,
    s.Payment_Typology_1,
    s.Payment_Typology_Group
FROM dbo.LI_SPARCS_2015_25_Inpatient AS s
ORDER BY NEWID();   -- random sample
-- Save as: 04_1_Category_Mapping_Sample.csv



/*--------------------------------------------------------
  04.1.3 – Birth Weight Cast Check
  WHAT:
    - Export births with non-null Birth_Weight.
  WHY:
    - Confirm integer conversion is correct and values look clinical
      (e.g., no obvious unit issues).
---------------------------------------------------------*/

SELECT TOP (200)
    s.Encounter_ID,
    s.Facility_Name,
    s.Age_Group,
    s.Birth_Weight,
    s.Length_of_Stay,
    s.Total_Charges
FROM dbo.LI_SPARCS_2015_25_Inpatient AS s
WHERE s.Birth_Weight IS NOT NULL
ORDER BY NEWID();
-- Save as: 04_1_BirthWeight_Sample.csv



/*--------------------------------------------------------
  04.1.4 – ZIP Categorization Check
  WHAT:
    - Export sample rows with original 3-digit ZIP and the new
      Zip3_Category.
  WHY:
    - Validate the “In-State / Out-of-State / Unknown” logic.
---------------------------------------------------------*/

SELECT TOP (200)
    s.Encounter_ID,
    s.Zip_Code_3_digits,
    s.Zip3_Category,
    s.Hospital_County,
    s.Health_Service_Area
FROM dbo.LI_SPARCS_2015_25_Inpatient AS s
ORDER BY NEWID();
-- Save as: 04_1_Zip3_Category_Sample.csv



/*--------------------------------------------------------
  04.1.5 – Fact/Dim Integrity Check
  WHAT:
    - Random sample from the Fact table joined to key dimensions.
  WHY:
    - Validate that:
        * All foreign keys resolve
        * Facility, date, payer and admission type are consistent.
---------------------------------------------------------*/

SELECT TOP (200)
    f.Encounter_ID,
    d.Full_Date,
    d.[Year],
    fac.Facility_Name,
    p.Payment_Typology_Group,
    a.AdmissionType_Std,
    disp.Disposition_Grouped,
    f.LOS_Sim,
    f.Total_Charges,
    f.Total_Costs
FROM dbo.Fact_Encounter       AS f
JOIN dbo.Dim_Date             AS d     ON f.Discharge_Date_Key  = d.Date_Key
JOIN dbo.Dim_Facility         AS fac   ON f.Facility_Key        = fac.Facility_Key
JOIN dbo.Dim_Payer            AS p     ON f.Payer_Key           = p.Payer_Key
JOIN dbo.Dim_AdmissionType    AS a     ON f.AdmissionType_Key   = a.AdmissionType_Key
JOIN dbo.Dim_Disposition      AS disp  ON f.Disposition_Key     = disp.Disposition_Key
ORDER BY NEWID();
-- Save as: 04_1_FactDim_Integrity_Sample.csv
