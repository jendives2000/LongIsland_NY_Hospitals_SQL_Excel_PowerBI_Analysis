/******************************************************************************************
 STEP 1 – GENERIC COLUMN-LEVEL DATA PROFILING SCRIPT
 -----------------------------------------------------------------------------------------
 Goal:
   - Profile all columns of a given table:
       * min / max
       * null count
       * distinct count
       * mean, standard deviation (numeric columns)
       * median (numeric columns, using PERCENTILE_CONT)
       * mode (most frequent value, any type)
       * count of "zero-like" values for numeric columns

 Usage:
   - Adjust @SchemaName and @TableName below.
   - Run the script in the context of the database that contains the table.
   - Results are returned from #ColumnProfile.

 Notes:
   - This is meant as an EXPLORATORY profiling tool, not as production code.
   - Median and mode can be heavy on very large tables; restrict to key columns if needed.
******************************************************************************************/

/* ========================================================================================
   0. CONFIGURATION – SET TARGET TABLE
   ======================================================================================== */

DECLARE @SchemaName sysname = N'dbo';             -- change if needed
DECLARE @TableName  sysname = N'LI_SPARCS_2015_25_Inpatient';    -- change to the target table name, etc.

DECLARE @FullTableName nvarchar(512) =
    QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName);

/* ========================================================================================
   1. CLEAN UP ANY PREVIOUS RUN
   ======================================================================================== */

DROP TABLE IF EXISTS #ColumnProfile;
DROP TABLE IF EXISTS #ColumnsMetadata;

/* ========================================================================================
   2. CAPTURE COLUMN METADATA FROM INFORMATION_SCHEMA
      - We use INFORMATION_SCHEMA.COLUMNS to discover all columns automatically.
   ======================================================================================== */

SELECT 
    COLUMN_NAME,
    ORDINAL_POSITION,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
INTO #ColumnsMetadata
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = @SchemaName
  AND TABLE_NAME   = @TableName
ORDER BY ORDINAL_POSITION;

-- Quick check (optional)
-- SELECT * FROM #ColumnsMetadata;

/* ========================================================================================
   3. CREATE THE PROFILE TABLE TO HOLD RESULTS
      - We keep everything in one row per column.
      - Min/max/mode stored as NVARCHAR for generic handling.
   ======================================================================================== */

CREATE TABLE #ColumnProfile
(
    column_name               sysname,
    ordinal_position          int,
    data_type                 sysname,
    character_maximum_length  int NULL,

    minimum                   nvarchar(4000) NULL,
    maximum                   nvarchar(4000) NULL,
    nulls                     int            NULL,
    distinct_count            int            NULL,

    mean                      float          NULL,
    median                    float          NULL,
    standard_deviation        float          NULL,

    mode                      nvarchar(4000) NULL,
    zero_values               int            NULL
);

-- Seed the profile table with the static metadata
INSERT INTO #ColumnProfile (column_name, ordinal_position, data_type, character_maximum_length)
SELECT COLUMN_NAME, ORDINAL_POSITION, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM #ColumnsMetadata;

/* ========================================================================================
   4. LOOP THROUGH COLUMNS AND PROFILE EACH ONE
   ======================================================================================== */

DECLARE 
    @i           int,
    @maxOrdinal  int,
    @ColumnName  sysname,
    @DataType    sysname,
    @ColQuoted   nvarchar(260),
    @sql         nvarchar(max),
    @median      float;

SELECT @i = MIN(ordinal_position), @maxOrdinal = MAX(ordinal_position)
FROM #ColumnsMetadata;

