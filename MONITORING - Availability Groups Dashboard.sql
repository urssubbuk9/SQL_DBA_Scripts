/*

In order to give everyone the chance to hone (or show off) their skills with T-SQL querying, I’m going to be sending out a regular T-SQL challenge every month. Let’s start off simple…

Using either the availability group you’ve built while attending Matt’s AG training or the SCOM ag
, write a query or set of queries to show the status for all availability groups on a given instance to include the following as a minimum:
•	Availability group name
•	Availability group healthy / unhealthy etc., synchronized / synchronizing etc.
•	Name and state of each availability replica
•	Name and state of each availability database

Once you’ve written your query, send me the *.sql file with the subject “T-SQL Challenge” no later than 12th January. 
Depending on how everyone gets on, we’ll then look at arranging some follow up classroom sessions to discuss different approaches.

I’ve detailed some of the DMVs that you might find helpful for this. There may be others…

•	sys.availability_groups
•	sys.availability_replicas
•	sys.dm_hadr_availability_replica_states



*/
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
-- Author:		Raul Gonzalez
-- Create date: 13/12/2019
-- Description:	Returns information of availability groups / databases
--
--
-- Parameters:
--				@agname
--
-- Log History:	
--
--=============================================

DECLARE @agname SYSNAME = NULL

-- 
-- Ag Level information
--
SELECT ag.name AS AG_name
		, agr.replica_server_name 
		, agr.availability_mode_desc
		, agrs.role_desc
		, agrs.synchronization_health_desc
		, agr.failover_mode_desc
		, agr.secondary_role_allow_connections_desc AS readable_secondary
		--, * 
	FROM sys.availability_groups AS ag
		INNER JOIN sys.availability_replicas AS agr
			ON agr.group_id = ag.group_id
		INNER JOIN sys.dm_hadr_availability_replica_states AS agrs
			ON agrs.group_id = ag.group_id
				AND agrs.replica_id = agr.replica_id
	WHERE (@agname IS NULL OR ag.name LIKE @agname)
	ORDER BY ag.name, role_desc, availability_mode_desc DESC, replica_server_name

--
-- Per Availability Database information
--
SELECT ag.name
		, agr.replica_server_name
		, d.database_name
		, ISNULL(ds.database_state_desc, 'SECONDARY') AS database_state_desc
		, ds.synchronization_health_desc
		, ds.synchronization_state_desc
		, ISNULL(ds.log_send_queue_size	, '-') AS log_send_queue_size	
		, ISNULL(ds.log_send_rate	, '-') AS log_send_rate	
		, ISNULL(ds.log_send_queue_size / NULLIF(ds.log_send_rate, 0), 0) AS log_send_etc
		, ISNULL(ds.redo_queue_size	, '-') AS redo_queue_size	
		, ISNULL(ds.redo_rate, '-') AS redo_rate
		, ISNULL(ds.redo_queue_size / NULLIF(ds.redo_rate, 0), 0) AS redo_send_etc
		, ISNULL(ds.secondary_lag_seconds, '-') AS secondary_lag_seconds
		--, *
	FROM sys.availability_databases_cluster AS d
		INNER JOIN sys.availability_groups AS ag
			ON ag.group_id = d.group_id
		INNER JOIN sys.availability_replicas AS agr
			ON agr.group_id = ag.group_id
		INNER JOIN sys.dm_hadr_database_replica_states AS ds
			ON ds.group_id = d.group_id
				AND ds.group_database_id = d.group_database_id
				AND ds.replica_id = agr.replica_id
	WHERE (@agname IS NULL OR ag.name LIKE @agname)
	ORDER BY ag.name
			, availability_mode_desc DESC
			, agr.replica_server_name
			, d.database_name
GO
