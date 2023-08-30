-- ===============================
-- Monitor backup/restore progress
-- ===============================
SELECT 
       Command,
       CAST(percent_complete AS int) AS [Percent Complete], 
       CAST(((DATEDIFF(s,start_time, GETDATE()))/3600) as varchar) + ' hour(s), '
              + CAST((DATEDIFF(s,start_time, GETDATE())%3600)/60 as varchar) + 'min, '
              + CAST((DATEDIFF(s,start_time, GETDATE())%60) as varchar) + ' sec' as [Running Time],
       CAST((estimated_completion_time / 3600000) as varchar) + ' hour(s), '
              + CAST((estimated_completion_time % 3600000) / 60000 AS varchar(50)) + 'min, '
              + CAST((estimated_completion_time % 60000) / 1000 AS varchar(50)) + ' sec' as [Estimated Time Left],
       DATEADD(SECOND, estimated_completion_time/1000, GETDATE()) AS [Estimated Completion Time],
       s.[text] AS [SQL],
       start_time AS [Start Time]
FROM sys.dm_exec_requests AS r
CROSS APPLY sys.dm_exec_sql_text(r.[sql_handle]) AS s
WHERE r.command LIKE 'RESTORE%'
OR r.command LIKE 'BACKUP%';
