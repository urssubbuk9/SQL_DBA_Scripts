-- ===========================================================================
-- Description:	Script to calculate DB free space dependant on various factors
-- Info: 		DBs can be excluded in the first INSERT code block
-- ===========================================================================

IF OBJECT_ID('tempdb..#masterfiles') IS NOT NULL
	DROP TABLE #masterfiles

DECLARE @rowcount INT
DECLARE @i INT = 1
DECLARE @databaseid INT
DECLARE @fileid INT
DECLARE @size INT
DECLARE @maxsize INT
DECLARE @growth INT
DECLARE @sql NVARCHAR(max)
DECLARE @usedspace INT
DECLARE @diskspace BIGINT

CREATE TABLE #masterfiles (
	id INT identity(1, 1)
	,database_id INT
	,file_id INT
	,size INT
	,max_size INT
	,growth INT
	)

INSERT INTO #masterfiles
SELECT database_id
	,file_id
	,size
	,max_size
	,growth
FROM sys.master_files
WHERE type = 0
	-- EXCLUDE DATABASES HERE IF NEEDED
	--AND name NOT IN (
	--	'DB NAME'
	--	,'DB NAME'
	--	)

SELECT @rowcount = COUNT(0)
FROM #masterfiles

WHILE @i < @rowcount
BEGIN
	SELECT @databaseid = database_id
		,@fileid = file_id
		,@size = size
		,@maxsize = max_size
		,@growth = growth
	FROM #masterfiles
	WHERE id = @i

	SET @sql = N'use [' + DB_NAME(@databaseid) + N']
			select @usedspace = FILEPROPERTY (FILE_NAME(@fileid), ''spaceused'')'

	EXEC sp_executesql @sql
		,N'@usedspace int output, @fileid int'
		,@fileid = @fileid
		,@usedspace = @usedspace OUTPUT

	--case 1: when no growth on DB file allowed, check available space / total space * 100
	--Is growth allowed? growth = 0
	IF @growth = 0
	BEGIN
		IF (cast(@usedspace AS FLOAT) / cast(@size AS FLOAT)) > 0.8
		BEGIN
			PRINT 'Case 1 ' + db_name(@databaseid)

			RAISERROR (
					'A DB data file has less than 20 Percent free space, please investigate'
					,16
					,1
					)
		END
	END

	--case 2: when file growth on DB file allowed, add free space on disk to DB available space / total space * 100
	--growth > 0
	IF @growth > 1
		AND @maxsize = - 1
	BEGIN
		SELECT @diskspace = available_bytes
		FROM sys.dm_os_volume_stats(@databaseid, @fileid)

		SET @diskspace = @diskspace / 1024 / 1024

		IF (cast(@usedspace AS FLOAT) / (cast(@diskspace AS FLOAT) + cast(@size AS FLOAT))) > 0.8
		BEGIN
			PRINT 'Case 2 ' + db_name(@databaseid)

			RAISERROR (
					'A DB data file has less than 20 Percent free space, please investigate'
					,16
					,1
					)
		END
	END

	--case 3: when file growth on DB file limited, check max size / total space * 100
	--growth >0
	IF @growth > 1
		AND @maxsize <> 1
		IF cast(@usedspace AS FLOAT) / cast(@maxsize AS FLOAT) > 0.8
		BEGIN
			PRINT 'Case 3 ' + db_name(@databaseid)

			RAISERROR (
					'A DB data file has less than 20 Percent free space, please investigate'
					,16
					,1
					)
		END

	SET @i = @i + 1
	SET @SQL = ''
END

DROP TABLE #masterfiles
