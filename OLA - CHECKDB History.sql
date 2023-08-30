SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--=============================================
-- Copyright (C) 2019 Coeo Ltd.
-- All rights reserved.
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
-- Author:		Raul Gonzalez, @SQLDoubleG (RAG)
-- Create date: 11/11/2019
-- Description:	Reads the commandlog table to find CHECKDB maintenance commands
--
-- Assumptions:	The commandlog table is in [master], change it if that's not the case
-- Log History:	
--				11/11/2019 RAG	Created
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

SELECT [ID]
		, [DatabaseName]
		, [CommandType]
		, [StartTime]
		, [EndTime]
		, tempdb.dbo.[formatSecondsToHR](DATEDIFF(SECOND, [StartTime], [EndTime])) AS duration
		, [ErrorNumber]
		, [ErrorMessage]
		, [Command]
FROM [master].dbo.CommandLog
WHERE CommandType = 'DBCC_CHECKDB'
AND DatabaseName = ISNULL(@dbname, DatabaseName)
ORDER BY ID ASC;

-- =============================================
-- Dependencies:This Section will remove any dependancy
-- =============================================
USE tempdb
GO
DROP FUNCTION [dbo].[formatSecondsToHR]
GO