WHILE @i IS NOT NULL AND @i <= @maxOrdinal
BEGIN
    /* ----------------------------------------------------------------------
       4.1 Get current column name & data type
       ---------------------------------------------------------------------- */
    SELECT 
        @ColumnName = COLUMN_NAME,
        @DataType   = DATA_TYPE
    FROM #ColumnsMetadata
    WHERE ordinal_position = @i;

    -- Always quote the column name to avoid issues with spaces / reserved words
    SET @ColQuoted = QUOTENAME(@ColumnName);

    /* ----------------------------------------------------------------------
       4.2 BASIC METRICS FOR ALL DATA TYPES:
           - min, max, null count, distinct count
       ---------------------------------------------------------------------- */
    SET @sql = N'
        UPDATE cp
        SET 
            minimum = CAST(x.min_value AS nvarchar(4000)),
            maximum = CAST(x.max_value AS nvarchar(4000)),
            nulls   = x.null_count,
            distinct_count = x.distinct_count
        FROM #ColumnProfile AS cp
        CROSS APPLY (
            SELECT 
                MIN(' + @ColQuoted + N') AS min_value,
                MAX(' + @ColQuoted + N') AS max_value,
                SUM(CASE WHEN ' + @ColQuoted + N' IS NULL THEN 1 ELSE 0 END) AS null_count,
                COUNT(DISTINCT ' + @ColQuoted + N') AS distinct_count
            FROM ' + @FullTableName + N'
        ) AS x
        WHERE cp.ordinal_position = ' + CAST(@i AS nvarchar(10)) + N';
    ';

    EXEC sp_executesql @sql;

    /* ----------------------------------------------------------------------
       4.3 NUMERIC COLUMNS:
           - mean, standard deviation, median, zero count
           - We treat standard numeric SQL Server types as numeric.
       ---------------------------------------------------------------------- */
    IF @DataType IN ('int', 'bigint', 'float', 'real', 'decimal', 'numeric', 'money', 'smallint', 'tinyint')
    BEGIN
        /* Mean and standard deviation using float to preserve decimals */
        SET @sql = N'
            UPDATE cp
            SET 
                mean = x.avg_value,
                standard_deviation = x.std_dev
            FROM #ColumnProfile AS cp
            CROSS APPLY (
                SELECT 
                    AVG(CAST(' + @ColQuoted + N' AS float)) AS avg_value,
                    STDEV(CAST(' + @ColQuoted + N' AS float)) AS std_dev
                FROM ' + @FullTableName + N'
            ) AS x
            WHERE cp.ordinal_position = ' + CAST(@i AS nvarchar(10)) + N';
        ';

        EXEC sp_executesql @sql;

        /* Zero-like values:
           - Number of rows where the numeric value is exactly 0
        */
        SET @sql = N'
            UPDATE cp
            SET zero_values = x.zero_count
            FROM #ColumnProfile AS cp
            CROSS APPLY (
                SELECT 
                    COUNT(*) AS zero_count
                FROM ' + @FullTableName + N'
                WHERE ' + @ColQuoted + N' = 0
            ) AS x
            WHERE cp.ordinal_position = ' + CAST(@i AS nvarchar(10)) + N';
        ';

        EXEC sp_executesql @sql;

        /* Median:
           - Uses PERCENTILE_CONT(0.5) if available (SQL Server 2012+)
           - Be aware this can be heavy on very large tables.
        */
        SET @median = NULL;

        SET @sql = N'
            ;WITH values_cte AS (
                SELECT CAST(' + @ColQuoted + N' AS float) AS val
                FROM ' + @FullTableName + N'
                WHERE ' + @ColQuoted + N' IS NOT NULL
            )
            SELECT @median_out = PERCENTILE_CONT(0.5) 
                                 WITHIN GROUP (ORDER BY val) 
                                 OVER ()
            FROM values_cte;
        ';

        EXEC sp_executesql 
            @sql,
            N'@median_out float OUTPUT',
            @median_out = @median OUTPUT;

        UPDATE #ColumnProfile
        SET median = @median
        WHERE ordinal_position = @i;
    END

    /* ----------------------------------------------------------------------
       4.4 MODE (MOST FREQUENT VALUE) FOR ANY DATA TYPE
           - We convert to NVARCHAR for STRING_AGG.
           - If multiple values tie for mode, they are concatenated by comma.
       ---------------------------------------------------------------------- */
    SET @sql = N'
        UPDATE cp
        SET mode = x.mode_values
        FROM #ColumnProfile AS cp
        CROSS APPLY (
            SELECT STRING_AGG(CAST(' + @ColQuoted + N' AS nvarchar(4000)), '','')
            FROM (
                SELECT TOP (100) ' + @ColQuoted + N',
                       DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rk
                FROM ' + @FullTableName + N'
                GROUP BY ' + @ColQuoted + N'
            ) AS m
            WHERE rk = 1
        ) AS x(mode_values)
        WHERE cp.ordinal_position = ' + CAST(@i AS nvarchar(10)) + N';
    ';

    EXEC sp_executesql @sql;

    /* ----------------------------------------------------------------------
       4.5 ADVANCE TO NEXT COLUMN
       ---------------------------------------------------------------------- */
    SET @i = @i + 1;
END;

/* ========================================================================================
   5. VIEW RESULTS
   ======================================================================================== */

SELECT *
FROM #ColumnProfile
ORDER BY ordinal_position;
