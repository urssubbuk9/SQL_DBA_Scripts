SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--=============================================
-- You may alter this code for your own *non-commercial* purposes. You may
-- republish altered code as long as you give due credit.
--   
-- THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
-- ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
-- TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
-- PARTICULAR PURPOSE.
--
-- =============================================
-- Description:	This script will return information collected by the query store
--
-- Assumptions:	The script will work on any version of the query store (SQL Server 2016 onward)
--
-- Parameters:	
--				- @dateFro
--				- @dateTo		
--				- @topNrows	
--				- @OrderBy	
--
-- Log History:	
--				11/11/2019 RAG	Created
--				18/11/2019 RAG	Added average wait times per wait type
--
-- =============================================


DECLARE @dateFrom	DATE = DATEADD(DAY, -8, GETDATE())
DECLARE @dateTo		DATE = NULL
DECLARE @topNrows	INT
DECLARE @OrderBy	SYSNAME = 'total_cpu'

SET @dateTo		= ISNULL(@dateTo, DATEADD(DAY, 7, @dateFrom)) -- one week
SET @topNrows	= ISNULL(@topNrows, 10)
SET @OrderBy	= ISNULL(@OrderBy, 'total_cpu')

IF @OrderBy NOT IN ('total_executions', 'avg_duration', 'avg_cpu_time', 'avg_logical_io_reads', 'avg_logical_io_writes'
					, 'total_duration', 'total_cpu', 'total_reads', 'total_writes') BEGIN 
	RAISERROR ('The possible values for @OrderBy are the following:
- total_executions
- avg_duration
- avg_cpu_time
- avg_logical_io_reads
- avg_logical_io_writes
- total_duration
- total_cpu			
- total_reads		
- total_writes		

Please Choose on of them and run it again', 16, 0) WITH NOWAIT;
	GOTO OnError
END

IF OBJECT_ID('tempdb..#intervals') IS NOT NULL DROP TABLE #intervals

SELECT runtime_stats_interval_id
		 , start_time
		 , end_time
	INTO #intervals
	FROM sys.query_store_runtime_stats_interval
	WHERE start_time <= @dateTo
		AND end_time >= @dateFrom

-- Capture Wait Stats if 2017 or higher
IF OBJECT_ID('tempdb..#waits') IS NOT NULL DROP TABLE #waits

DECLARE @sql NVARCHAR(MAX) = 'SELECT w.plan_id
		, AVG(w.avg_query_wait_time_ms) AS avg_query_wait_time_ms
		, SUM(w.total_query_wait_time_ms) AS total_query_wait_time_ms
		, STRING_AGG(w.wait_category_desc + '' (Total: '' + CONVERT(VARCHAR(30), w.total_query_wait_time_ms) + '' - Avg: '' + CONVERT(VARCHAR(30), w.avg_query_wait_time_ms) + '')'', '', '') 
			WITHIN GROUP(ORDER BY w.total_query_wait_time_ms DESC) AS total_query_wait_time_ms_breakdown
	FROM (
		SELECT w.plan_id
			   , w.wait_category_desc
			   , AVG(avg_query_wait_time_ms) AS avg_query_wait_time_ms
			   , SUM(w.total_query_wait_time_ms) AS total_query_wait_time_ms
			FROM sys.query_store_wait_stats AS w
				INNER JOIN #intervals AS rsti
					ON rsti.runtime_stats_interval_id = w.runtime_stats_interval_id
			GROUP BY w.plan_id
					 , w.wait_category_desc
	) AS w
	GROUP BY w.plan_id;'

CREATE TABLE #waits(
	[plan_id]								BIGINT	NULL
	, [avg_query_wait_time_ms]				FLOAT	NULL
	, [total_query_wait_time_ms]			BIGINT	NULL
	, [total_query_wait_time_ms_breakdown]	NVARCHAR(4000) NULL)

IF CAST(CAST(SERVERPROPERTY('ProductVersion') AS varchar(4)) as decimal(4,2)) > 13 BEGIN
	INSERT INTO #waits (plan_id, [avg_query_wait_time_ms], total_query_wait_time_ms, total_query_wait_time_ms_breakdown)
	EXECUTE sp_executesql @sqlstmt = @sql
