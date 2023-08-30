-- Log shipping query
USE msdb

SELECT getdate() AS server_getdate
		, datediff(MINUTE, lsms.last_restored_date, getdate()) as [Time since last Restore]
		, last_restored_latency as [Last Restored Latency]
		, datediff(mi, lsms.last_copied_date, getdate()) as [Time Since Last Copy]
		, lss.primary_server
		, monitor_server AS secondary_server
		, lss.primary_database
		, lsms.last_restored_date
		, lsms.last_copied_date
		, lss.backup_source_directory
		, lss.backup_destination_directory
	FROM msdb.dbo.log_shipping_secondary lss
		JOIN msdb.dbo.log_shipping_secondary_databases lssd ON lss.secondary_id = lssd.secondary_id
		JOIN msdb.dbo.log_shipping_monitor_secondary lsms ON lss.secondary_id = lsms.secondary_id
--where lsms.last_restored_date < dateadd(mi, -120, getdate())
	ORDER BY 1 desc  
