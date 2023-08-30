/* From SQL Server Internals Course */

--================================================================================================================
-- Query Store
--================================================================================================================
USE WideWorldImporters_QS;
GO

-- ============
-- Check Status
-- ============
SELECT is_query_store_on from sys.databases WHERE database_id = DB_ID();
SELECT actual_state_desc FROM sys.database_query_store_options;

-- ================
-- Enable / Disable
-- ================
ALTER DATABASE WideWorldImporters_QS SET QUERY_STORE = OFF;
ALTER DATABASE WideWorldImporters_QS SET QUERY_STORE = ON;

-- ===============
-- Change settings
-- ===============
ALTER DATABASE WideWorldImporters_QS SET QUERY_STORE (OPERATION_MODE = READ_ONLY);
ALTER DATABASE WideWorldImporters_QS SET QUERY_STORE (OPERATION_MODE = READ_WRITE);

ALTER DATABASE WideWorldImporters_QS SET QUERY_STORE CLEAR; 

USE WideWorldImporters_QS;
GO

IF OBJECT_ID('dbo.QueryCE') IS NOT NULL
	DROP PROCEDURE dbo.QueryCE;
GO
CREATE PROCEDURE dbo.QueryCE (@OrderNumber int)
AS
	SELECT *
	FROM dbo.CE_demo
	WHERE OrderNumber = @OrderNumber;
RETURN;
GO

UPDATE STATISTICS dbo.CE_demo WITH FULLSCAN;

-- =======
-- PROBLEM
-- =======

-- Run smaller query then large query...
DBCC FREEPROCCACHE;

EXEC dbo.QueryCE @OrderNumber = 1;

DBCC FREEPROCCACHE

EXEC dbo.QueryCE @OrderNumber = 50000;
GO

-- ===============================================================================
-- The number of queries with the longest average execution time within last hour?
-- ===============================================================================
SELECT TOP 10 rs.avg_duration, qt.query_sql_text, q.query_id,  
    qt.query_text_id, p.plan_id, GETUTCDATE() AS CurrentUTCTime,   
    rs.last_execution_time   
FROM sys.query_store_query_text AS qt   
JOIN sys.query_store_query AS q   
    ON qt.query_text_id = q.query_text_id   
JOIN sys.query_store_plan AS p   
    ON q.query_id = p.query_id   
JOIN sys.query_store_runtime_stats AS rs   
    ON p.plan_id = rs.plan_id  
WHERE rs.last_execution_time > DATEADD(hour, -1, GETUTCDATE())  
ORDER BY rs.avg_duration DESC;  

-- ============================
-- Queries with multiple plans?
-- ============================ 
WITH Query_MultPlans  
AS  
(  
SELECT COUNT(*) AS cnt, q.query_id   
FROM sys.query_store_query_text AS qt  
JOIN sys.query_store_query AS q  
    ON qt.query_text_id = q.query_text_id  
JOIN sys.query_store_plan AS p  
    ON p.query_id = q.query_id  
GROUP BY q.query_id  
HAVING COUNT(distinct plan_id) > 1  
)  
SELECT q.query_id, object_name(object_id) AS ContainingObject,   
    query_sql_text, plan_id, p.query_plan AS plan_xml,  
    p.last_compile_start_time, p.last_execution_time  
FROM Query_MultPlans AS qm  
JOIN sys.query_store_query AS q  
    ON qm.query_id = q.query_id  
JOIN sys.query_store_plan AS p  
    ON q.query_id = p.query_id  
JOIN sys.query_store_query_text qt   
    ON qt.query_text_id = q.query_text_id  
WHERE query_sql_text NOT LIKE 'WITH Query_MultPlans%'
ORDER BY query_id, plan_id; 

-- ===================================================================================
-- Queries that recently regressed in performance (comparing different point in time)?
-- ===================================================================================
SELECT   
    qt.query_sql_text,   
    q.query_id,   
    qt.query_text_id,   
    rs1.runtime_stats_id AS runtime_stats_id_1,  
    rsi1.start_time AS interval_1,   
    p1.plan_id AS plan_1,   
    rs1.avg_duration AS avg_duration_1,   
    rs2.avg_duration AS avg_duration_2,  
    p2.plan_id AS plan_2,   
    rsi2.start_time AS interval_2,   
    rs2.runtime_stats_id AS runtime_stats_id_2  
FROM sys.query_store_query_text AS qt   
JOIN sys.query_store_query AS q   
    ON qt.query_text_id = q.query_text_id   
JOIN sys.query_store_plan AS p1   
    ON q.query_id = p1.query_id   
JOIN sys.query_store_runtime_stats AS rs1   
    ON p1.plan_id = rs1.plan_id   
JOIN sys.query_store_runtime_stats_interval AS rsi1   
    ON rsi1.runtime_stats_interval_id = rs1.runtime_stats_interval_id   
JOIN sys.query_store_plan AS p2   
    ON q.query_id = p2.query_id   
JOIN sys.query_store_runtime_stats AS rs2   
    ON p2.plan_id = rs2.plan_id   
JOIN sys.query_store_runtime_stats_interval AS rsi2   
    ON rsi2.runtime_stats_interval_id = rs2.runtime_stats_interval_id  
WHERE rsi1.start_time > DATEADD(hour, -48, GETUTCDATE())   
    AND rsi2.start_time > rsi1.start_time   
    AND p1.plan_id <> p2.plan_id  
    AND rs2.avg_duration > 2*rs1.avg_duration  
ORDER BY q.query_id, rsi1.start_time, rsi2.start_time; 


-- ==========================================
-- Check the status of Forced Plans regularly
-- ==========================================
SELECT 
	p.plan_id, 
	p.query_id, 
	q.object_id as containing_object_id,  
    force_failure_count, 
	last_force_failure_reason_desc  
FROM sys.query_store_plan AS p  
JOIN sys.query_store_query AS q on p.query_id = q.query_id  
WHERE is_forced_plan = 1; 

-- =======================
-- Manually forcing a plan
-- =======================
EXEC sp_query_store_force_plan 	@query_id = 1, @plan_id = 1; 


-- =========================
-- Manually unforcing a plan
-- =========================
EXEC sp_query_store_unforce_plan 	@query_id = 1, @plan_id = 1; 