END
ELSE BEGIN
	INSERT INTO #waits (plan_id, [avg_query_wait_time_ms], total_query_wait_time_ms, total_query_wait_time_ms_breakdown)
	VALUES (0, 0, 0, N'n/a')
END

-- Get the intervals for the period defined.
IF OBJECT_ID('tempdb..#totals') IS NOT NULL DROP TABLE #totals

SELECT SUM(rst.count_executions) AS total_executions
		, SUM(rst.count_executions * rst.avg_duration) AS total_duration
		, SUM(rst.count_executions * rst.avg_cpu_time) AS total_cpu
		, SUM(rst.count_executions * rst.avg_logical_io_reads) AS total_reads
		, SUM(rst.count_executions * rst.avg_logical_io_writes) AS total_writes
INTO #totals
		--, 		* 
-- SELECT *
	FROM sys.query_store_runtime_stats AS rst
	INNER JOIN #intervals AS rsti
		ON rsti.runtime_stats_interval_id = rst.runtime_stats_interval_id 

SELECT rst.start_time
		, rst.end_time
		, rst.query_id
		, rst.n_plans
		--, qp.query_id
		--, rst.plan_id
		, ISNULL(OBJECT_SCHEMA_NAME(q.object_id) + '.' + OBJECT_NAME(q.object_id), '-') AS object_name
		, rst.total_executions
	
	-- totals
		, CONVERT(BIGINT, rst.total_duration / 1000)	AS total_duration_ms
		, CONVERT(BIGINT, rst.total_cpu / 1000)		AS total_cpu_ms
		, rst.total_reads
		, rst.total_writes
		--, ISNULL(w.total_query_wait_time_ms					, 0) AS total_query_wait_time_ms			 
		--, ISNULL(w.total_query_wait_time_ms_breakdown		, 0) AS total_query_wait_time_ms_breakdown

	-- averages
		, ISNULL(CONVERT(BIGINT, rst.avg_duration / 1000	), 0) AS avg_duration_ms
		, ISNULL(CONVERT(BIGINT, rst.avg_cpu_time / 1000	), 0) AS avg_cpu_time_ms
		, ISNULL(CONVERT(BIGINT, rst.avg_logical_io_reads	), 0) AS avg_logical_io_reads
		, ISNULL(CONVERT(BIGINT, rst.avg_logical_io_writes	), 0) AS avg_logical_io_writes
		--, ISNULL(CONVERT(BIGINT, w.avg_query_wait_time_ms	), 0) AS avg_query_wait_time_ms

	-- percentages 
		, ISNULL(CONVERT(DECIMAL(5,2), rst.total_duration	* 100 / NULLIF(t.total_duration, 0)		), 0)	AS percentge_duration
		, ISNULL(CONVERT(DECIMAL(5,2), rst.total_cpu		* 100 / NULLIF(t.total_cpu, 0)			), 0)	AS percentge_cpu
		, ISNULL(CONVERT(DECIMAL(5,2), rst.total_reads		* 100 / NULLIF(t.total_reads, 0)		), 0)	AS percentge_reads
		, ISNULL(CONVERT(DECIMAL(5,2), rst.total_writes		* 100 / NULLIF(t.total_writes, 0)		), 0)	AS percentge_writes
		--, ISNULL(CONVERT(DECIMAL(5,2), w.total_query_wait_time_ms * 100. / NULLIF(tw.total_query_wait_time_ms, 0)), 0) AS percentage_query_wait_time_ms

	-- Query Text and Plan 
		--, qt.query_sql_text
		--, qp.query_plan
		, ISNULL(TRY_CONVERT(XML, '<!--' + REPLACE(qt.query_sql_text, '--', '/* this line was commented out */') + '-->'), qt.query_sql_text) AS query_sql_text
		--, ISNULL(TRY_CONVERT(XML, qp.query_plan), qp.query_plan) AS query_plan

	FROM (
		SELECT TOP (@topNrows) 
				CONVERT(DATETIME2(0), MIN(rsti.start_time)) AS start_time
				, CONVERT(DATETIME2(0), MAX(rsti.end_time)) AS end_time
				, qp.query_id
				, COUNT(DISTINCT rst.plan_id) n_plans
				, SUM(rst.count_executions) AS total_executions
				-- averages
				, AVG(rst.avg_duration) AS avg_duration		   
				, AVG(rst.avg_cpu_time) AS avg_cpu_time		   
				, AVG(rst.avg_logical_io_reads) AS avg_logical_io_reads 
				, AVG(rst.avg_logical_io_writes) AS avg_logical_io_writes
				-- totals
				, SUM(rst.count_executions * rst.avg_duration)			AS total_duration
				, SUM(rst.count_executions * rst.avg_cpu_time)			AS total_cpu
				, SUM(rst.count_executions * rst.avg_logical_io_reads)	AS total_reads
				, SUM(rst.count_executions * rst.avg_logical_io_writes) AS total_writes
				--, 		* 
		-- SELECT *
			FROM sys.query_store_runtime_stats AS rst
			INNER JOIN sys.query_store_plan AS qp
				ON qp.plan_id = rst.plan_id 
			INNER JOIN #intervals AS rsti
				ON rsti.runtime_stats_interval_id = rst.runtime_stats_interval_id 
			GROUP BY qp.query_id -- rst.plan_id
			ORDER BY  CASE WHEN @OrderBy = 'total_executions'		THEN SUM(rst.count_executions) ELSE NULL END DESC
					, CASE WHEN @OrderBy = 'avg_duration'			THEN AVG(rst.avg_duration) ELSE NULL END DESC
					, CASE WHEN @OrderBy = 'avg_cpu_time'			THEN AVG(rst.avg_cpu_time) ELSE NULL END DESC
					, CASE WHEN @OrderBy = 'avg_logical_io_reads'	THEN AVG(rst.avg_logical_io_reads) ELSE NULL END DESC
					, CASE WHEN @OrderBy = 'avg_logical_io_writes'	THEN AVG(rst.avg_logical_io_writes) ELSE NULL END DESC
					, CASE WHEN @OrderBy = 'total_duration'			THEN SUM(rst.count_executions * rst.avg_duration) ELSE NULL END DESC
					, CASE WHEN @OrderBy = 'total_cpu'				THEN SUM(rst.count_executions * rst.avg_cpu_time) ELSE NULL END DESC
					, CASE WHEN @OrderBy = 'total_reads'			THEN SUM(rst.count_executions * rst.avg_logical_io_reads) ELSE NULL END DESC
					, CASE WHEN @OrderBy = 'total_writes'			THEN SUM(rst.count_executions * rst.avg_logical_io_writes) ELSE NULL END DESC
		) AS rst
		--INNER JOIN sys.query_store_plan AS qp
		--	ON qp.plan_id = rst.plan_id
		INNER JOIN sys.query_store_query AS q
			ON q.query_id = rst.query_id
		INNER JOIN sys.query_store_query_text AS qt
			ON qt.query_text_id = q.query_text_id 
		--LEFT JOIN #waits AS w
		--	ON w.plan_id = qp.plan_id
		OUTER APPLY #totals AS t
		OUTER APPLY (SELECT SUM(total_query_wait_time_ms) AS total_query_wait_time_ms FROM #waits) AS tw
	--WHERE rst.plan_id = 1999
	ORDER BY CASE WHEN @OrderBy = 'total_executions'		THEN rst.total_executions ELSE NULL END DESC
			, CASE WHEN @OrderBy = 'avg_duration'			THEN rst.avg_duration ELSE NULL END DESC
			, CASE WHEN @OrderBy = 'avg_cpu_time'			THEN rst.avg_cpu_time ELSE NULL END DESC
			, CASE WHEN @OrderBy = 'avg_logical_io_reads'	THEN rst.avg_logical_io_reads ELSE NULL END DESC
			, CASE WHEN @OrderBy = 'avg_logical_io_writes'	THEN rst.avg_logical_io_writes ELSE NULL END DESC
			, CASE WHEN @OrderBy = 'total_duration'			THEN rst.total_duration	ELSE NULL END DESC
			, CASE WHEN @OrderBy = 'total_cpu'				THEN rst.total_cpu ELSE NULL END DESC
			, CASE WHEN @OrderBy = 'total_reads'			THEN rst.total_reads ELSE NULL END DESC
			, CASE WHEN @OrderBy = 'total_writes'			THEN rst.total_writes ELSE NULL END DESC

OnError:
GO
