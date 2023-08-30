SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--=============================================
-- Copyright (C) 2019 Coeo Ltd
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
-- Description:	Returns statements to Disable, Enable and Run jobs
--              This script can be useful for failovers.
--
-- Log History:	
--				02/05/2019 RAG - Created
--
-- =============================================

--==============================================
-- Execute in SQLCMD
--==============================================

--:CONNECT SERVERNAME

SELECT ':CONNECT ' + @@SERVERNAME AS disable_command
		, ':CONNECT ' + @@SERVERNAME AS enable_command
		, ':CONNECT ' + @@SERVERNAME AS run_command
UNION
SELECT 'EXEC msdb.dbo.sp_update_job @job_name = N''' +name+ ''', @enabled = 0' + CHAR(10) 
		, 'EXEC msdb.dbo.sp_update_job @job_name = N''' +name+ ''', @enabled = 1' + CHAR(10)
		, 'EXEC msdb.dbo.sp_start_job @job_name = N''' +name+ '''' + CHAR(10)
FROM msdb.dbo.sysjobs
WHERE name like 'LS%'
AND enabled = 1
UNION 
SELECT 'GO', 'GO', 'GO'
ORDER BY 1
GO
