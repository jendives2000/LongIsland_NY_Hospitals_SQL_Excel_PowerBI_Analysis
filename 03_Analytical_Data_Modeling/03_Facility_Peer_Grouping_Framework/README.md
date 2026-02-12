# 03 - Facility Peer Grouping Framework

## Purpose

This framework defines and governs facility peer-group assignments used for fair hospital comparison across KPI domains.

Peer grouping is structural model context, not KPI math. It is implemented in SQL so the same comparison logic is reused consistently across validation, semantic modeling, and reporting.

---

## Scope

This framework:

- Defines canonical peer groups (`PG-A` through `PG-E`)
- Seeds `Dim_PeerGroup`
- Populates `Bridge_Facility_PeerGroup`
- Enforces deterministic matching through canonical facility names

This framework does not:

- Calculate KPI values
- Modify KPI fact logic
- Use fuzzy or heuristic matching

---

## SQL Artifacts

- `seed_dim_peergroup_and_bridge.sql`
- `../03_SQL/3_6c_dim_peergroup.sql`
- `../03_SQL/3_6d_bridge_facility_peergroup.sql`

---

## Data Model Objects

### 1) `dbo.Dim_PeerGroup`

- Grain: one row per peer group
- Key: `PeerGroup_Key`
- Role: canonical benchmark lens

### 2) `dbo.Bridge_Facility_PeerGroup`

- Grain: one row per facility-peer assignment
- Composite key: (`Facility_Key`, `PeerGroup_Key`)
- Role: factless bridge enabling peer-group filter propagation

The bridge is retained to keep the model extensible if multi-group assignments are needed in the future.

---

## Canonical Peer Groups

- `PG-A Academic / Tertiary`
- `PG-B Large Community`
- `PG-C Mid-Size Community`
- `PG-D Rural / East-End`
- `PG-E Specialty-Dominant`

Definitions and descriptions are seeded directly in `seed_dim_peergroup_and_bridge.sql`.

---

## Assignment Method

Facility mappings are resolved by exact join on:

- `Dim_Facility.Facility_Name`

Why exact matching is enforced:

- Prevents silent misclassification
- Surfaces naming quality issues early
- Preserves auditable and deterministic behavior

If a name mismatch exists, no bridge row is created by design.

---

## Required QA Checks

After seeding:

- All expected peer groups exist in `Dim_PeerGroup`
- All mapped facilities resolve to `Dim_Facility`
- Bridge rows contain valid foreign keys only

The seed script includes QA queries for unresolved names and final assignment review.

---

## KPI Interpretation Guidance

Peer grouping provides comparison context. It does not replace clinical judgment.

Use peer groups to reduce structural bias when interpreting:

- Severity-driven outcomes
- Throughput and LOS patterns
- Payer and financial pressure profiles
- Disposition and mortality differences

---

## Downstream Usage

In the semantic layer, peer context is consumed through model relationships rather than custom KPI rewrites.

See also:

- `../README.md`
- `../../06_PBI_Semantic_Model/README.md`

---

## Known Limitations

- Peer grouping does not remove all case-mix heterogeneity
- Small facilities may still show volatility on low denominators
- Group definitions may require periodic governance refresh

---

## Folder Contents

```text
03_Facility_Peer_Grouping_Framework/
|-- README.md
|-- seed_dim_peergroup_and_bridge.sql
|-- image.png
`-- image-1.png
```
