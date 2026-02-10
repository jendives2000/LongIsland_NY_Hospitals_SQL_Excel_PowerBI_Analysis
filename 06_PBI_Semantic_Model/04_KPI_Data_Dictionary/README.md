# KPI Data Dictionary

## Semantic Model Metadata & Business Rule Documentation

---

## Purpose

The KPI Data Dictionary surfaces **complete, searchable metadata** for the analytical semantic model, enabling users, analysts, and stakeholders to quickly locate and understand every measure, column, table, and relationship embedded in the Power BI model.

Rather than maintaining separate documentation artifacts, the data dictionary is **generated live from the semantic model** using DAX metadata functions, ensuring consistency between model structure and documentation. This eliminates documentation drift and creates a single source of truth for all KPI definitions and business rules.

---

## Architecture

The data dictionary is built in three layers:

### Layer 1: Metadata Extraction (Hidden Calculated Tables)

Four metadata calculated tables extract structural information directly from the Power BI semantic model using DAX `INFO.VIEW()` functions:

| Table Name                | DAX Source              | Purpose                                          |
| ----------------------- | ----------------------- | ------------------------------------------------ |
| `_Meta_Measures`        | `INFO.VIEW.MEASURES()`   | Captures all measures with expressions and metadata |
| `_Meta_Tables`          | `INFO.VIEW.TABLES()`     | Extracts table names, row counts, and properties |
| `_Meta_Columns`         | `INFO.VIEW.COLUMNS()`    | Details columns, data types, and relationships |
| `_Meta_Relationships`   | `INFO.VIEW.RELATIONSHIPS()` | Documents all model relationships and cardinalities |

These tables remain **hidden from users** and serve as the operational foundation for the unified dictionary.

### Layer 2: Unified Dictionary (Calculated Table)

The `_DataDictionary` calculated table **unions all four metadata sources** into a single, flat structure with standardized fields:

```
_DataDictionary = 
  UNION(
    SELECT-statement over _Meta_Measures,
    SELECT-statement over _Meta_Columns,
    SELECT-statement over _Meta_Tables,
    SELECT-statement over _Meta_Relationships
  )
```

**Standardized Fields:**
- `Type` — Object type (Measure, Column, Table, Relationship)
- `Name` — Object name for search and filtering
- `Description` — Business rule, definition, or context
- `Location` — Parent table or dimension for hierarchy
- `Expression` — DAX formula or data type specification
- `DataType` — Field type (decimal, text, integer, etc.)
- `DisplayFolder` — Organizational folder in model

**Filtering Logic:**
- Hidden objects automatically excluded
- `_Meta_*` tables themselves excluded from visibility
- Only "production" objects surfaced to end users

### Layer 3: Report Interface (User-Facing)

A dedicated Power BI report page surfaces the unified dictionary with:

- **Slicers** by object `Type` (Measure, Column, Table, Relationship)
- **Search box** filterable by `Name` for rapid location
- **Detail view** showing all metadata fields including full DAX expressions
- **Linked navigation** to related measures, columns, and business context

---

## Key Features

### Live Synchronization

The data dictionary updates automatically whenever the semantic model structure changes. No manual refresh or external maintenance required.

### KPI Definition Clarity

Every measure includes:
- Complete DAX formula
- Business rule rationale
- Clinical/operational context
- Diagnostic interpretation guidance

### Relationship Transparency

All model relationships are documented with:
- Source and target tables
- Cardinality (1:1, 1:*, *:*)
- Filter flow direction
- Known relationship assumptions

### Standardized Metadata

Consistent naming, description, and documentation conventions across all KPI domains ensure rapid onboarding and reduce interpretation risk.

---

## How to Use

### Finding a Specific KPI or Metric

1. Open the **Data Dictionary** report page
2. Use the `Type` slicer to filter by **Measure** (if searching for a KPI)
3. Type the metric name in the **Name** search box
4. Review the `Description` field for business definition and context
5. Examine the `Expression` field to understand the DAX calculation logic

### Understanding Relationships

1. Filter by `Type` = **Relationship**
2. Identify source and target tables
3. Note cardinality and filter direction
4. Cross-reference with the semantic model diagram for visual confirmation

### Exploring Columns by Table

1. Filter by `Type` = **Column**
2. Use `Location` field to organize by parent table
3. Review `DataType` for storage and calculation implications
4. Check `Description` for domain and business rules (e.g., currency codes, categorical mappings)

---

## Design Principles

**Completeness**  
All model objects are documented; no ad-hoc or undocumented measures.

**Consistency**  
Standardized structure and naming across all KPI domains reduces cognitive load.

**Auditability**  
Every calculation and relationship is traceable to its DAX source, supporting governance and reproducibility.

**Maintainability**  
Metadata is generated, not hand-curated, eliminating drift between model and documentation.

---

## Relationship to Other Components

- **06_PBI_Semantic_Model/01_Fact_KPI_SQL/** — Source SQL logic underlying each measure
- **06_PBI_Semantic_Model/02_Dimensions_Reference/** — Dimension table documentation
- **06_PBI_Semantic_Model/03_PowerBI_Model/** — Semantic model structure and relationships
- **05_KPI_Dev/** — KPI-level business logic and validation

---

## Technical Notes

**DAX Version Requirement**  
`INFO.VIEW()` functions require Power BI Desktop or Power BI Premium with support for dynamic metadata discovery (available in recent versions).

**Refresh Behavior**  
The `_DataDictionary` table refreshes with each semantic model deployment. No independent refresh schedule required.

**Performance**  
Metadata tables are calculated and materialized on model load; filtering and searching against the report page is performant.

---
