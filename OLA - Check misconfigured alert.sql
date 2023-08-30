/*
Use this script to review SCOM alert for "Ola Hallengren jobs are misconfigured"

- There should be EXACTLY four UNIQUE jobs returned by the query, i.e., the four
    cleanup jobs deployed as part of the standard maintenance solution
- If any are missing, check the jobs are created and enabled
- Review any extra jobs
- Each job should have run successfully within the last 7 days
*/

USE msdb

SELECT j.name AS job_name,
    j.enabled,
	js.step_id,
	js.step_name,
	h.last_success,
	js.command
FROM sysjobs j
	JOIN sysjobsteps js ON j.job_id = js.job_id
	OUTER APPLY
	(
		SELECT TOP 1 dbo.agent_datetime(jh.run_date, jh.run_time) AS last_success
		FROM sysjobhistory jh
		WHERE jh.job_id = js.job_id
			AND jh.step_id = js.step_id
			AND jh.run_status = 1
		ORDER BY jh.run_date DESC, jh.run_time DESC
	) h
WHERE (
		js.command LIKE '%delete%commandlog%'           -- CommandLog Cleanup
		OR js.step_name LIKE '%output file cleanup%'    -- Output File Cleanup
		OR js.command LIKE '%sp_delete_backuphistory%'  -- sp_delete_backuphistory
		OR js.command LIKE '%sp_purge_jobhistory%'      -- sp_purge_jobhistory
	)
    AND j.enabled = 1
ORDER BY job_name, step_id
