/*
Requires SQL 2005 or later

This script gets all config info for availability groups running on target instance

This can take a while to run when there are lots of databases/groups, so should only be used for this use case

SW - 09/2022
*/

SET ANSI_NULLS ON

IF OBJECT_ID(N'tempdb..#groupDBs') IS NOT NULL
BEGIN
	DROP TABLE #groupDBs
END
GO

SELECT group_id
	,STUFF((
			SELECT ', ' + [database_name]
			FROM sys.availability_databases_cluster
			WHERE (group_id = Results.group_id)
			FOR XML PATH('')
				,TYPE
			).value('(./text())[1]', 'VARCHAR(MAX)'), 1, 2, '') AS databaselistbygroup
INTO #groupDBs
FROM sys.availability_databases_cluster Results
GROUP BY group_id

SELECT agr.replica_server_name
	,ag.name AS [availability_group_name]
	,gdbs.databaselistbygroup AS [databases_in_group]
	,agr.endpoint_url
	,agr.availability_mode_desc
	,agr.failover_mode_desc
	,agr.session_timeout
	,agr.primary_role_allow_connections_desc
	,agr.secondary_role_allow_connections_desc
	,agr.backup_priority
	,COALESCE(agr.read_only_routing_url, 'N/A') AS [read_only_routing_url]
	,COALESCE(CAST(rl.routing_priority AS NVARCHAR(5)), CAST('N/A' AS NVARCHAR(5))) AS [routing_priority]
	,COALESCE(agr2.replica_server_name, 'N/A') AS [read_only_replica]
	,ag.failure_condition_level
	,ag.health_check_timeout
	,ag.automated_backup_preference_desc
	,gl.dns_name AS [group_listner_dns_name]
	,gl.port AS [group_listener_port]
	,CASE
		WHEN gl.is_conformant = 1
			THEN 'YES'
		ELSE 'NO'
		END AS [is_conformant]
	,glip.ip_address AS [listener_ip_address]
	,glip.ip_subnet_mask AS [listener_ip_subnet_mask]
	,CASE
		WHEN glip.is_dhcp = 1
			THEN 'YES'
		ELSE 'NO'
		END AS [listener_is_dhcp_enabled]
	,glip.network_subnet_prefix_length AS [listener_network_subnet_prefix_length]
	,glip.network_subnet_ipv4_mask AS [listener_network_subnet_ipv4_mask]
	,glip.state_desc AS [listener_state]
FROM sys.availability_replicas agr
LEFT JOIN sys.availability_read_only_routing_lists rl ON agr.replica_id = rl.replica_id
LEFT JOIN sys.availability_groups ag ON ag.group_id = agr.group_id
LEFT JOIN sys.availability_replicas agr2 ON agr2.replica_id = rl.read_only_replica_id
LEFT JOIN sys.availability_group_listeners gl ON gl.group_id = ag.group_id
LEFT JOIN sys.availability_group_listener_ip_addresses glip ON glip.listener_id = gl.listener_id
LEFT JOIN #groupDBs gdbs ON gdbs.group_id = ag.group_id
