# Facility Peer Grouping Framework

## What This Is

This document defines the **facility peer grouping framework** used across the project to ensure that hospital benchmarking, KPI interpretation, and executive reporting are **clinically fair, statistically meaningful, and industry-aligned**.

Peer groups are a core part of the analytical data model and directly influence how KPIs such as Length of Stay, Mortality, Cost, and Payer Mix are interpreted.

---

## Why Peer Grouping Is Required

In healthcare analytics, comparing hospitals without adjusting for **role, acuity, and service mix** leads to false conclusions.

Industry best practices (CMS, AHRQ, Vizient, HFMA) consistently show that performance metrics are structurally driven by:

* Teaching vs non-teaching mission
* Tertiary referral responsibilities
* Case mix severity
* Specialty concentration (cardiac, rehab, neuro)
* Rural vs urban operating constraints
* Safety-net obligations

This framework ensures that:

* High-acuity hospitals are not penalized
* Small hospitals are not distorted by volatility
* Specialty hospitals are not diluted into general peers
* Executives can trust KPI signals

---

## Design Principles

The peer groups defined here follow five strict principles:

1. **Role over ownership**
   Health system branding is irrelevant for benchmarking. Hospital function is what matters.

2. **KPI-specific applicability**
   Not every peer group is valid for every KPI.

3. **Clinical plausibility**
   Groupings reflect real referral patterns and care pathways.

4. **Statistical stability**
   Groups avoid low-denominator volatility where possible.

5. **Executive defensibility**
   Every grouping decision can be explained in one sentence to leadership.

---

## Peer Group Definitions

<details>
<summary> See Hospital / Peer-Group Table</summary>

| Hospital | Peer Group | Rationale (Summary) |
|--------|------------|---------------------|
| **North Shore University Hospital** | PG-A Academic / Tertiary | Teaching hospital, regional tertiary referral center, high-acuity case mix |
| **University Hospital (Stony Brook University Hospital)** | PG-A Academic / Tertiary | Academic medical center with advanced subspecialty services |
| **Winthrop-University Hospital (NYU Langone Hospital – Long Island)** | PG-A Academic / Tertiary | Academic affiliate, tertiary referrals, complex inpatient mix |
| **Nassau University Medical Center** | PG-A Academic / Tertiary (Safety-Net) | Public teaching hospital with safety-net mission and high acuity |
| **Good Samaritan Hospital Medical Center** | PG-B Large Community | High-volume community hospital with broad acute-care services |
| **Huntington Hospital** | PG-B Large Community | Full-service community hospital with ICU and surgical depth |
| **Southside Hospital** | PG-B Large Community | Large community hospital serving dense catchment area |
| **South Nassau Communities Hospital** | PG-B Large Community | High-volume acute-care community hospital |
| **St Catherine of Siena Hospital** | PG-B Large Community | Broad inpatient services, moderate–high acuity |
| **Mercy Medical Center** | PG-B Large Community | Large community hospital with diverse service mix |
| **St. Joseph Hospital** | PG-B Large Community | Full-service community acute-care hospital |
| **Brookhaven Memorial Hospital Medical Center Inc** | PG-B Large Community | High-volume community hospital, non-tertiary role |
| **Glen Cove Hospital** | PG-C Mid-Size Community | Lower acuity, limited specialty depth |
| **Plainview Hospital** | PG-C Mid-Size Community | Suburban community hospital with narrower service mix |
| **Syosset Hospital** | PG-C Mid-Size Community | Mid-size hospital with limited tertiary exposure |
| **Franklin Hospital** | PG-C Mid-Size Community | Community-focused hospital with moderate inpatient volume |
| **John T Mather Memorial Hospital of Port Jefferson NY Inc** | PG-C Mid-Size Community | Community hospital with regional, non-tertiary role |
| **Long Island Jewish Valley Stream** | PG-C Mid-Size Community | Community hospital, limited subspecialty concentration |
| **Eastern Long Island Hospital** | PG-D Rural / East-End | Small hospital serving geographically isolated population |
| **Peconic Bay Medical Center** | PG-D Rural / East-End | Low-volume East-End hospital with high transfer-out rate |
| **Southampton Hospital** | PG-D Rural / East-End | Rural/East-End hospital with seasonal variability |
| **St Francis Hospital** | PG-E Specialty-Dominant | Cardiac specialty focus drives LOS, cost, and outcomes |
| **St Charles Hospital** | PG-E Specialty-Dominant | Rehabilitation / neuro specialty concentration |


</details>

### PG-A — Academic / Tertiary Referral Centers

