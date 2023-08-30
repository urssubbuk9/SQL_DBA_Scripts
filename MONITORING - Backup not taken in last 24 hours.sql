-- ===========================================================================
-- Description:	Script to check last Backup within a time period
-- Info: 		Backup last check time can be changed
-- ===========================================================================

-- DBs with no full backups in last day
SELECT CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS SERVER
	,msdb.dbo.backupset.database_name
	,MAX(msdb.dbo.backupset.backup_finish_date) AS last_db_backup_date
	,DATEDIFF(hh, MAX(msdb.dbo.backupset.backup_finish_date), GETDATE()) AS [Backup Age (Hours)]
FROM msdb.dbo.backupset
WHERE msdb.dbo.backupset.type = 'D'
	--Modify below to exclude database names
	AND msdb.dbo.backupset.database_name NOT IN ('')
GROUP BY msdb.dbo.backupset.database_name
-- CHANGE TIME PERIOD TO SUIT NEEDS
HAVING (MAX(msdb.dbo.backupset.backup_finish_date) < DATEADD(hh, - 25, GETDATE()))

--Raise error if any found
IF (@@ROWCOUNT > 0)
BEGIN
	RAISERROR (
			'A DB with no backup in 24 hours has been identified'
			,16
			,1
			)
END
