--Written by Christian Bowman

declare 
@JobName nvarchar(100) = 'LSCopy_SQLCLUSCW01-2_Aggregator_2',
@StartDate nvarchar(15) = '20190925',--'YYYYMMDD'
@EndDate nvarchar(15) = '20190925', --'YYYYMMDD'
@RunTimeStart int = '070000', --= 07:00:00
@RunTimEnd int = '080000', --= 08:00:00,
@JobStatus nvarchar(100) = '%', --0,1,2,3,4 or %
@Enabled int = 1, --1=enabled 0 = disabled
@Step = 0 --for all history set to % for only overview 0

select 
h.instance_id,
 j.name as 'JobName',
 h.step_id,
 run_date,
 case run_status when 0 then 'Failed'
				when 1 then 'Succeeded'
				when 2 then 'Retry'
				when 3 then 'Canceled'
				when 4 then 'In Progress' end as Status,
 STUFF(STUFF(RIGHT(REPLICATE('0', 6) +  CAST(h.run_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':') 'run_time',
 h.message,
 msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime'
From msdb.dbo.sysjobs j 
INNER JOIN msdb.dbo.sysjobhistory h 
 ON j.job_id = h.job_id 
where j.enabled = @enabled  --Only Enabled Jobs
and j.name = @JobName
and h.run_status like @JobStatus
and h.run_date >= @StartDate
and h.run_date <= @EndDate
and run_time between @RunTimeStart and @RunTimEnd
order by h.instance_id desc --,run_time desc,step_id asc
