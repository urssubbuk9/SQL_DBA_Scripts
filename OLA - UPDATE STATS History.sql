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
-- Description:	Reads the commandlog table to find index maintenance commands
--
-- Log History:	
--				26/06/2019 RAG	Created
--
-- =============================================
-- =============================================
-- Dependencies:This Section will create on tempdb any dependant function
-- =============================================
USE tempdb
GO
CREATE FUNCTION [dbo].[formatSecondsToHR](
	@nSeconds INT
)
RETURNS VARCHAR(24)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @R VARCHAR(24)

	SET @R = ISNULL(NULLIF(CONVERT(VARCHAR(24), @nSeconds / 3600 / 24 ),'0') + '.', '') + 
				RIGHT('00' + CONVERT(VARCHAR(24), @nSeconds / 3600 % 24 ), 2) + ':' + 
				RIGHT('00' + CONVERT(VARCHAR(24), @nSeconds / 60 % 60), 2) + ':' + 
				RIGHT('00' + CONVERT(VARCHAR(24), @nSeconds % 60), 2)

	RETURN @R

END
GO
-- =============================================
-- END of Dependencies
-- =============================================

DECLARE @dbname		SYSNAME = NULL
DECLARE @tableName	SYSNAME	= NULL

SELECT [ID]
		, [DatabaseName]
		, [SchemaName]
		, [ObjectName]
		, [ObjectType]
		, [StatisticsName]
		, [Command]
		, [CommandType]
		, [StartTime]
		, [EndTime]
		, [tempdb].[dbo].[formatSecondsToHR](DATEDIFF(SECOND, [StartTime], [EndTime])) AS duration
		, [ErrorNumber]
		, [ErrorMessage]
FROM master.dbo.CommandLog AS c
WHERE CommandType = 'UPDATE_STATISTICS'
AND [ObjectName] = ISNULL(@tableName, [ObjectName])
AND DatabaseName = ISNULL(@dbname, DatabaseName)
ORDER BY 1 ASC;

-- =============================================
-- Dependencies:This Section will remove any dependancy
-- =============================================
USE tempdb
GO
DROP FUNCTION [dbo].[formatSecondsToHR]
GO
