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

-- Description:	This script will return total resources consumed per interval
--
-- Assumptions:	The script will work on any version of the query store (SQL Server 2016 onward)
--              Since the Query Store is per database, percentages of individual databases shoud be added
--
-- Parameters:	
--              @dateFrom	
--              @dateTo		
--
-- Log History:	
--				05/02/2020 RAG	Created
--
-- =============================================

-- USE [dbName]

DECLARE @dateFrom	DATETIME2 = DATEADD(HOUR, -6, GETDATE())
DECLARE @dateTo		DATETIME2 = GETDATE()

DECLARE @nprocessor INT		= (SELECT COUNT(*) FROM sys.dm_os_schedulers WHERE status = 'VISIBLE ONLINE')

IF OBJECT_ID('tempdb..#intervals') IS NOT NULL DROP TABLE #intervals

SELECT runtime_stats_interval_id
        , start_time
        , end_time
	INTO #intervals
	FROM sys.query_store_runtime_stats_interval
	WHERE start_time <= @dateTo
		AND end_time >= @dateFrom

SELECT  CONVERT(SMALLDATETIME, rsti.start_time) AS start_time
		, CONVERT(SMALLDATETIME, rsti.end_time) AS end_time
		, SUM(rst.count_executions) AS total_executions
		, CEILING((CEILING(SUM(rst.count_executions * rst.avg_cpu_time) / 1000000) * 100) 
			/ (DATEDIFF(SECOND, rsti.start_time, rsti.end_time) * @nprocessor)) AS Database_CPU_percent
		
		, CEILING(SUM(rst.count_executions * rst.avg_duration) / 1000000) AS total_duration_s
		, CEILING(SUM(rst.count_executions * rst.avg_cpu_time) / 1000000) AS total_cpu_s
		, SUM(rst.count_executions * rst.avg_logical_io_reads) AS total_reads
		, CEILING(SUM(rst.count_executions * rst.avg_logical_io_reads) / 128) AS total_reads_mb
		, SUM(rst.count_executions * rst.avg_logical_io_writes) AS total_writes
		, CEILING(SUM(rst.count_executions * rst.avg_logical_io_writes) / 128) AS total_writes_mb
	FROM sys.query_store_runtime_stats AS rst
		INNER JOIN #intervals AS rsti
			ON rsti.runtime_stats_interval_id = rst.runtime_stats_interval_id 
	GROUP BY rsti.start_time, rsti.end_time
