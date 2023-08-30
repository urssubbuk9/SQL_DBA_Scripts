/* ================================================================================

Title/Name: Show when DBCC CHECKDB was last run (successfully)
Last Modified: 20/06/2019 - RAG
Description: 

Notes:

Log History:
            17/10/2018  RAG - Added database info from sp_helpdb and sys.databases (Created, db_size)
            20/06/2019  RAG - Added AG state to report if they are primary / secondary or Stand Alone
================================================================================= */

SET DATEFORMAT MDY -- in case of non-default date setting

DECLARE 
       @Database sysname,
       @SQL nvarchar(1000),
       @ThresholdDays int;

SET @ThresholdDays = 4;

CREATE TABLE #Output (
       ParentObject nvarchar(200),
       Object nvarchar(200),
       Field nvarchar(200),
       Value nvarchar(200)
);

CREATE TABLE #Output2 (
       DatabaseName sysname,
       LastGoodDBCC datetime
);

CREATE TABLE #helpdb(
name	sysname, 
db_size	nvarchar(13), 
owner	sysname, 
dbid	smallint, 
created	nvarchar(11), 
status	nvarchar(600),
compatibility_level	tinyint
);

INSERT INTO #helpdb
EXECUTE sp_helpdb;

-- Calculate AG state
SELECT ag.name AS AG_name
		, agd.database_name 
		, agrs.role_desc
	INTO #AGState
	FROM sys.availability_databases_cluster AS agd
		INNER JOIN sys.availability_groups AS ag
			ON ag.group_id = agd.group_id
		INNER JOIN sys.availability_replicas AS agr
			ON agr.group_id = agd.group_id
		INNER JOIN sys.dm_hadr_availability_replica_states AS agrs
			ON agrs.group_id = agd.group_id
				AND agrs.replica_id = agr.replica_id
				AND replica_server_name = @@SERVERNAME

DECLARE cur CURSOR FORWARD_ONLY STATIC READ_ONLY 
FOR 
       SELECT name 
       FROM sys.databases
       WHERE source_database_id IS NULL
       AND name <> 'tempdb'
       AND state_desc = 'ONLINE';

OPEN cur;
FETCH NEXT FROM cur INTO @Database;

WHILE (@@FETCH_STATUS = 0)
BEGIN
       SET @SQL = 'DBCC DBINFO (''' + @Database + ''') WITH TABLERESULTS';
       INSERT INTO #Output
       EXEC(@SQL);

       INSERT INTO #Output2
       SELECT DISTINCT @Database, Value
       FROM #Output
       WHERE Field = 'dbi_dbccLastKnownGood';

       DELETE FROM #Output;

       FETCH NEXT FROM cur INTO @Database;
END

CLOSE cur;
DEALLOCATE cur;

SELECT @@SERVERNAME AS server_name,
		DatabaseName,
		d2.create_date,
		CASE WHEN ag.role_desc IS NULL THEN 'Stand Alone' ELSE 'AG - ' + ag.role_desc END AS role_desc,
		CASE WHEN d2.is_read_only = 1 THEN 'READ_ONLY' ELSE 'READ_WRITE' END AS read_only,
		d.db_size,
		CASE LastGoodDBCC WHEN '1900-01-01 00:00:00.000' THEN NULL ELSE LastGoodDBCC END AS [Last Good DBCC],
		CASE LastGoodDBCC WHEN '1900-01-01 00:00:00.000' THEN NULL ELSE DATEDIFF(day, LastGoodDBCC, GETDATE()) END AS [Days Since Last Good DBCC],
		CASE WHEN (DATEDIFF(day, LastGoodDBCC, GETDATE()) - @ThresholdDays) > 0 THEN '*** CRITICAL ***' ELSE 'GOOD' END AS [Status],
		'DBCC CHECKDB(''' + DatabaseName + ''') WITH NO_INFOMSGS, ALL_ERRORMSGS;' AS [DBCC Command]
FROM #Output2 AS o
LEFT JOIN #helpdb AS d
ON d.name = o.DatabaseName
LEFT JOIN sys.databases AS d2
ON d2.name = o.DatabaseName
LEFT JOIN #AGState AS ag
ON ag.database_name = o.DatabaseName
--WHERE (DATEDIFF(day, LastGoodDBCC, GETDATE()) - @ThresholdDays) > 0
ORDER BY LastGoodDBCC ASC, DatabaseName;

DROP TABLE #Output;
DROP TABLE #Output2;
DROP TABLE #helpdb;
DROP TABLE #AGState;
