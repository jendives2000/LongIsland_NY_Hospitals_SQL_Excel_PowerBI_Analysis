# 06.05 - Validation

## Purpose

Defines validation controls that certify semantic-layer outputs remain consistent with Step 05 KPI logic.

This is the trust-preservation layer between SQL truth and executive BI consumption.

---

## Validation Scope in Step 06

Step 06 validates semantic integrity, not KPI redefinition.

Key checks:

- Numerator/denominator reconciliation against Step 05
- No row loss from joins or grain changes
- Correct behavior under dimensional slicing
- DAX measure parity with SQL expectations

---

## Explainability and Risk Control

Validation protects against common interpretation risks:

- Aggregation drift from precomputed rates
- Filter-path ambiguity in visuals
- Low-volume distortion without guardrails

---

## Required Outcome

A KPI fact is Step-06-certified only when semantic outputs remain consistent with Step 05 contracts and are safe for executive interpretation.
