/*
================================================================

  Search Error Logs
	Description: 
	This script generates commands to read multiple SQL Server
  error logs easily and with the cut-off date/time as a comment. 
  You can also search for a specific string in the log 
  using the @SearchString variable below.

================================================================
*/


CREATE TABLE #ErrorLogs 
  ( 
     [LogNumber]    INT, 
     [Date]         DATETIME, 
     [LogFileSize]  BIGINT 
  ) 

CREATE CLUSTERED INDEX IX_LogNumber ON #ErrorLogs([LogNumber] DESC); 

INSERT INTO #ErrorLogs 
EXEC xp_enumerrorlogs;
GO
-------------------------------------------------------------------------------------------------------------------

DECLARE @SearchString SYSNAME; 
SET @SearchString = NULL;
--SET @SearchString = 'Test';

-------------------------------------------------------------------------------------------------------------------

SELECT [LogNumber], 
       'EXEC sp_readerrorlog ' 
       + CONVERT(VARCHAR(5), [LogNumber]) 
	   + ',1'
	   + CASE WHEN @SearchString IS NOT NULL THEN (',''' + @SearchString + '''') ELSE '' END + ';' AS [ReadErrorLog],
	   '--' + CONVERT(VARCHAR(20),[Date]) as [Date]
FROM #ErrorLogs;

DROP TABLE #ErrorLogs; 
