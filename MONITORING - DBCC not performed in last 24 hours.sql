-- ===========================================================================
-- Description:	Script to check last DBCC within a time period
-- Info: 		DBCC last check time can be changed
-- ===========================================================================
IF OBJECT_ID(N'tempdb..#DBDBCCInfo') IS NOT NULL
BEGIN
DROP TABLE #DBDBCCInfo
END
GO

IF OBJECT_ID(N'tempdb..#DBCCValue') IS NOT NULL
BEGIN
DROP TABLE #DBCCValue
END
GO

--Create temp tables to store DBCC info in
CREATE TABLE #DBDBCCInfo (
	ParentObject VARCHAR(255)
	,[Object] VARCHAR(255)
	,Field VARCHAR(255)
	,[Value] VARCHAR(255)
	)

CREATE TABLE #DBCCValue (
	DatabaseName VARCHAR(255)
	,LastDBCC DATETIME
	)

--Insert results of DBCC DBINFO into temp table, transform into simpler table with database name and datetime of last known good DBCC CheckDB
EXECUTE sp_MSforeachdb '
INSERT INTO #DBDBCCInfo EXECUTE ("DBCC DBINFO ( ""?"" ) WITH TABLERESULTS");
INSERT INTO #DBCCValue (DatabaseName, LastDBCC) (SELECT "?", [Value] FROM #DBDBCCInfo WHERE Field = "dbi_dbccLastKnownGood");
TRUNCATE TABLE #DBDBCCInfo;'

--Select all DBCC results
SELECT *
FROM #DBCCValue
-- CHANGE TIMESTAMP TO SUIT NEEDS
WHERE DATEDIFF(HOUR, LastDBCC, CURRENT_TIMESTAMP) > 216
-- EXCLUDE DBs
	AND DatabaseName <> 'tempdb'
-- EXCLUDE READ ONLY DBS WHERE DBCC INFO IS NOT UPDATED AND ALSO NEW DBs WHICH HAVE NOT BEEN CHECKED YET
	and lastDBCC <> '1900-01-01 00:00:00.000'

--Raise error if any found
IF (@@ROWCOUNT > 0)
BEGIN
	RAISERROR (
			'A DB with a DBCC check older than 7 days has been found'
			,16
			,1
			)
END
ELSE
PRINT 'All good'
