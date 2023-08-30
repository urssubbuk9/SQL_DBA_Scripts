--MADE BY Ben Edwards and Daria Afanasyeva
--Shrinking log files, where the log files are bigger than data files; Take a log backup, if the log file won't shrink


WITH files AS
(
    SELECT DB_NAME(database_id) AS db,
        SUM(CASE WHEN type_desc = 'ROWS' THEN size ELSE 0 END)/128 AS data_size,
        SUM(CASE WHEN type_desc = 'LOG' THEN size ELSE 0 END)/128 AS log_size
    FROM sys.master_files
    GROUP BY database_id
)
SELECT *,
-- Shrink to 90% of the data file size
'USE [' + db + ']' + CHAR(10)+ 'GO' + CHAR(10) + 'DBCC SHRINKFILE (2, ' + CAST((CAST(data_size * 0.9 as int)) as VARCHAR(10)) + ')' + CHAR(10) as [ShrinkFile]
FROM files
WHERE log_size > data_size and (data_size > 1024 or log_size > 1024)
ORDER BY db
