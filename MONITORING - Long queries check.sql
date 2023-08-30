--CREATE TABLE master.dbo.LongQueries (Timestamp datetime, SPID int, QueryText nvarchar (4000), Duration int, Login_Name nvarchar (255)) 

--Find all running processes
SELECT 'SPID='+CONVERT(VARCHAR,requests.session_id)+' has been running the following for '+CONVERT(VARCHAR,DATEDIFF(MINUTE, requests.start_time, CURRENT_TIMESTAMP))+' minutes' AS Message,
    CONVERT(VARCHAR,DATEDIFF(MINUTE, requests.start_time, CURRENT_TIMESTAMP)) AS Duration,
    execsessions.login_name AS Username

FROM sys.dm_exec_requests as requests
	CROSS APPLY sys.dm_exec_sql_text(requests.sql_handle) as sqltext
	INNER JOIN sys.dm_exec_sessions as execsessions
		on requests.session_id = execsessions.session_id

--Filter out background processes, system processes and younger than 60 minutes
WHERE requests.status <> 'background'
    AND DATEDIFF(MINUTE, requests.start_time, CURRENT_TIMESTAMP) > 60
    AND execsessions.login_name not like '%svc%'
	AND execsessions.login_name not like '%system%'

--Insert to table LongQueries if found
IF (@@ROWCOUNT > 0)
    BEGIN
		SET ANSI_WARNINGS OFF

		INSERT INTO master.dbo.LongQueries
			SELECT getdate(), requests.session_id, sqltext.text, CONVERT(VARCHAR,DATEDIFF(MINUTE, requests.start_time, CURRENT_TIMESTAMP)), execsessions.login_name

		FROM sys.dm_exec_requests requests
			CROSS APPLY sys.dm_exec_sql_text(requests.sql_handle) sqltext
			INNER JOIN sys.dm_exec_sessions execsessions
				on requests.session_id = execsessions.session_id

		WHERE requests.status <> 'background'
			AND DATEDIFF(MINUTE, requests.start_time, CURRENT_TIMESTAMP) > 60
			AND execsessions.login_name not like '%svc%'
			AND execsessions.login_name not like '%system%'
			
		SET ANSI_WARNINGS ON

		--Raise error if any found
	    RAISERROR ('A long running query has been identified', 16, 1)
    END
