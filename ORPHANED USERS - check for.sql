IF OBJECT_ID('tempdb..#orphans') IS NOT NULL
	DROP TABLE #orphans;

CREATE TABLE #orphans
(
	DBName sysname,
	UserName sysname,
	Type char(1),
	TypeDesc varchar(30),
	OwnedSchemas int
);

INSERT #orphans
EXEC sp_MSforeachdb N'
	USE [?];
	SELECT DB_NAME() AS DBName,
		name AS UserName,
		type,
		type_desc AS Type,
		sch.schemas
	FROM sys.database_principals dp
		CROSS APPLY (SELECT COUNT(*) AS schemas FROM sys.schemas s WHERE s.principal_id = dp.principal_id) sch
	WHERE
		(
			type IN (''U'', ''G'')
			OR (type = ''S'' AND LEN(sid) <= 16)
		)
		AND name NOT IN (''guest'', ''sys'', ''INFORMATION_SCHEMA'')
		AND NOT EXISTS (SELECT * FROM sys.server_principals sp WHERE sp.sid = dp.sid);
';

SELECT DBName,
	UserName,
	TypeDesc,
	CASE
		WHEN UserName = 'dbo'
			THEN '-- Check database owner'
		WHEN type = 'S' AND EXISTS (SELECT * FROM sys.server_principals WHERE name = o.UserName)
			THEN 'USE [' + o.DBName + ']; ALTER USER [' + o.UserName + '] WITH LOGIN = [' + o.UserName + '];'
		WHEN type IN ('U', 'G')
			THEN 'CREATE LOGIN [' + o.UserName + '] FROM WINDOWS'
		ELSE '-- Login [' + o.UserName + '] not found'
	END AS FixOrphan,
	CASE
		WHEN UserName = 'dbo'
			THEN '-- Check database owner'
		WHEN OwnedSchemas > 0
			THEN '-- Check owned schemas in [' + o.DBName + '] for [' + o.UserName + ']'
		ELSE 'USE [' + o.DBName + ']; DROP USER [' + o.UserName + ']'
	END AS DropUser
FROM #orphans o
ORDER BY DBName, UserName;

/*
-- Fix schemas owned by orphaned users

SELECT *,
	USER_NAME(principal_id) AS owner,
	CASE WHEN schema_id <> principal_id AND principal_id > 1 THEN 'ALTER AUTHORIZATION ON schema::' + name + ' TO [' + name + ']' END AS fix_owner,
	CASE WHEN obj.objects = 0 AND schema_id > 4 AND schema_id < 16384 THEN 'DROP SCHEMA [' + name + ']' END AS drop_schema
FROM sys.schemas s
	CROSS APPLY (SELECT COUNT(*) AS objects FROM sys.objects o WHERE o.schema_id = s.schema_id) obj
ORDER BY schema_id

*/

/*
--Find all objects owned by a schema

SELECT 'DROP TABLE [TheSchema].'+ name, *
FROM sys.objects
WHERE SCHEMA_ID = SCHEMA_ID('TheSchema')
