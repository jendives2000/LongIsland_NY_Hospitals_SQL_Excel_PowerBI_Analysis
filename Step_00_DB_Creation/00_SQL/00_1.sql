create database LI_NYHealth;
GO

----------------

EXEC sp_rename 
    'dbo.HID_SPARCS_De-Identified__2015_20251030',
    'LI_SPARCS_2015_25_Inpatient';
