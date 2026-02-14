# 06.03 - Power BI Model

## Purpose

Contains the production Power BI Project (`.pbip`) implementing the Step 06 semantic layer.

This is the executive consumption model where governed KPI facts, conformed dimensions, and certified measures are assembled.

---

## Portfolio Relevance

This folder demonstrates senior BI delivery capability:

- Version-controlled PBIP/TMDL model engineering
- Governed measure architecture
- Explainability-safe report design
- Recruiter- and executive-readable artifact structure

---

## Core Artifacts

- [`PBI_Project/PowerBI_project.pbip`](/06_PBI_Semantic_Model/03_PowerBI_Model/PBI_Project/PowerBI_project.pbip)
- [`PBI_Project/PowerBI_project.SemanticModel/definition/*.tmdl`](/06_PBI_Semantic_Model/03_PowerBI_Model/PBI_Project/PowerBI_project.SemanticModel/definition/)
- `PBI_Project/PowerBI_project.Report/definition/*`
- [`PowerBI_Report_Structure.md`](/06_PBI_Semantic_Model/03_PowerBI_Model/PowerBI_Report_Structure.md)
- [`screenshots/image.png`](/06_PBI_Semantic_Model/03_PowerBI_Model/screenshots/image.png) (model/report preview)

---

## Report Structure Guide

Use [`PowerBI_Report_Structure.md`](/06_PBI_Semantic_Model/03_PowerBI_Model/PowerBI_Report_Structure.md) for report page sequencing, interpretation rules, and mandatory slicer behavior.

That guide is report-specific. This README remains the folder-level contract.

---

## Modeling Rules

- Facts are filtered by conformed dimensions.
- Measures compute rates from additive columns.
- KPI logic is consumed from Step 05, not recreated in visuals.
- Guardrails are retained for low-volume interpretation safety.

---

## Governance Note

Semantic model changes should be treated as production contract changes and require synchronized documentation updates in:

- [`04_KPI_Data_Dictionary/README.md`](/06_PBI_Semantic_Model/04_KPI_Data_Dictionary/README.md)
- [`05_Validation/README.md`](/06_PBI_Semantic_Model/05_Validation/README.md)

