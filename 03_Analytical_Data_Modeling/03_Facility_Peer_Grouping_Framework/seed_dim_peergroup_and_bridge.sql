

/*===========================================================================
  STEP 03 - SEED: dbo.Dim_PeerGroup (KPI context lens)
===========================================================================*/
MERGE dbo.Dim_PeerGroup AS tgt
USING
(
    VALUES
      ('PG-A Academic / Tertiary',
       'Teaching / academic tertiary referral centers with advanced subspecialty services and higher acuity by design.',
       1),

      ('PG-B Large Community',
       'Full-service community acute-care hospitals with ED/ICU/surgery and broad inpatient services, without primary tertiary referral responsibility.',
       2),

      ('PG-C Mid-Size Community',
       'Mid-size / suburban community hospitals with lower acuity, narrower specialty depth, and limited tertiary exposure.',
       3),

      ('PG-D Rural / East-End',
       'Low-volume rural / small community hospitals serving geographically isolated populations with limited specialty services.',
       4),

      ('PG-E Specialty-Dominant',
       'Hospitals structurally shaped by a dominant specialty focus (e.g., cardiac, rehab/neuro), skewing LOS/cost/disposition/outcomes vs general acute peers.',
       5)
) AS src (PeerGroup_Name, PeerGroup_Description, PeerGroup_Sort)
ON (tgt.PeerGroup_Name = src.PeerGroup_Name)
WHEN MATCHED THEN
    UPDATE SET
        tgt.PeerGroup_Description = src.PeerGroup_Description,
        tgt.PeerGroup_Sort        = src.PeerGroup_Sort,
        tgt.Is_Active             = 1
WHEN NOT MATCHED THEN
    INSERT (PeerGroup_Name, PeerGroup_Description, PeerGroup_Sort, Is_Active)
    VALUES (src.PeerGroup_Name, src.PeerGroup_Description, src.PeerGroup_Sort, 1)
WHEN NOT MATCHED BY SOURCE THEN
    UPDATE SET tgt.Is_Active = 0;
GO


/*===========================================================================
  STEP 04 - POPULATE: dbo.Bridge_Facility_PeerGroup
  KPI OUTPUT / METRIC:
    - Facility-to-PeerGroup assignment count (rows inserted/merged)
===========================================================================*/
;WITH PeerGroup_Map AS
(
    -- WHAT: canonical mapping based on README hospital / peer-group table
    -- WHY: centralizes peer context; avoids embedding logic in KPI SQL / DAX
    SELECT *
    FROM (VALUES
        ('North Shore University Hospital', 'PG-A Academic / Tertiary'),
        ('University Hospital', 'PG-A Academic / Tertiary'),
        ('Winthrop-University Hospital', 'PG-A Academic / Tertiary'),
        ('Nassau University Medical Center', 'PG-A Academic / Tertiary'),  -- README notes safety-net label; still PG-A group

        ('Good Samaritan Hospital Medical Center', 'PG-B Large Community'),
        ('Huntington Hospital', 'PG-B Large Community'),
        ('Southside Hospital', 'PG-B Large Community'),
        ('South Nassau Communities Hospital', 'PG-B Large Community'),
        ('St Catherine of Siena Hospital', 'PG-B Large Community'),
        ('Mercy Medical Center', 'PG-B Large Community'),
        ('St. Joseph Hospital', 'PG-B Large Community'),
        ('Brookhaven Memorial Hospital Medical Center Inc', 'PG-B Large Community'),

        ('Glen Cove Hospital', 'PG-C Mid-Size Community'),
        ('Plainview Hospital', 'PG-C Mid-Size Community'),
        ('Syosset Hospital', 'PG-C Mid-Size Community'),
        ('Franklin Hospital', 'PG-C Mid-Size Community'),
        ('John T Mather Memorial Hospital of Port Jefferson New York Inc', 'PG-C Mid-Size Community'),
        ('Long Island Jewish Valley Stream', 'PG-C Mid-Size Community'),

        ('Eastern Long Island Hospital', 'PG-D Rural / East-End'),
        ('Peconic Bay Medical Center', 'PG-D Rural / East-End'),
        ('Southampton Hospital', 'PG-D Rural / East-End'),

        ('St Francis Hospital', 'PG-E Specialty-Dominant'),
        ('St Charles Hospital', 'PG-E Specialty-Dominant')
    ) AS v(Facility_Name, PeerGroup_Name)
),
Resolved_Keys AS
(
    SELECT
        f.Facility_Key,
        pg.PeerGroup_Key
    FROM PeerGroup_Map AS m
    INNER JOIN dbo.Dim_Facility  AS f
        ON f.Facility_Name = m.Facility_Name
    INNER JOIN dbo.Dim_PeerGroup AS pg
        ON pg.PeerGroup_Name = m.PeerGroup_Name
)
MERGE dbo.Bridge_Facility_PeerGroup AS tgt
USING Resolved_Keys AS src
    ON  tgt.Facility_Key  = src.Facility_Key
    AND tgt.PeerGroup_Key = src.PeerGroup_Key
