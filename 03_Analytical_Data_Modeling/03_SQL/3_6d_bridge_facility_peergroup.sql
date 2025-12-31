--------------------------------------------------------------------------------
-- FILE: 3_6d_bridge_facility_peergroup.sql
-- LAYER: Analytical Data Model – Bridge (Factless)
--
-- WHAT:
--   Create the Bridge_Facility_PeerGroup table.
--   This factless bridge resolves the many-to-many relationship between
--   facilities and peer groups.
--
-- WHY:
--   A single facility may belong to multiple peer groups (e.g.:
--   Academic + Safety-Net, or Community + Rural).
--
--   Using a bridge table:
--     - Preserves star schema integrity
--     - Avoids duplicating facility rows
--     - Enables flexible peer-based slicing in Power BI
--
-- GRAIN:
--   One row per Facility–PeerGroup assignment.
--
-- KEYS:
--   Composite Primary Key:
--     - Facility_Key
--     - PeerGroup_Key
--
-- DEPENDENCIES:
--   - dbo.Dim_Facility
--   - dbo.Dim_PeerGroup
--
-- DOWNSTREAM USAGE:
--   - Enables Peer Group filtering across all KPI fact tables
--   - Supports many-to-many analysis without custom DAX logic
--
-- NOTES:
--   This table contains no measures.
--   It exists purely to propagate analytical context.
--------------------------------------------------------------------------------

IF OBJECT_ID('dbo.Bridge_Facility_PeerGroup', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Bridge_Facility_PeerGroup;
END;
GO

CREATE TABLE dbo.Bridge_Facility_PeerGroup
(
    Facility_Key  INT NOT NULL,
    PeerGroup_Key INT NOT NULL,
    Created_At    DATETIME2(0) NOT NULL
        CONSTRAINT DF_Bridge_Facility_PeerGroup_CreatedAt DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_Bridge_Facility_PeerGroup
        PRIMARY KEY (Facility_Key, PeerGroup_Key),

    CONSTRAINT FK_Bridge_Facility
        FOREIGN KEY (Facility_Key)
        REFERENCES dbo.Dim_Facility (Facility_Key),

    CONSTRAINT FK_Bridge_PeerGroup
        FOREIGN KEY (PeerGroup_Key)
        REFERENCES dbo.Dim_PeerGroup (PeerGroup_Key)
);

CREATE INDEX IX_Bridge_Facility_PeerGroup_PeerGroup
    ON dbo.Bridge_Facility_PeerGroup (PeerGroup_Key);
GO
