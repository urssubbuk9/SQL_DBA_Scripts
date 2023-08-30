DROP EVENT SESSION [SA_is_used] ON SERVER
GO
CREATE EVENT SESSION [SA_login_audit]
ON SERVER
	ADD EVENT sqlserver.login
	(ACTION (sqlserver.client_app_name, sqlserver.client_hostname
			, sqlserver.database_name, sqlserver.is_system, sqlserver.nt_username
			, sqlserver.session_id, sqlserver.session_nt_username, sqlserver.username)
	 WHERE ([sqlserver].[username] = N'sa'))
	ADD TARGET package0.event_file
	(SET filename = N'SA_login_audit', max_file_size = (5), max_rollover_files = (10))
WITH (MAX_MEMORY = 4096KB, EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS, MAX_DISPATCH_LATENCY = 30 SECONDS
	, MAX_EVENT_SIZE = 0KB, MEMORY_PARTITION_MODE = NONE, TRACK_CAUSALITY = OFF, STARTUP_STATE = ON);
GO

ALTER EVENT SESSION [SA_login_audit] ON SERVER STATE = start