WHEN NOT MATCHED THEN
    INSERT (Facility_Key, PeerGroup_Key)
    VALUES (src.Facility_Key, src.PeerGroup_Key)
-- Optional: if you want the bridge to exactly match the mapping list,
-- uncomment the next clause to remove stale assignments.
-- WHEN NOT MATCHED BY SOURCE THEN
--     DELETE
;
GO

/*===========================================================================
  STEP 05 - QA CHECKS (optional)
===========================================================================*/
-- WHAT: ensure all mapped facilities were found in Dim_Facility by name
-- WHY: catches naming mismatches early (dash vs hyphen, Inc vs Inc., etc.)

SELECT m.Facility_Name
FROM (VALUES 
('North Shore University Hospital', 'PG-A Academic / Tertiary'),
        ('University Hospital', 'PG-A Academic / Tertiary'),
        ('Winthrop-University Hospital', 'PG-A Academic / Tertiary'),
        ('Nassau University Medical Center', 'PG-A Academic / Tertiary'),  -- README notes safety-net label; still PG-A group

        ('Good Samaritan Hospital Medical Center', 'PG-B Large Community'),
        ('Huntington Hospital', 'PG-B Large Community'),
        ('Southside Hospital', 'PG-B Large Community'),
        ('South Nassau Communities Hospital', 'PG-B Large Community'),
        ('St Catherine of Siena Hospital', 'PG-B Large Community'),
        ('Mercy Medical Center', 'PG-B Large Community'),
        ('St. Joseph Hospital', 'PG-B Large Community'),
        ('Brookhaven Memorial Hospital Medical Center Inc', 'PG-B Large Community'),

        ('Glen Cove Hospital', 'PG-C Mid-Size Community'),
        ('Plainview Hospital', 'PG-C Mid-Size Community'),
        ('Syosset Hospital', 'PG-C Mid-Size Community'),
        ('Franklin Hospital', 'PG-C Mid-Size Community'),
        ('John T Mather Memorial Hospital of Port Jefferson New York Inc', 'PG-C Mid-Size Community'),
        ('Long Island Jewish Valley Stream', 'PG-C Mid-Size Community'),

        ('Eastern Long Island Hospital', 'PG-D Rural / East-End'),
        ('Peconic Bay Medical Center', 'PG-D Rural / East-End'),
        ('Southampton Hospital', 'PG-D Rural / East-End'),

        ('St Francis Hospital', 'PG-E Specialty-Dominant'),
        ('St Charles Hospital', 'PG-E Specialty-Dominant')
    )
AS m(Facility_Name, PeerGroup_Name)
LEFT JOIN dbo.Dim_Facility f ON f.Facility_Name = m.Facility_Name
WHERE f.Facility_Key IS NULL;

-- Human-readable view: This is the query you’ll actually use to verify correctness.
SELECT
    f.Facility_Name,
    pg.PeerGroup_Name,
    pg.PeerGroup_Sort
FROM dbo.Bridge_Facility_PeerGroup b
INNER JOIN dbo.Dim_Facility f
    ON f.Facility_Key = b.Facility_Key
INNER JOIN dbo.Dim_PeerGroup pg
    ON pg.PeerGroup_Key = b.PeerGroup_Key
ORDER BY
    pg.PeerGroup_Sort,
    f.Facility_Name;

-- View the raw bridge table
SELECT
    Facility_Key,
    PeerGroup_Key,
    Created_At
FROM dbo.Bridge_Facility_PeerGroup
ORDER BY Facility_Key, PeerGroup_Key;


-- Optional: count facilities per peer group
SELECT
    pg.PeerGroup_Name,
    COUNT(DISTINCT b.Facility_Key) AS Facility_Count
FROM dbo.Dim_PeerGroup pg
LEFT JOIN dbo.Bridge_Facility_PeerGroup b
    ON b.PeerGroup_Key = pg.PeerGroup_Key
GROUP BY
    pg.PeerGroup_Name,
    pg.PeerGroup_Sort
ORDER BY
    pg.PeerGroup_Sort;

