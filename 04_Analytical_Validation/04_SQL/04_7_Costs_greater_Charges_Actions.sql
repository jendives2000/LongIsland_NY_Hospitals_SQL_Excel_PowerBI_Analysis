-- Quantify which service lines drive these 1120 cases

SELECT ClinicalClass_Key, COUNT(*) AS CountCases
FROM dbo.Fact_Encounter
WHERE Total_Costs > Total_Charges
GROUP BY ClinicalClass_Key
ORDER BY CountCases DESC;

SELECT 
    AVG(Length_of_Stay_Int) AS AvgLOS,
    MIN(Length_of_Stay_Int) AS MinLOS,
    MAX(Length_of_Stay_Int) AS MaxLOS
FROM dbo.Fact_Encounter
WHERE Total_Costs > Total_Charges;

SELECT Payer_Key, COUNT(*) AS CountCases
FROM dbo.Fact_Encounter
WHERE Total_Costs > Total_Charges
GROUP BY Payer_Key;



/* Negative-margin encounters with payer labels */

SELECT 
    f.Encounter_ID,
    f.Length_of_Stay_Int,
    f.Total_Charges,
    f.Total_Costs,
    (f.Total_Costs - f.Total_Charges) AS Margin_Loss,   -- how much costs exceed charges

    f.ClinicalClass_Key,                                -- we’ll decode this later via Dim_ClinicalClass
    p.Payment_Typology_1,
    p.Payment_Typology_Group,
    p.Is_Unknown
FROM dbo.Fact_Encounter AS f
LEFT JOIN dbo.Dim_Payer AS p
    ON f.Payer_Key = p.Payer_Key
WHERE f.Total_Costs > f.Total_Charges
ORDER BY Margin_Loss DESC;      -- biggest negative margins first





/* Summary: which payer types drive the 1120 negative-margin cases? */

SELECT
    p.Payment_Typology_1,
    p.Payment_Typology_Group,
    COUNT(*) AS NegativeMargin_Count
FROM dbo.Fact_Encounter AS f
LEFT JOIN dbo.Dim_Payer AS p
    ON f.Payer_Key = p.Payer_Key
WHERE f.Total_Costs > f.Total_Charges
GROUP BY
    p.Payment_Typology_1,
    p.Payment_Typology_Group
ORDER BY
    NegativeMargin_Count DESC;

