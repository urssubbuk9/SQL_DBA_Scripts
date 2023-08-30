/*
	Description: Deletes backup history for specified database.
	Notes: Similar to sp_delete_database_backuphistory but uses set-based deletes rather than cursor!
*/

USE msdb
SET NOCOUNT ON

DECLARE @db sysname
DECLARE @keep_days int
DECLARE @do_delete bit
DECLARE @temp table (media_set_id int NOT NULL PRIMARY KEY)
DECLARE @rc int
DECLARE @err int

/*
	@db = wilcard search for matching database name
		OR '$offline$' for all offline databases
		OR '$orphan$' for all orphaned backup data
*/
SET @db = '%'
SET @keep_days = 90
SET @do_delete = 0

--create index on backupset for performance
IF NOT EXISTS
	(
		SELECT *
		FROM sys.indexes i
			JOIN sys.tables t ON i.object_id = t.object_id
			JOIN sys.index_columns ic ON i.index_id = ic.index_id
				AND i.object_id = ic.object_id
			JOIN sys.columns c ON ic.column_id = c.column_id
				AND c.object_id = ic.object_id
		WHERE t.name = 'backupset'
			AND c.name = 'media_set_id'
			AND ic.key_ordinal = 1
	)
BEGIN
	RAISERROR('Creating index on backupset.', 0, 1) WITH NOWAIT
	CREATE NONCLUSTERED INDEX IX_backupset_media_set_id ON backupset(media_set_id)
END

INSERT @temp
SELECT DISTINCT media_set_id
FROM backupset bs
WHERE
	(
		database_name LIKE @db
		OR
		(
			@db = '$offline$'
			AND EXISTS (SELECT * FROM master.sys.databases WHERE name = bs.database_name AND state_desc = 'offline')
		)
		OR
		(
			@db = '$orphan$'
			AND NOT EXISTS (SELECT * FROM master.sys.databases WHERE name = bs.database_name)
		)
	)
	AND backup_finish_date < DATEADD(dd, -@keep_days, GETDATE())
OPTION (RECOMPILE)

SELECT @rc = @@ROWCOUNT

RAISERROR('Got %d media_set_ids to delete.', 0, 1, @rc) WITH NOWAIT

IF @do_delete = 1
BEGIN
	BEGIN TRY
		--delete restore history
		DELETE restorefile
		FROM restorefile rf
			INNER JOIN restorehistory rh ON rf.restore_history_id = rh.restore_history_id
			INNER JOIN backupset bs ON rh.backup_set_id = bs.backup_set_id
			INNER JOIN @temp t ON bs.media_set_id = t.media_set_id

		SELECT @rc = @@ROWCOUNT

		RAISERROR('Deleted %d rows from restorefile.', 0, 1, @rc) WITH NOWAIT

		DELETE restorefilegroup
		FROM restorefilegroup rfg
			INNER JOIN restorehistory rh ON rfg.restore_history_id = rh.restore_history_id
			INNER JOIN backupset bs ON rh.backup_set_id = bs.backup_set_id
			INNER JOIN @temp t ON bs.media_set_id = t.media_set_id

		SELECT @rc = @@ROWCOUNT

		RAISERROR('Deleted %d rows from restorefilegroup.', 0, 1, @rc) WITH NOWAIT

		DELETE restorehistory
		FROM restorehistory rh
			INNER JOIN backupset bs ON rh.backup_set_id = bs.backup_set_id
			INNER JOIN @temp t ON bs.media_set_id = t.media_set_id

		SELECT @rc = @@ROWCOUNT

		RAISERROR('Deleted %d rows from restorehistory.', 0, 1, @rc) WITH NOWAIT

		--delete backup history
		DELETE backupfile
		FROM backupfile bf
			INNER JOIN backupset bs ON bf.backup_set_id = bs.backup_set_id
			INNER JOIN @temp t ON bs.media_set_id = t.media_set_id

		SELECT @rc = @@ROWCOUNT

		RAISERROR('Deleted %d rows from backupfile.', 0, 1, @rc) WITH NOWAIT

		DELETE backupfilegroup
		FROM backupfilegroup bfg
			INNER JOIN backupset bs ON bfg.backup_set_id = bs.backup_set_id
			INNER JOIN @temp t ON bs.media_set_id = t.media_set_id

		SELECT @rc = @@ROWCOUNT

		RAISERROR('Deleted %d rows from backupfilegroup.', 0, 1, @rc) WITH NOWAIT

		DELETE backupmediafamily
		FROM backupmediafamily bmf
			INNER JOIN @temp t ON bmf.media_set_id = t.media_set_id

		SELECT @rc = @@ROWCOUNT

		RAISERROR('Deleted %d rows from backupmediafamily.', 0, 1, @rc) WITH NOWAIT

		--use transaction for last two tables so we can get media_set_ids again if there's a problem
		BEGIN TRAN

		DELETE backupset
		FROM backupset bs
			INNER JOIN @temp t ON bs.media_set_id = t.media_set_id

		SELECT @rc = @@ROWCOUNT

		RAISERROR('Deleted %d rows from backupset.', 0, 1, @rc) WITH NOWAIT

		DELETE backupmediaset
		FROM backupmediaset bms
			INNER JOIN @temp t ON bms.media_set_id = t.media_set_id

		SELECT @rc = @@ROWCOUNT

		RAISERROR('Deleted %d rows from backupmediaset.', 0, 1, @rc) WITH NOWAIT

		COMMIT TRAN
	END TRY
	BEGIN CATCH
		WHILE @@TRANCOUNT > 0 ROLLBACK TRAN

		RAISERROR('Delete failed.', 16, 1)
	END CATCH
