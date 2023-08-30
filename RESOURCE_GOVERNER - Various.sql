/*Author/provider: Roberto*/

--======================================================
-- Obtain resource pool and worload group configuration
--======================================================

USE master  
SELECT * FROM sys.resource_governor_resource_pools  
SELECT * FROM sys.resource_governor_workload_groups  
GO 

--======================================================
--- Get the classifier function Id and state (enabled).
--======================================================

SELECT * FROM sys.resource_governor_configuration  
GO  
--- Get the classifer function name and the name of the schema  
--- that it is bound to.  
SELECT   
      object_schema_name(classifier_function_id) AS [schema_name],  
      object_name(classifier_function_id) AS [function_name]  
FROM sys.dm_resource_governor_configuration  

--==========================================================================================================
-- Obtain the current runtime data for the resource pools and workload groups by using the following query. 
--==========================================================================================================

SELECT * FROM sys.dm_resource_governor_resource_pools  
SELECT * FROM sys.dm_resource_governor_workload_groups  
GO

--=====================================================================
--Find out what sessions are in each group by using the following query.
--=====================================================================

SELECT s.group_id, CAST(g.name as nvarchar(20)) as ResourcePool, s.session_id, s.login_time, CAST(s.host_name as nvarchar(20)) as HostName, CAST(s.program_name AS nvarchar(20)) as ProgramName
          FROM sys.dm_exec_sessions s  
     INNER JOIN sys.dm_resource_governor_workload_groups g  
          ON g.group_id = s.group_id  
ORDER BY g.name  
GO  

--=====================================================================
--Find out which requests are in each group by using the following query.
--======================================================================

SELECT r.group_id, g.name, r.status, r.session_id, SUSER_NAME(r.user_id) as UserName, r.request_id, r.start_time, r.command, r.sql_handle, t.text   
           FROM sys.dm_exec_requests r  
     INNER JOIN sys.dm_resource_governor_workload_groups g  
            ON g.group_id = r.group_id  
     CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t  
ORDER BY g.name  
GO

--==================================================================================
--Find out what requests are running in the classifier by using the following query.
--==================================================================================

SELECT s.group_id, g.name, s.session_id, s.login_time, s.host_name, s.program_name   
           FROM sys.dm_exec_sessions s  
     INNER JOIN sys.dm_resource_governor_workload_groups g  
           ON g.group_id = s.group_id  
                 AND 'preconnect' = s.status  
ORDER BY g.name  
GO  

SELECT r.group_id, g.name, r.status, r.session_id, r.request_id, r.start_time, r.command, r.sql_handle, t.text   
           FROM sys.dm_exec_requests r  
     INNER JOIN sys.dm_resource_governor_workload_groups g  
           ON g.group_id = r.group_id  
                 AND 'preconnect' = r.status  
     CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t  
ORDER BY g.name  
GO  

-- Check username and programname
USE master;
SELECT  session_id,
        program_name, *
FROM    sys.dm_exec_sessions
WHERE   program_name IS NOT NULL;
