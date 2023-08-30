-- =============================================
-- Description: Query SSISDB Package History
-- =============================================

USE SSISDB;
GO

DECLARE @PackageName NVARCHAR(255)
SET @PackageName = '%'

SELECT e.execution_id AS ExecutionID,
       e.folder_name AS FolderName,
       e.project_name AS ProjectName,
       e.package_name AS PackageName,
       e.start_time AS StartTime,
       e.end_time AS EndTime,
       STUFF(
                CONVERT(CHAR(8), CAST(e.end_time AS DATETIME) - CAST(e.start_time AS DATETIME), 108),
                1,
                2,
                DATEDIFF(hh, 0, CAST(e.end_time AS DATETIME) - CAST(e.start_time AS DATETIME))
            ) AS Duration,
       CASE status
           WHEN 1 THEN 'Created'
           WHEN 2 THEN 'Running'
           WHEN 3 THEN 'Cancelled'
           WHEN 4 THEN 'Failed'
           WHEN 5 THEN 'Pending'
           WHEN 6 THEN 'Ended Unexpectedly'
           WHEN 7 THEN 'Succeeded'
           WHEN 8 THEN 'Stopping'
           WHEN 9 THEN 'Completed'
           ELSE NULL
       END AS StatusDesc
FROM [catalog].[executions] AS e
WHERE e.package_name LIKE @PackageName;