END
ELSE
BEGIN
	SELECT 'restorefile' AS table_name, COUNT(*) AS rows_to_delete
	FROM restorefile rf
		INNER JOIN restorehistory rh ON rf.restore_history_id = rh.restore_history_id
		INNER JOIN backupset bs ON rh.backup_set_id = bs.backup_set_id
		INNER JOIN @temp t ON bs.media_set_id = t.media_set_id
	UNION ALL
	SELECT 'restorefilegroup' AS table_name, COUNT(*) AS rows_to_delete
	FROM restorefilegroup rfg
		INNER JOIN restorehistory rh ON rfg.restore_history_id = rh.restore_history_id
		INNER JOIN backupset bs ON rh.backup_set_id = bs.backup_set_id
		INNER JOIN @temp t ON bs.media_set_id = t.media_set_id
	UNION ALL
	SELECT 'restorehistory' AS table_name, COUNT(*) AS rows_to_delete
	FROM restorehistory rh
		INNER JOIN backupset bs ON rh.backup_set_id = bs.backup_set_id
		INNER JOIN @temp t ON bs.media_set_id = t.media_set_id
	UNION ALL
	SELECT 'backupfile' AS table_name, COUNT(*) AS rows_to_delete
	FROM backupfile bf
		INNER JOIN backupset bs ON bf.backup_set_id = bs.backup_set_id
		INNER JOIN @temp t ON bs.media_set_id = t.media_set_id
	UNION ALL
	SELECT 'backupfilegroup' AS table_name, COUNT(*) AS rows_to_delete
	FROM backupfilegroup bfg
		INNER JOIN backupset bs ON bfg.backup_set_id = bs.backup_set_id
		INNER JOIN @temp t ON bs.media_set_id = t.media_set_id
	UNION ALL
	SELECT 'backupmediafamily' AS table_name, COUNT(*) AS rows_to_delete
	FROM backupmediafamily bmf
		INNER JOIN @temp t ON bmf.media_set_id = t.media_set_id
	UNION ALL
	SELECT 'backupset' AS table_name, COUNT(*) AS rows_to_delete
	FROM backupset bs
		INNER JOIN @temp t ON bs.media_set_id = t.media_set_id
	UNION ALL
	SELECT 'backupmediaset' AS table_name, COUNT(*) AS rows_to_delete
	FROM backupmediaset bms
		INNER JOIN @temp t ON bms.media_set_id = t.media_set_id
END
