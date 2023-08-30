----------------------------------------------------------------------------------------------
-- Create the xEvent trace to capture distributed transactions
---------------------------------------------------------------------------------------------
CREATE EVENT SESSION [dtc_monitor] ON SERVER
ADD EVENT sqlserver.dtc_transaction(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.server_principal_name,sqlserver.server_principal_sid,sqlserver.session_id,sqlserver.sql_text))
ADD TARGET package0.ring_buffer(SET max_events_limit=(5000), max_memory=(4096)),
ADD TARGET package0.event_file(SET filename=N'dtc_monitor.xel',max_file_size=(5),max_rollover_files=(4))
WITH (STARTUP_STATE=ON)
GO

-- Start / Stop trace
ALTER EVENT SESSION [dtc_monitor] ON SERVER STATE = START;
--ALTER EVENT SESSION [dtc_monitor] ON SERVER STATE = STOP;


----------------------------------------------------------------------------------------------
-- Use this to read from the Ring Buffer (data available since SQL Server restart)
----------------------------------------------------------------------------------------------
DECLARE @xml_buffer XML = 
(
	SELECT TOP 1 target_data
	FROM sys.dm_xe_sessions s
	INNER JOIN sys.dm_xe_session_targets st ON s.address = st.event_session_address
	WHERE s.NAME = 'dtc_monitor'
)

SELECT * 
FROM (
	SELECT
		col.value('@timestamp', 'varchar(200)') as [timestamp],
		col.value('(./action/value/text())[7]', 'varchar(200)') as [database_name],
		col.value('(./data/text/text())[2]', 'varchar(200)') as [dtc_transaction_activity],
		col.value('(./action/value/text())[9]', 'varchar(200)') as [client_hostname],
		col.value('(./action/value/text())[10]', 'varchar(200)') as [client_app_name],
		col.value('(./data/value/text())[5]', 'varchar(200)') as [resource_manager_id],
		col.value('(./action/value/text())[5]', 'varchar(200)') as [nt_username],
		col.value('(./action/value/text())[2]', 'varchar(200)') as [session_id],
		col.value('(./action/value/text())[1]', 'nvarchar(max)') as [sql_text]
	FROM @xml_buffer.nodes('RingBufferTarget/event') as tab(col)
) dtc_trans
WHERE dtc_trans.[database_name] IS NOT NULL
ORDER BY dtc_trans.[timestamp] ASC

-- Count the number of enlisting DTC transactions
SELECT 
	dtc_trans.[database_name] AS [database_name],
	COUNT(dtc_trans.dtc_transaction_activity) AS dtc_tran_count 
FROM (
	SELECT
		col.value('(./action/value/text())[7]', 'varchar(200)') as [database_name],
		col.value('(./data/text/text())[2]', 'varchar(200)') as [dtc_transaction_activity]
	FROM @xml_buffer.nodes('RingBufferTarget/event') as tab(col)
) dtc_trans
WHERE dtc_trans.dtc_transaction_activity = 'Enlisting in a DTC transaction'
GROUP BY dtc_trans.[database_name]


----------------------------------------------------------------------------------------------
-- Use this to read from the xEvent output file (will persist data during restarts)
----------------------------------------------------------------------------------------------
SELECT 
	[timestamp],
	[dtc_transaction_activity],
	[database_name],
	[dtc_transaction_activity],
	[client_app_name],
	[resource_manager_id],
	[session_id],
	[sql_text]
FROM 
(
	SELECT 
		CAST(event_data AS XML) AS event_data
	FROM sys.fn_xe_file_target_read_file('dtc_monitor*.xel', null, null, null) 
) dtc_trace
CROSS APPLY 
(
	SELECT
		col.value('@timestamp', 'varchar(200)') as [timestamp],
		col.value('(./action/value/text())[7]', 'varchar(200)') as [database_name],
		col.value('(./data/text/text())[2]', 'varchar(200)') as [dtc_transaction_activity],
		col.value('(./action/value/text())[9]', 'varchar(200)') as [client_hostname],
		col.value('(./action/value/text())[10]', 'varchar(200)') as [client_app_name],
		col.value('(./data/value/text())[5]', 'varchar(200)') as [resource_manager_id],
		col.value('(./action/value/text())[5]', 'varchar(200)') as [nt_username],
		col.value('(./action/value/text())[2]', 'varchar(200)') as [session_id],
		col.value('(./action/value/text())[1]', 'nvarchar(max)') as [sql_text]
	FROM dtc_trace.event_data.nodes('event') as tab(col)
) dtc_trans
WHERE dtc_trans.[database_name] IS NOT NULL
ORDER BY dtc_trans.[timestamp] ASC
GO

-- Count the number of enlisting DTC transactions
SELECT 
	dtc_trans.[database_name] AS [database_name],
	COUNT(dtc_trans.[database_name]) AS [dtc_tran_count]
FROM 
(
	SELECT 
		CAST(event_data AS XML) AS event_data
	FROM sys.fn_xe_file_target_read_file('dtc_monitor*.xel', null, null, null) 
) dtc_trace
CROSS APPLY 
(
	SELECT
		col.value('(./action/value/text())[7]', 'varchar(200)') as [database_name],
		col.value('(./data/text/text())[2]', 'varchar(200)') as [dtc_transaction_activity]
	FROM dtc_trace.event_data.nodes('event') as tab(col)
) dtc_trans
WHERE dtc_trans.[dtc_transaction_activity] = 'Enlisting in a DTC transaction'
GROUP BY dtc_trans.[database_name]
ORDER BY dtc_trans.[database_name] ASC
GO


----------------------------------------------------------------------------------------------
-- Create an agent job to stop the trace.  MAKE SURE YOU UPDATE THE SCHEDULE!!!!!
----------------------------------------------------------------------------------------------
USE [msdb]
GO

/****** Object:  Job [Coeo Job : Stop dtc_monitor]    Script Date: 08/10/2019 13:55:16 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 08/10/2019 13:55:16 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Coeo Job : Stop dtc_monitor', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Stop xEvent Trace]    Script Date: 08/10/2019 13:55:17 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Stop xEvent Trace', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'ALTER EVENT SESSION [dtc_monitor] ON SERVER STATE = STOP', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Stop dtc_monitor schedule', 
		@enabled=1, 
		@freq_type=1, 
		@freq_interval=0, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20191011, 
		@active_end_date=99991231, 
		@active_start_time=150000, 
		@active_end_time=235959, 
		@schedule_uid=N'b8072da5-5279-4127-b473-807b175ae341'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
