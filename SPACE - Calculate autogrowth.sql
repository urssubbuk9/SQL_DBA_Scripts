/* ==================================================================================
	Description: Script to give a recommendation ONLY of appropriate AutoGrowth setting for multiple databases.

   ================================================================================== */


SELECT	DB_NAME(mf.database_id) AS [DBName]
		, mf.[type_desc]
		, mf.[name] AS [filename]
		, (mf.size /128) AS [sizeMB]
		, (mf.growth /128) AS [currentGrowthMB]
		, mf.is_percent_growth
		, recommendation.growth AS [recommendedGrowth]
		, 'ALTER DATABASE '
		+ QUOTENAME(DB_NAME(mf.database_id))
		+ ' MODIFY FILE(NAME=N'
		+ QUOTENAME(mf.[name], '''')
		+ ', FILEGROWTH='
		+ recommendation.growth
		+ 'MB);' AS [alterStatement]
FROM	sys.master_files AS mf cross apply
		(SELECT	CASE 
			WHEN (mf.size /128) <= 1024 THEN '100'
			WHEN mf.[type] = 0 and (mf.size /128) >= 102400 THEN '5120'
			ELSE '1024'
		END AS [growth]) AS [recommendation]
WHERE	mf.[type] < 2
and		mf.database_id <> 2
and		((mf.growth /128) < 100 or mf.is_percent_growth = 1)
	UNION ALL
SELECT	'tempdb'
		, mf.[type_desc]
		, mf.[name]
		, (sf.size /128) AS [sizeMB]
		, (sf.growth /128) AS [growthMB]
		, mf.is_percent_growth
		, recommendation.growth
		, 'ALTER DATABASE '
		+ QUOTENAME(DB_NAME(mf.database_id))
		+ ' MODIFY FILE(NAME=N'
		+ QUOTENAME(mf.[name], '''')
		+ ', FILEGROWTH='
		+ recommendation.growth
		+ 'MB);'
FROM	tempdb.sys.sysfiles AS sf inner join
		sys.master_files AS mf on mf.database_id = 2 
and		mf.file_id = sf.fileid cross apply
		(SELECT	CASE 
			WHEN (mf.size /128) <= 1024 THEN '100'
			WHEN mf.[type] = 0 and (mf.size /128) >= 102400 THEN '5120'
			ELSE '1024'
		END AS [growth]) AS [recommendation]
WHERE	((mf.growth /128) < 100 or mf.is_percent_growth = 1);