**Definition**
Hospitals with teaching missions, high acuity, complex case mix, and regional referral responsibilities.

**Structural characteristics**

* Teaching programs / academic affiliation
* Advanced subspecialty services
* Higher severity and mortality by design
* Higher cost structure

**Hospitals included**

* North Shore University Hospital
* University Hospital (Stony Brook University Hospital)
* Winthrop-University Hospital (NYU Langone Hospital – Long Island)
* Nassau University Medical Center

---

### PG-B — Large Community Acute-Care Hospitals

**Definition**
Full-service community hospitals with ED, ICU, surgery, and broad inpatient services, but without primary tertiary referral responsibility.

**Structural characteristics**

* High volume
* Moderate to high acuity
* Broad service mix
* Community-driven referral patterns

**Hospitals included**

* Good Samaritan Hospital Medical Center
* Huntington Hospital
* Southside Hospital
* South Nassau Communities Hospital
* St Catherine of Siena Hospital
* Mercy Medical Center
* St. Joseph Hospital
* Brookhaven Memorial Hospital Medical Center Inc

---

### PG-C — Mid-Size / Suburban Community Hospitals

**Definition**
Community hospitals with lower acuity, narrower specialty depth, and limited tertiary exposure.

**Structural characteristics**

* Lower severity mix
* Fewer transfers-in
* Cost and LOS profiles distinct from large centers

**Hospitals included**

* Glen Cove Hospital
* Plainview Hospital
* Syosset Hospital
* Franklin Hospital
* John T Mather Memorial Hospital of Port Jefferson New York Inc
* Long Island Jewish Valley Stream

---

### PG-D — Rural / Small Community / East-End Hospitals

**Definition**
Low-volume hospitals serving geographically isolated populations with limited specialty services.

**Structural characteristics**

* Small denominators
* Seasonal variability
* Higher transfer-out rates
* Limited ICU and subspecialty depth

**Hospitals included**

* Eastern Long Island Hospital
* Peconic Bay Medical Center
* Southampton Hospital

---

### PG-E — Specialty-Dominant Hospitals

**Definition**
Hospitals whose performance metrics are structurally shaped by a dominant specialty focus.

**Structural characteristics**

* Non-representative LOS and cost profiles
* Skewed disposition patterns
* Inappropriate comparison to general acute hospitals

**Hospitals included**

* St Francis Hospital (cardiac-dominant)
* St Charles Hospital (rehabilitation / neuro-dominant)

---

## KPI-to-Peer-Group Applicability

Not all peer groups are valid for all KPIs. The table below defines which peer groups are used for each KPI.

| KPI | PG-A Academic / Tertiary | PG-B Large Community | PG-C Mid-Size Community | PG-D Rural / East-End | PG-E Specialty-Dominant |
|-----|--------------------------|----------------------|-------------------------|-----------------------|------------------------|
| **KPI 01 – Length of Stay** | ✓ | ✓ | ✓ | ✓ | ✓ |
| **KPI 02 – Unplanned Admission Proxy** | ✓ | ✓ | ✓ | ✓ | — |
| **KPI 03 – Severity Mix Index** | ✓ | ✓* | ✓* | ✓ | — |
| **KPI 04 – Payer Mix** | ✓ | ✓ | ✓ | ✓ | — |
| **KPI 05 – Disposition Outcomes** | ✓ | ✓ | ✓ | ✓ | ✓ |
| **KPI 06 – Mortality** | ✓ | ✓ | — | ✓ | ✓ |
| **KPI 07 – Cost per Encounter** | ✓ | ✓ | ✓ | ✓ | ✓ |

**Notes:**  
- ✓* = PG-B and PG-C are interpreted as a combined *Community Hospital* comparator set for Severity Mix.  
- “—” indicates the peer group is intentionally excluded to avoid distortion or statistical instability.


---

## Downstream Usage

This peer grouping framework is used in:

* Step 05 KPI development
* Power BI slicers and filters
* Executive dashboards and benchmarking views
* Interpretive annotations and tooltips

Peer group logic is **never embedded ad hoc** in KPI SQL. It is treated as a **semantic modeling layer**.

---

## Known Limitations

* Peer groups do not eliminate the need for clinical judgment
* Small hospitals may still exhibit volatility on rare events
* Specialty overlap may evolve over time

These limitations are acknowledged explicitly to prevent misuse of metrics.

---

## Summary

This framework ensures that all hospital performance metrics in this project are:

* Fair
* Comparable
* Clinically grounded
* Executive-ready

It is a foundational component of the analytical data model, not a visualization convenience.

---