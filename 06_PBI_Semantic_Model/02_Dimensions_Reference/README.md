# 06.02 - Dimensions Reference

## Purpose

Documents conformed dimensions consumed by Step 06 KPI facts and the PBIP semantic model.

Dimensions are shared governance assets used for consistent filtering, slicing, and interpretation.

---

## Explainability and Interpretation Role

Conformed dimensions protect interpretation quality by ensuring:

- One definition per business concept
- Stable filter behavior across KPI domains
- Comparable facility and peer-group analysis

---

## Dimension Scope in This Step

This folder documents usage contracts for dimensions referenced by Step 06 facts and model artifacts.

Dimensions are consumed here, not redefined.

---

## Current Dimension Documentation

- [`Dim_Year/README.md`](/06_PBI_Semantic_Model/02_Dimensions_Reference/Dim_Year/README.md)

Additional conformed dimensions are documented in model artifacts and can be expanded here as needed.

---

## Governance Rule

Any dimension-key or definition change impacting KPI interpretation requires:

1. SQL/model update
2. Validation rerun
3. README and data-dictionary update
