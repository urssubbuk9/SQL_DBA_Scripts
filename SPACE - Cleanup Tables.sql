/* =========================================================================
			DATE: 11th May 2018
		 	 Description: A script to delete tables older than X in the chosen database
		   
		   Notes: Script does not check for foreign keys etc that 
				  could prevent tables from being dropped.
   ========================================================================= */

/* RAISERROR ('ErrorText,Severity,State) WITH LOG (sends to SQL error log)*/

USE AdhocDataRequests 
SELECT 'DROP TABLE ' + QUOTENAME([s].[name]) + '.' + QUOTENAME([tables].[name]) + '; ' + 'RAISERROR (''Table ' + QUOTENAME([s].[name]) + '.' + QUOTENAME([tables].[name]) + ' has been dropped by the cleanup job (Purge_AdhocDataRequests_Tables)'', 1 , 1) WITH LOG;' AS command
INTO #TempTableList
FROM sys.tables tables JOIN sys.schemas s ON tables.schema_id = s.schema_id
WHERE tables.modify_date < (GETDATE()-30)

--Declare the cursor and command variable
DECLARE @command VARCHAR(256)
DECLARE tablesToRemove_cursor CURSOR FOR
	SELECT command FROM #TempTableList

--Populate with first command
OPEN tablesToRemove_cursor
FETCH NEXT FROM tablesToRemove_cursor INTO @command

--While there are commands left, execute them
WHILE @@FETCH_STATUS = 0
BEGIN
    --EXEC (@command)
    PRINT (@command)
    FETCH NEXT FROM tablesToRemove_cursor INTO @command
END
--Clean up afterwards
CLOSE tablesToRemove_cursor
DEALLOCATE tablesToRemove_cursor
DROP table #TempTableList
