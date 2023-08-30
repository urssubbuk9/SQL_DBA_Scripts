-- =======================================================
-- Create date: 27/04/2020
-- Description: Sets all User Databases to Simple Recovery
-- =======================================================

DECLARE 
@DBName AS SYSNAME,
@SQL    AS NVARCHAR(MAX)

DECLARE DBCursor CURSOR READ_ONLY FOR
SELECT name
FROM sys.databases
WHERE name NOT IN ('master','model','msdb','tempdb') 
AND recovery_model_desc <> 'Simple'

OPEN DBCursor
FETCH NEXT FROM DBCursor INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN
SET @SQL = '';
SET @SQL = N'ALTER DATABASE [' + @DBName + '] SET RECOVERY SIMPLE;';
PRINT (@SQL);
EXECUTE (@SQL);

FETCH NEXT FROM DBCursor INTO @DBName
END

CLOSE DBCursor
DEALLOCATE DBCursor
