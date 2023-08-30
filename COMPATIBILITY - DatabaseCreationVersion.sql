CREATE TABLE #DBs (
         Id int identity(1,1) primary key clustered,
         ParentObject varchar(255),
         Object varchar(255),
         Field varchar(255),
         Value varchar(255),
         dbID int
)

SET NOCOUNT ON
Insert Into #DBs (ParentObject, Object, Field, Value)
Exec sp_msforeachdb N'DBCC DBInfo(''?'') With TableResults, NO_INFOMSGS';

DELETE FROM #DBs WHERE Field NOT IN('dbi_createVersion','dbi_dbname');

ALTER TABLE #DBs ADD dbName sysname NULL;

--UPDATE u
--SET  dbName = (
--      SELECT TOP 1 CAST(Value as sysname) as dbName
--      FROM #DBs as s
--      WHERE s.Field = 'dbi_dbname'
--      AND   s.Id <= u.Id
--      ORDER BY Id DESC
--      )
--FROM #DBs as u;


	UPDATE x
	SET
	dbName = (SELECT TOP (1) CAST(Value as sysname) FROM #DBs d WHERE Field = 'dbi_dbname' AND d.Id > x.Id ORDER BY d.Id ASC)
	FROM #DBs x WHERE x.Field <> 'dbi_dbname'


SET NOCOUNT OFF

SELECT @@servername as ServerName
   ,a.Name
	,CAST(CASE
		WHEN a.compatibility_level = 65 THEN 'SQL 6.5'
		WHEN a.compatibility_level = 70 THEN 'SQL 7'
		WHEN a.compatibility_level = 80 THEN 'SQL 2000'
		WHEN a.compatibility_level = 90 THEN 'SQL 2005'
		WHEN a.compatibility_level = 100 THEN 'SQL 2008/2008R2'
		WHEN a.compatibility_level = 110 THEN 'SQL 2012'
		WHEN a.compatibility_level = 120 THEN 'SQL 2014'
		WHEN a.compatibility_level = 130 THEN 'SQL 2016'
		WHEN a.compatibility_level = 140 THEN 'SQL 2017'
		ELSE 'Unknown' END as varchar(30)) as compatibility_level
   ,cast(CASE 
		WHEN b.Value BETWEEN 515 AND 538 THEN 'SQL 7'
		WHEN b.Value BETWEEN 539 AND 610 THEN 'SQL 2000'
		WHEN b.Value BETWEEN 611 AND 654 THEN 'SQL 2005'
		WHEN b.Value BETWEEN 655 AND 660 THEN 'SQL 2008'
		WHEN b.Value BETWEEN 661 AND 705 THEN 'SQL 2008R2'
		WHEN b.Value BETWEEN 706 AND 781 THEN 'SQL 2012'
		WHEN b.Value BETWEEN 782 AND 782 THEN 'SQL 2014'
		WHEN b.Value BETWEEN 836 AND 852 THEN 'SQL 2016'
		WHEN b.Value BETWEEN 862 AND 869 THEN 'SQL 2017'
		WHEN b.Value > 869 THEN 'SQL New'
		ELSE 'pre SQL 7'
		END 	
		as varchar(30)) as OriginalDatabaseVersion
FROM (SELECT name, compatibility_level from sys.databases) as a
      LEFT OUTER JOIN
      (
      SELECT dbName, Value
      FROM #DBs
      WHERE Field = 'dbi_createVersion'
      ) as b
         ON a.Name = b.dbName;
            
DROP TABLE #DBs;
