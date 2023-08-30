/* 
Author: Unknown
Description: Queries job history to find which jobs would have been running at a certain time 

Changes : 
			RAG - 2019-03-18	- Changed the duration to be calculated in seconds and then added to '2010-01-01' to avoid errors when a job
								run for longer than 24h
								- Added run_duration which will be in this format [d.hh:mm:ss]
			RAG - 2019-04-26	- Changed a concrete time for a time range to give more flexibility.
			RAG - 2019-04-29	- Changed how duration was calculated to make it simpler

*/
-- =============================================
-- Dependencies:This Section will create on tempdb any dependancy
-- =============================================
USE tempdb
GO
CREATE FUNCTION [dbo].[formatMStimeToHR](
	@duration INT
)
RETURNS VARCHAR(24)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @strDuration VARCHAR(24)
	DECLARE @R			VARCHAR(24)

	SET @strDuration = RIGHT(REPLICATE('0',24) + CONVERT(VARCHAR(24),@duration), 24)

	SET @R = ISNULL(NULLIF(CONVERT(VARCHAR	, CONVERT(INT,SUBSTRING(@strDuration, 1, 20)) / 24 ),0) + '.', '') + 
				RIGHT('00' + CONVERT(VARCHAR, CONVERT(INT,SUBSTRING(@strDuration, 1, 20)) % 24 ), 2) + ':' + 
				SUBSTRING( @strDuration, 21, 2) + ':' + 
				SUBSTRING( @strDuration, 23, 2)
	
	RETURN ISNULL(@R,'-')

END
GO
-- =============================================
-- END of Dependencies
-- =============================================

DECLARE @targetTimeFrom datetime 	SET @targetTimeFrom = '2019-04-25 06:00:00';
DECLARE @targetTimeTo datetime 		SET @targetTimeTo = ISNULL('2019-04-25 07:00:00', @targetTimeFrom);
--<<<EDIT TIME AND DATE YY/MM/DD
-- SET @targetTime = 'xxx' -- for SQL Server 2008 and less



-- convert to string, then int:
DECLARE @filter int = CAST(CONVERT(char(8), @targetTimeFrom, 112) AS int);

;WITH
    times
    AS
    (
       SELECT
            job_id,
            step_name,
			-- Start DATE
			LEFT(run_date, 4) + '-' + SUBSTRING(CAST(run_date AS char(8)),5,2) + '-' + RIGHT(run_date,2) + ' ' + 
			-- Start TIME

			LEFT(REPLICATE('0', 6 - LEN(run_time)) 
				+ CAST(run_time AS varchar(6)), 2) + ':' + 
				SUBSTRING(REPLICATE('0', 6 - LEN(run_time)) 
				+ CAST(run_time AS varchar(6)), 3, 2) + ':' 
				+ RIGHT(REPLICATE('0', 6 - LEN(run_time)) 
				+ CAST(run_time AS varchar(6)), 2) AS [start_time]
		
		-- 
			, DATEADD(SECOND, 
			
				(LEFT( RIGHT('000000' + CONVERT(VARCHAR, run_duration), 6), 2) * 3600 
					+ 
					LEFT( RIGHT('000000' + CONVERT(VARCHAR, run_duration), 4), 2) * 60
					+ 
					RIGHT('000000' + CONVERT(VARCHAR, run_duration), 2))
				, '2010-01-01'
				) AS [duration]
		, run_duration
	    FROM
            msdb.dbo.sysjobhistory
        WHERE
        run_date IN (@filter - 1, @filter, @filter + 1)
    )

SELECT
		j.name
		, t.step_name
		, t.start_time
		, DATEADD(ss, DATEDIFF(ss, '2010-01-01 00:00:00', duration), start_time) [end_time]
		, [tempdb].[dbo].[formatMStimeToHR](run_duration) AS run_duration
FROM
    times t
    INNER JOIN msdb.dbo.sysjobs j ON j.job_id = t.job_id

WHERE start_time < @targetTimeTo
	AND DATEADD(ss, DATEDIFF(ss, '2010-01-01 00:00:00', duration), start_time) > @targetTimeFrom
ORDER BY 
        run_duration DESC


-- =============================================
-- Dependencies:This Section will remove any dependancy
-- =============================================
USE tempdb
GO
DROP FUNCTION [dbo].[formatMStimeToHR]
GO
