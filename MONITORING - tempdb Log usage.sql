SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--=============================================
--   
-- You may alter this code for your own *non-commercial* purposes. You may
-- republish altered code as long as you give due credit.
--   
-- THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
-- ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
-- TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
-- PARTICULAR PURPOSE.
--
-- =============================================
-- Description:	Raises an error when log usage is above the threshold
--				for a given database or any if not specified
--
-- Remarks:
--				Create a job that runs every X minutes with N retries every X minutes
--                  The job will fail when log usage is above the threhold for a period of N * X
--
-- Parameters:
--				@dbname
--              @threshold
--
-- Log History:	
--				2019-07-11 RAG - Created
-- =============================================

DECLARE @dbname SYSNAME
DECLARE @threshold DECIMAL(5,2) = 80


CREATE TABLE #LogUsage(
    [Database_Name] SYSNAME
    , [LogSize] DECIMAL(15, 2)
    , [LogSpaceUsed] DECIMAL(5,2)
    , Status INT
)

INSERT INTO #LogUsage
EXECUTE sp_executesql N'DBCC SQLPERF(''Logspace'')'

IF EXISTS (SELECT * FROM #LogUsage 
            WHERE Database_Name = ISNULL(@dbname, Database_Name)
                AND LogSpaceUsed >= @threshold) BEGIN
	RAISERROR('log usage over the threshold', 16, 0, 1,1)
END 
ELSE BEGIN
	PRINT 'log usage below the threshold'
END
