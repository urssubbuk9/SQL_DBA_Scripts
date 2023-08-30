/* ===============================================
    Show last full or log backup times for all dbs
    Author: Unknown
    Date: Unknown
    Last Updated: 31/05/2018 by Subbu CN
   =============================================== */
DECLARE 
       @SQL nvarchar(max),
       @BackupType char(1);

SET @BackupType = 'D'; -- or L (D is full backup, I is differential, L is log)

SET @SQL = '
WITH CTE AS 
(
       SELECT  
              d.[name] AS [Database name],
              b.backup_finish_date AS [Backup finish date],
              CAST(DATEDIFF(minute, b.backup_finish_date, GETDATE()) / 60.0 AS decimal(10,1)) AS [Backup age (hours)],
              b.[user_name] AS [Username],
              m.physical_device_name AS [Backup device],
              ROW_NUMBER() OVER (PARTITION BY d.[name] ORDER BY b.backup_finish_date DESC) AS rn
       FROM [master].sys.databases d
       LEFT OUTER JOIN msdb.dbo.backupset b 
              ON d.name COLLATE SQL_Latin1_General_CP1_CI_AS = b.database_name COLLATE SQL_Latin1_General_CP1_CI_AS
              AND b.[type] = ''' + @BackupType + ''' 
              AND b.server_name = SERVERPROPERTY(''ServerName'') /*Backupset ran on current server */
       LEFT OUTER JOIN msdb.dbo.backupmediafamily AS m
              ON b.media_set_id = m.media_set_id
       WHERE d.is_in_standby = 0                       /* Not a log shipping target database */
       AND d.source_database_id IS NULL  /* Excludes database snapshots */
       AND d.[state] <> 1                              /* Not currently restoring, like log shipping databases */ '

IF (@BackupType = 'D')
BEGIN
       SET @SQL = @SQL + ' AND d.database_id <> 2 '
END
ELSE
BEGIN
       SET @SQL = @SQL + ' AND d.name NOT IN (''master'',''tempdb'',''msdb'') AND d.recovery_model_desc <> ''SIMPLE'' '
END

SET @SQL = @SQL + '  
)
SELECT 
       [Database name],
       [Backup finish date],
       [Backup age (hours)],
       [Username],
       [Backup device]
FROM CTE
WHERE rn = 1
ORDER BY [Database name];';

EXEC(@SQL);
