# Power BI Report Structure and Navigation Guide

## Purpose

Defines report-page sequencing and interpretation rules for executive KPI consumption.

This is a report-specific usage guide for the Step 06 Power BI artifact.

---

## Scope Boundary

- Step 05 defines KPI logic.
- Step 06 semantic model consumes KPI logic.
- This guide defines how report pages should be read to avoid interpretation drift.

---

## Reading Order (Explainability-First)

Review pages in this order:

1. Severity Mix (context)
2. Unplanned Intake (context)
3. Payer Mix (context)
4. Length of Stay (throughput)
5. Mortality (outcome risk)
6. Cost and Margin Pressure (financial stress)
7. Disposition (exit flow)

Context pages come first by design.

---

## Executive Page Contract

Each page should define:

- One executive question
- Core visuals (what is shown)
- Interpretation rules (what can and cannot be concluded)

Do not combine multiple unrelated questions on one page.

---

## Mandatory Slicers and Locks

Global slicers:

- Facility
- Peer Group
- Discharge Month (within available data scope)

Locked filters:

- Inpatient encounters only
- Year scope as defined by model release

---

## Interpretation Guardrails

- Do not rank hospitals across structurally different peer groups.
- Do not interpret outcomes without context KPIs.
- Show denominators with low-frequency rates.
- Use guarded measures where sample size is insufficient.

---

## Change Control

If report sequencing or interpretation rules change, update:

1. This guide
2. `06_PBI_Semantic_Model/03_PowerBI_Model/README.md`
3. Related KPI documentation in `05_KPI_Dev`
4. Validation notes in `06_PBI_Semantic_Model/05_Validation/README.md`
