/* Author: Unknown
 Use to query the SQL Server plan cache for queries and execution plans. Can also order by [total_cpu_time (seconds)] for example*/

select
    quotename(db_name(qt.dbid)) as database_name,   quotename(object_schema_name(qt.objectid, qt.dbid)) + N'.' + quotename(object_name(qt.objectid, qt.dbid)) as qualified_object_name
    , sql_handle
    , plan_generation_num
    , plan_handle
    , statement_start_offset
    , statement_end_offset
    , creation_time
    , last_execution_time
    , execution_count
    , total_worker_time/1000.00/1000.00 as [total_cpu_time (seconds)]
    , last_worker_time/1000.00/1000.00 as [last_cpu_time (seconds)]
    , min_worker_time/1000.00/1000.00 as [min_cpu_time (seconds)]
    , max_worker_time/1000.00/1000.00 as [max_worker_time (seconds)]
    , total_physical_reads
    , last_physical_reads
    , min_physical_reads
    , max_physical_reads
    , total_logical_reads
    , last_logical_reads
    , min_logical_reads
    , max_logical_reads
    , total_logical_writes
    , last_logical_writes
    , min_logical_writes
    , max_logical_writes
    , total_clr_time/1000.00/1000.00 as [total_clr_time (seconds)]
    , last_clr_time/1000.00/1000.00 as [last_clr_time (seconds)]
    , min_clr_time/1000.00/1000.00 as [min_clr_time (seconds)]
    , max_clr_time/1000.00/1000.00 as [max_clr_time (seconds)]
    , total_elapsed_time/1000.00/1000.00 as [total_elapsed_time (seconds)]
    , last_elapsed_time/1000.00/1000.00 as [last_elapsed_time (seconds)]
    , min_elapsed_time/1000.00/1000.00 as [min_elapsed_time (seconds)]
    , max_elapsed_time/1000.00/1000.00 as [max_elapsed_time (seconds)]
    , (SELECT TOP 1 SUBSTRING(qt.text,statement_start_offset / 2+1 , 
      ( (CASE WHEN statement_end_offset = -1 
         THEN (LEN(CONVERT(nvarchar(max),qt.text)) * 2) 
         ELSE statement_end_offset END)  - statement_start_offset) / 2+1))  AS sql_statement
    , qp.query_plan
from sys.dm_exec_query_stats
    cross apply sys.dm_exec_sql_text(sql_handle) as qt
    cross apply sys.dm_exec_query_plan(plan_handle) as qp
	WHERE (SELECT TOP 1 SUBSTRING(qt.text,statement_start_offset / 2+1 , 
      ( (CASE WHEN statement_end_offset = -1 
         THEN (LEN(CONVERT(nvarchar(max),qt.text)) * 2) 
         ELSE statement_end_offset END)  - statement_start_offset) / 2+1)) LIKE '%some of% your query%'
order by [total_elapsed_time (seconds)] desc 
GO
