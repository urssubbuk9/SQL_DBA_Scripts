SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--=============================================
--   
-- You may alter this code for your own *non-commercial* purposes. You may
-- republish altered code as long as you give due credit.
--   
-- THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
-- ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
-- TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
-- PARTICULAR PURPOSE.
--
-- =============================================
-- Description:	This script will return information related to the QUery Store settings per database
--
-- Assumptions:	The script will work on any version of the query store (SQL Server 2016 onward)
--
-- Parameters:	
--				- @dbname, NULL for all databases, allows wildcards
--
-- Remarks:
--              Values for #read_only_reasons taken from 
--              https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-database-query-store-options-transact-sql?view=sql-server-ver15
-- Log History:	
--				26/03/2020 RAG	Created
--
-- =============================================

DECLARE @dbname SYSNAME	= NULL -- 'dbname'


DECLARE @SQL	NVARCHAR(MAX)

CREATE TABLE #read_only_reasons(
readonly_reason INT
, readonly_reason_desc NVARCHAR(512)
)

INSERT INTO #read_only_reasons
VALUES(1, 'Database is in read-only mode')
		, (2, 'Database is in single-user mode')
		, (4, 'Database is in emergency mode')
		, (8, 'Database is secondary replica (applies to Always On and Azure SQL Database geo-replication). This value can be effectively observed only on readable secondary replicas')
		, (65536, 'The Query Store has reached the size limit set by the MAX_STORAGE_SIZE_MB option')
		, (131072, 'The number of different statements in Query Store has reached the internal memory limit. Consider removing queries that you do not need or upgrading to a higher service tier to enable transferring Query Store to read-write mode. Applies to: Azure SQL Database.')
		, (262144, 'Size of in-memory items waiting to be persisted on disk has reached the internal memory limit. Query Store will be in read-only mode temporarily until the in-memory items are persisted on disk. Applies to: Azure SQL Database.')
		, (524288, 'Database has reached disk size limit. Query Store is part of user database, so if there is no more available space for a database, that means that Query Store cannot grow further anymore. Applies to: Azure SQL Database. ')

CREATE TABLE #t(
    [database_name] SYSNAME
    , desired_state_desc nvarchar(60)
    , actual_state_desc nvarchar(60)
    , readonly_reason int
    , readonly_reason_desc NVARCHAR(512)
    , current_storage_size_mb bigint
    , max_storage_size_mb bigint
    , stale_query_threshold_days bigint
    , max_plans_per_query bigint
    , query_capture_mode_desc nvarchar(60)
    , size_based_cleanup_mode_desc nvarchar(60)
)

DECLARE c CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY 
FOR SELECT name 
        FROM sys.databases 
        WHERE is_query_store_on = 1
            AND name LIKE ISNULL(@dbname, name)

OPEN c
FETCH NEXT FROM c INTO @dbname
WHILE @@FETCH_STATUS = 0 BEGIN

	SET @SQL = N'USE ' + QUOTENAME(@dbname) +
	'SELECT DB_NAME()
            , desired_state_desc
            , actual_state_desc
            , o.readonly_reason
            , ISNULL(readonly_reason_desc, ''N/A'') AS readonly_reason_desc
            , current_storage_size_mb
            , max_storage_size_mb 
            , stale_query_threshold_days 
            , max_plans_per_query 
            , query_capture_mode_desc 
            , size_based_cleanup_mode_desc 	
        FROM sys.database_query_store_options AS o
        LEFT JOIN #read_only_reasons AS r
            ON o.readonly_reason = r.readonly_reason'

	INSERT INTO #t
	EXECUTE sp_executesql @stmt = @SQL

	FETCH NEXT FROM c INTO @dbname

END

CLOSE c
DEALLOCATE c

SELECT * 
FROM  #t
ORDER BY database_name

DROP TABLE #t
DROP TABLE #read_only_reasons
