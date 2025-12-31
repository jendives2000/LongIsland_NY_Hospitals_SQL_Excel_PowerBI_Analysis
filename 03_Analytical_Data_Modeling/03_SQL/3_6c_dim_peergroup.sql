--------------------------------------------------------------------------------
-- FILE: 3_6c_dim_peergroup_and_3_6d_bridge_facility_peergroup.sql
-- LAYER: Analytical Data Model – Dimension + Bridge
--
-- WHAT:
--   1) Create dbo.Dim_PeerGroup
--   2) Create dbo.Bridge_Facility_PeerGroup (factless bridge)
--   3) Seed Dim_PeerGroup with PG-A..PG-E (idempotent)
--   4) Populate bridge by mapping Dim_Facility.Facility_Name -> PeerGroup
--
-- WHY:
--   Peer groups are semantic context for benchmarking and must not be embedded
--   ad hoc in KPI SQL or DAX. A bridge supports facilities belonging to
--   peer-group lenses without duplicating fact rows.
--------------------------------------------------------------------------------

/*===========================================================================
  STEP 01 - CREATE: dbo.Dim_PeerGroup
===========================================================================*/
IF OBJECT_ID('dbo.Dim_PeerGroup', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_PeerGroup
    (
        PeerGroup_Key          INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Dim_PeerGroup PRIMARY KEY,
        PeerGroup_Name         VARCHAR(100) NOT NULL,
        PeerGroup_Description  VARCHAR(255) NULL,
        PeerGroup_Sort         INT NULL,
        Is_Active              BIT NOT NULL CONSTRAINT DF_Dim_PeerGroup_IsActive DEFAULT (1),
        Created_At             DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_PeerGroup_CreatedAt DEFAULT (SYSDATETIME())
    );

    -- WHAT: prevent duplicate peer group names
    -- WHY: name is used as a stable natural key for idempotent seeding
    CREATE UNIQUE INDEX UX_Dim_PeerGroup_PeerGroup_Name
        ON dbo.Dim_PeerGroup (PeerGroup_Name);
END;
GO
