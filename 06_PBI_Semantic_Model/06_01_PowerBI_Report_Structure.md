# 06_01 — Power BI Report Structure & Navigation Guide

## Purpose of This Document

This document defines the **official structure, sequencing, and interpretation rules** of the Power BI report built on top of the validated KPI layer (Step 05).

Its role is to ensure that:
- KPIs are consumed **in the correct analytical order**
- Peer-group comparisons are applied **consistently and fairly**
- Executives and analysts do **not misinterpret structural signals as performance issues**
- The report remains **maintainable, auditable, and scalable** as new data or years are added

This document is **mandatory** in enterprise BI projects and acts as the contract between:
- Data Engineering & Analytics
- BI Developers
- Executive Consumers

---

<details>
<summary><strong>📑 Table of Contents</strong></summary>

- [06\_01 — Power BI Report Structure \& Navigation Guide](#06_01--power-bi-report-structure--navigation-guide)
  - [Purpose of This Document](#purpose-of-this-document)
  - [Design Principles](#design-principles)
  - [Report Navigation Overview](#report-navigation-overview)
  - [Page 0 — Executive Orientation (Landing Page)](#page-0--executive-orientation-landing-page)
    - [Purpose](#purpose)
    - [Key Messages](#key-messages)
    - [Visual Elements](#visual-elements)
    - [Interaction Rules](#interaction-rules)
  - [Page 1 — Severity Mix Context (Baseline)](#page-1--severity-mix-context-baseline)
    - [Executive Question](#executive-question)
    - [Visuals](#visuals)
    - [Interpretation Rules](#interpretation-rules)
  - [Page 2 — Intake Pressure (Unplanned Admissions)](#page-2--intake-pressure-unplanned-admissions)
    - [Executive Question](#executive-question-1)
    - [Visuals](#visuals-1)
    - [Interpretation Rules](#interpretation-rules-1)
  - [Page 3 — Length of Stay (Throughput)](#page-3--length-of-stay-throughput)
    - [Executive Question](#executive-question-2)
    - [Visuals](#visuals-2)
    - [Interpretation Rules](#interpretation-rules-2)
  - [Page 4 — Disposition Outcomes (Exit Flow)](#page-4--disposition-outcomes-exit-flow)
    - [Executive Question](#executive-question-3)
    - [Visuals](#visuals-3)
    - [Interpretation Rules](#interpretation-rules-3)
  - [Page 5 — Mortality (Outcome Risk)](#page-5--mortality-outcome-risk)
    - [Executive Question](#executive-question-4)
    - [Visuals](#visuals-4)
    - [Interpretation Rules](#interpretation-rules-4)
  - [Page 6 — Financial Pressure (Cost \& Margin)](#page-6--financial-pressure-cost--margin)
    - [Executive Question](#executive-question-5)
    - [Visuals](#visuals-5)
    - [Interpretation Rules](#interpretation-rules-5)
  - [Page 7 — Payer Mix \& Reimbursement Risk](#page-7--payer-mix--reimbursement-risk)
    - [Executive Question](#executive-question-6)
    - [Visuals](#visuals-6)
    - [Interpretation Rules](#interpretation-rules-6)
  - [Mandatory Slicers \& Filters](#mandatory-slicers--filters)
    - [Global Slicers](#global-slicers)
    - [Locked Filters](#locked-filters)
  - [Explicit Non-Goals of the Report](#explicit-non-goals-of-the-report)
  - [Governance \& Change Control](#governance--change-control)
  - [Summary](#summary)

</details>


---
## Design Principles

The Power BI report follows four non-negotiable principles:

1. **Context before performance**  
   Severity and intake context must be reviewed before outcomes or financial KPIs.

2. **Peer-group comparison only**  
   Cross-role hospital comparisons are structurally invalid.

3. **Single-year clarity**  
   The dataset covers inpatient encounters for 2015 only.  
   Month-level variation is allowed; year-over-year interpretation is not.

4. **Guardrails over rankings**  
   KPIs are interpreted using bands, context flags, and peer medians — not league tables.

---

## Report Navigation Overview

The report is organized into **eight pages**, sequenced to mirror the real-world hospital care flow:

Severity → Intake → Throughput → Discharge → Outcomes → Financial Exposure

Each page answers **one executive question only**.

---

## Page 0 — Executive Orientation (Landing Page)

### Purpose
Prevent misinterpretation before analysis begins.

### Key Messages
- Scope: NY Inpatient SPARCS, 2015
- KPIs are **not independent**
- Peer-group filtering is mandatory
- Severity is context, not performance

### Visual Elements
- Static text tiles (no charts)
- Navigation buttons to KPI sections
- Link to the Executive “How to Read This Report” guide

### Interaction Rules
- No slicers except Year (locked to 2015)
- This page is informational only

---

## Page 1 — Severity Mix Context (Baseline)

**KPI:** 05.01 — Severity Mix Index (APR)  
**Peer Groups:**  
- Academic / Tertiary  
- Community Acute-Care  
- Rural / East-End

### Executive Question
Are downstream differences driven by patient acuity?

### Visuals
- Average Severity Mix Index by facility
- APR Severity distribution (Levels 1–4)
- Facility vs peer median indicator

### Interpretation Rules
- This page **does not indicate performance**
- Higher severity is expected for referral centers
- No ranking or conditional formatting allowed

---

## Page 2 — Intake Pressure (Unplanned Admissions)

**KPI:** 05.03 — Unplanned Admission Rate  
**Peer Groups:**  
- Academic / Tertiary  
- Large Community  
- Mid-Size Community  
- Rural / East-End  

### Executive Question
Is capacity pressure driven by unplanned intake?

### Visuals
- Unplanned Admission Rate (%)
- Planned vs Unplanned encounter counts
- Peer-group percentile band (within group only)

### Interpretation Rules
- High unplanned rate ≠ poor operations
- This page must be reviewed **before LOS or Cost**
- Specialty-dominant hospitals excluded

---

## Page 3 — Length of Stay (Throughput)

**KPI:** 05.05 — Length of Stay (LOS)  
**Peer Groups:** All (including specialty)

### Executive Question
Are patients staying longer than expected given severity and intake mix?

### Visuals
- Average LOS by facility
- LOS distribution (bucketed)
- LOS by APR Severity Level

### Interpretation Rules
- LOS without severity context is invalid
- Long-tail LOS drives cost and capacity pressure
- Flat LOS across severity levels is a warning signal

---

## Page 4 — Disposition Outcomes (Exit Flow)

**KPI:** 05.04 — Disposition Outcomes  
**Peer Groups:** All + Specialty

### Executive Question
Where do patients go after discharge?

### Visuals
- Disposition share (Home / Post-Acute / Transfer / Death)
- Facility vs peer disposition mix

### Interpretation Rules
- Higher post-acute share may reflect case mix, not inefficiency
- Transfers are expected in tertiary centers
- Disposition explains downstream cost and LOS effects

---

## Page 5 — Mortality (Outcome Risk)

**KPI:** 05.06 — Mortality Rate  
**Peer Groups:**  
- Academic / Tertiary  
- Large Community  
- Rural / East-End  
- Specialty  

**Excluded:** Mid-Size Community (low denominator risk)

### Executive Question
Do mortality patterns align with severity and hospital role?

### Visuals
- Mortality rate with encounter count
- Severity-aligned comparison
- Volume vs rate decomposition

### Interpretation Rules
- Mortality is a low-frequency metric
- Counts must always be shown alongside rates
- Small denominators trigger volatility flags

---

## Page 6 — Financial Pressure (Cost & Margin)

**KPI:** 05.07 — MCost per Encounter & Margin Pressure  
**Peer Groups:** All

### Executive Question
Is inpatient care financially sustainable?

### Visuals
- Average medical cost per encounter
- Margin pressure ratio (cost / charges)
- Facility vs peer band comparison

### Interpretation Rules
- Margin pressure is not profitability
- Must be interpreted with LOS and severity
- System-wide averages are intentionally excluded

---

## Page 7 — Payer Mix & Reimbursement Risk

**KPI:** 05.02 — Payer Mix & Reimbursement Risk  
**Peer Groups:** All (with safety-net lens)

### Executive Question
Is financial pressure structural or operational?

### Visuals
- Payer share by facility
- Negative-margin rate by payer group
- Facility vs peer payer exposure

### Interpretation Rules
- High Medicaid or self-pay share is mission-driven
- Losses may be reimbursement-driven, not operational
- Safety-net hospitals require separate interpretation

---

## Mandatory Slicers & Filters

### Global Slicers
- Facility
- Peer Group
- Discharge Month (2015 only)

### Locked Filters
- Year = 2015
- Inpatient encounters only

---

## Explicit Non-Goals of the Report

This report does **not**:
- Rank hospitals across peer groups
- Assign performance scores
- Replace clinical or operational audits
- Claim causality between KPIs

It is a **decision-support and signal-detection system**, not a judgment tool.

---

## Governance & Change Control

Any modification to:
- KPI definitions
- Peer group assignments
- Page sequencing
- Interpretation rules

Requires updates to:
- Step 05 KPI documentation
- This report structure document
- Executive interpretation guide

---

## Summary

This Power BI report is intentionally structured to:
- Enforce analytical discipline
- Prevent structural bias
- Support executive decision-making
- Remain defensible under scrutiny

Correct interpretation depends on **following the page order**.

Skipping context pages invalidates downstream conclusions.
