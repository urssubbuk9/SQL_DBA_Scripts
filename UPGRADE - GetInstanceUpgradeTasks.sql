--Instance Discovery for SQL Server 2005 SP2+ only
SET NOCOUNT ON;
USE [master];

--1 logins
DECLARE @MajorVersion tinyint
SET @MajorVersion = CAST(SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(5)),1,CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(5)))-1) AS TINYINT)
 
IF @MajorVersion >= 10 --SQL 2008 LOGINPROPERTY
	EXEC master..sp_executesql N'SELECT name, type_desc, CAST(LOGINPROPERTY(name,''PasswordLastSetTime'') as datetime) as PasswordLastSetTime
	FROM master.sys.server_principals
	WHERE name NOT LIKE ''##%'''
ELSE
	EXEC master..sp_executesql N'SELECT name, ''UNKNOWN'' type_desc, CAST(updatedate as datetime) as PasswordLastSetTime
	FROM master.dbo.syslogins
	WHERE name NOT LIKE ''##%'''


--2 linked servers
IF @MajorVersion >= 10 --SQL 2008 sysservers
EXEC sp_executesql N'SELECT s.server_id, s.name, s.data_source, s.product, s.provider, s.provider_string, s.catalog, s.is_remote_login_enabled, ll.TotalLinkedLogins - s.is_remote_login_enabled as TotalLinkedLogins
FROM sys.servers as s
	LEFT OUTER JOIN 
	(SELECT server_id, COUNT(*) as TotalLinkedLogins
	FROM sys.linked_logins as ll
	GROUP BY server_id
	) as ll
		ON s.server_id = ll.server_id
WHERE NOT (s.server_id = 0 AND s.data_source = @@SERVERNAME)'
ELSE
EXEC sp_executesql N'SELECT s.srvid as server_id, s.srvname as name, s.datasource as data_source, s.srvproduct as product, s.providername as provider, s.providerstring as provider_string, N'''' as catalog, s.isremote as is_remote_login_enabled, cast(NULL as int) as TotalLinkedLogins
FROM master..sysservers as s
WHERE NOT (s.srvid = 0 AND s.datasource = @@SERVERNAME)'

--3 endpoints
IF @MajorVersion >= 10
EXEC sp_executesql N'SELECT name as EndpointName
FROM master.sys.endpoints
WHERE endpoint_id NOT IN (1,2,3,4,5)'
ELSE
SELECT CAST(NULL as sysname) as EndpointName
WHERE 1=2

-- 4 backup devices
IF @MajorVersion >= 10
EXEC sp_executesql N'select name as BackupDeviceName, type_desc
from master.sys.backup_devices'
ELSE
SELECT CAST(NULL as sysname) as BackupDeviceName, CAST(NULL as sysname) as type_desc
WHERE 1=2

--6 alerts
SELECT name
FROM msdb.dbo.sysalerts
ORDER BY name

--7 operators
SELECT name, email_address, last_email_date 
FROM msdb.dbo.sysoperators
ORDER BY name

--8 system database roles
IF @MajorVersion >= 10
EXEC sp_executesql N'SELECT * FROM (
SELECT ''master'' as DatabaseName, name as RoleName,type_desc FROM master.[sys].[database_principals] WHERE type IN (''R'' ,''A'') and is_fixed_role = 0
UNION ALL
SELECT ''msdb'' as DatabaseName, name as RoleName,type_desc FROM msdb.[sys].[database_principals] WHERE type IN (''R'' ,''A'') and is_fixed_role = 0
UNION ALL
SELECT ''model'' as DatabaseName, name as RoleName,type_desc FROM model.[sys].[database_principals] WHERE type IN (''R'' ,''A'') and is_fixed_role = 0
) as t
WHERE RoleName NOT IN (''public'',''db_owner'',''db_accessadmin'',''db_securityadmin'',''db_ddladmin'',''db_backupoperator'',''db_datareader'',''db_datawriter'',''db_denydatareader'',''db_denydatawriter'',''TargetServersRole'',''SQLAgentUserRole'',''SQLAgentReaderRole'',''SQLAgentOperatorRole'',''DatabaseMailUserRole'',''db_ssisadmin'',''db_ssisltduser'',''db_ssisoperator'',''dc_operator'',''dc_admin'',''dc_proxy'',''PolicyAdministratorRole'',''ServerGroupAdministratorRole'',''ServerGroupReaderRole'',''UtilityCMRReader'',''UtilityIMRWriter'',''UtilityIMRReader'')'
ELSE
EXEC sp_executesql N'SELECT * FROM (
SELECT ''master'' as DatabaseName, name as RoleName, case WHEN [issqlrole] = 1 THEN ''DATABASE ROLE'' WHEN [isapprole] = 1 THEN ''APPLICATION ROLE'' ELSE NULL END as type_desc FROM [master].[dbo].[sysusers] WHERE [issqlrole]=1 OR [isapprole]=1
UNION ALL
SELECT ''msdb'' as DatabaseName, name as RoleName, case WHEN [issqlrole] = 1 THEN ''DATABASE ROLE'' WHEN [isapprole] = 1 THEN ''APPLICATION ROLE'' ELSE NULL END as type_desc FROM msdb.[dbo].[sysusers] WHERE [issqlrole]=1 OR [isapprole]=1
UNION ALL
SELECT ''model'' as DatabaseName, name as RoleName, case WHEN [issqlrole] = 1 THEN ''DATABASE ROLE'' WHEN [isapprole] = 1 THEN ''APPLICATION ROLE'' ELSE NULL END as type_desc FROM model.[dbo].[sysusers] WHERE [issqlrole]=1 OR [isapprole]=1
) as t
WHERE RoleName NOT IN (''public'',''db_owner'',''db_accessadmin'',''db_securityadmin'',''db_ddladmin'',''db_backupoperator'',''db_datareader'',''db_datawriter'',''db_denydatareader'',''db_denydatawriter'',''TargetServersRole'',''SQLAgentUserRole'',''SQLAgentReaderRole'',''SQLAgentOperatorRole'',''DatabaseMailUserRole'',''db_ssisadmin'',''db_ssisltduser'',''db_ssisoperator'',''dc_operator'',''dc_admin'',''dc_proxy'',''PolicyAdministratorRole'',''ServerGroupAdministratorRole'',''ServerGroupReaderRole'',''UtilityCMRReader'',''UtilityIMRWriter'',''UtilityIMRReader'')'


--9 credentials
IF @MajorVersion >= 10
EXEC sp_executesql N'SELECT name, credential_identity
FROM sys.credentials
ORDER BY NAME'
ELSE
SELECT cast(NULL as sysname) as name, cast(NULL as sysname) as credential_identity 
WHERE 1=2

--10 replication
IF @MajorVersion >= 10
EXEC sp_executesql N'SELECT name, is_published, is_subscribed, is_distributor
FROM sys.databases
WHERE is_published = 1
OR is_subscribed = 1
OR is_distributor = 1'
ELSE
EXEC sp_executesql N'SELECT name, 0 as is_published, 0 as is_subscribed, 0 as is_distributor FROM master..sysdatabases'

--11 distributor agent profiles
IF OBJECT_ID('msdb.dbo.MSagent_profiles') IS NOT NULL
	EXEC sp_executesql N'SELECT profile_name FROM msdb.dbo.MSagent_profiles WHERE def_profile=0'
ELSE
	SELECT cast('No Replication Agent Profiles' as sysname) as profile_name

--12 SSIS packages
SELECT CAST('Check file system with "dir *.dts /s /b"' as nvarchar(256)) as name, CAST('File System' as sysname) as location
INTO #ssispackages

IF OBJECT_ID('msdb.dbo.sysdtspackages') IS NOT NULL
exec sp_executesql N'INSERT INTO #ssispackages(name, Location)
SELECT name, ''sysdtspackages'' from msdb.dbo.sysdtspackages'

IF OBJECT_ID('msdb.dbo.sysdtspackages90') IS NOT NULL
exec sp_executesql N'INSERT INTO #ssispackages(name, Location)
SELECT name, ''sysdtspackages90'' from msdb.dbo.sysdtspackages90'

IF OBJECT_ID('msdb.dbo.sysssispackages') IS NOT NULL
exec sp_executesql N'INSERT INTO #ssispackages(name, Location)
SELECT name, ''sysssispackages'' from msdb.dbo.sysssispackages'

IF OBJECT_ID('SSISDB.catalog.packages ') IS NOT NULL
exec sp_executesql N'INSERT INTO #ssispackages(name, Location)
SELECT name, ''SSISDB'' from SSISDB.catalog.packages '

SELECT name, location FROM #ssispackages
DROP TABLE #ssispackages

--15 custom sp_configure
DECLARE @CpuPhysicalCores INT
DECLARE @CpuVirtualCores INT
DECLARE @MemTotalRamMb INT
DECLARE @MemSqlRamMb INT
DECLARE @MemAppRamMb INT
DECLARE @MemOSRamMb INT
DECLARE @MinimumSQLRamMb INT
DECLARE @tempDbFiles TINYINT
 
SELECT @MinimumSQLRamMb = CASE
        WHEN @MajorVersion < 12 THEN 1000 --SQL 2012 or earlier minimum requirements is 1GB
        WHEN @MajorVersion = 12 THEN 4096 --SQL 2014 minimum requirements is 4GB
        END
 
--change @MemAppRamMb to include application requirements. 0 assumes dedicated SQL server.
SET @MemAppRamMb = 0
SET @MemOSRamMb = 1000 --minimum for Windows OS
SET @MajorVersion = CAST(SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(5)),1,CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(5)))-1) AS TINYINT)
 
--Prior to SQL 2012 buffer pool (max server memory) didnt include CLR and lots of other things so more RAM needs to be given for OS.
SELECT @MemAppRamMb = CASE
                    WHEN @MajorVersion >= 11 THEN 0 --SQL 2012
                    ELSE 1000 END
 
IF @MajorVersion <= 8
BEGIN
	EXEC sp_executesql
	N'CREATE TABLE #TempTable (  
	[Index] VARCHAR(256),   
	Name  VARCHAR(256),                             
	Internal_Value VARCHAR(256),  
	Character_Value VARCHAR(256))  

	INSERT INTO #TempTable  
	EXEC xp_msver

	SELECT @MemTotalRamMbOut = (SELECT Internal_Value From #TempTable WHERE Name = ''PhysicalMemory'')
		  ,@CpuPhysicalCoresOut = (SELECT Internal_Value From #TempTable WHERE Name = ''ProcessorCount'')
		  ,@CpuVirtualCoresOut = (SELECT Internal_Value From #TempTable WHERE Name = ''ProcessorCount'')'
		,N'@MemTotalRamMbOut int output, @CpuPhysicalCoresOut int output, @CpuVirtualCoresOut int output'
    ,@MemTotalRamMbOut = @MemTotalRamMb output, @CpuPhysicalCoresOut = @CpuPhysicalCores output, @CpuVirtualCoresOut = @CpuVirtualCores output
END

IF @MajorVersion >= 9 AND @MajorVersion < 11
BEGIN
	EXEC sp_executesql N'SELECT @MemTotalRamMbOut = physical_memory_in_bytes/1024./1024.
		,@CpuPhysicalCoresOut = cpu_count
		, @CpuVirtualCoresOut = cpu_count - hyperthread_ratio
	FROM master.sys.dm_os_sys_info;'
	,N'@MemTotalRamMbOut int output, @CpuPhysicalCoresOut int output, @CpuVirtualCoresOut int output'
	,@MemTotalRamMbOut = @MemTotalRamMb output, @CpuPhysicalCoresOut = @CpuPhysicalCores output, @CpuVirtualCoresOut = @CpuVirtualCores output
END

IF @MajorVersion >= 11 --SQL 2012 onwards has different column name (physical_memory_kb rather than physical_memory_in_bytes)
BEGIN
	EXEC sp_executesql N'SELECT @MemTotalRamMbOut = physical_memory_kb/1024.
		,@CpuPhysicalCoresOut = cpu_count
		, @CpuVirtualCoresOut = cpu_count - hyperthread_ratio
	FROM master.sys.dm_os_sys_info;'
	,N'@MemTotalRamMbOut int output, @CpuPhysicalCoresOut int output, @CpuVirtualCoresOut int output'
	,@MemTotalRamMbOut = @MemTotalRamMb output, @CpuPhysicalCoresOut = @CpuPhysicalCores output, @CpuVirtualCoresOut = @CpuVirtualCores output
END
 
SELECT @tempDbFiles = CASE WHEN @CpuPhysicalCores < 4 THEN 4 ELSE @CpuPhysicalCores END
	,@MemSqlRamMb = @MemTotalRamMb
        - @MemOSRamMb --deduct memory for OS
        - @MemAppRamMb --deduct memory for applications
        - CASE --deduct for memory required to manage server RAM
        WHEN @MemTotalRamMb < 16000 THEN CEILING(@MemTotalRamMb / 6. /1000.) * 1000 --1GB to manage every 6GB (4) up to 16GB
        WHEN @MemTotalRamMb >= 16000 THEN 2500 + (CEILING((@MemTotalRamMb - 16000) / 12. /1000.) * 1000) --1GB to manage every 12GB (8) over 16GB
        END
 
IF @MemSqlRamMb < @MinimumSQLRamMb --cant have less than minimum memory requirement for SQL
BEGIN
	SET @MemSqlRamMb = @MinimumSQLRamMb
END
 
 
CREATE TABLE ##configs (
        name nvarchar(35),
        target_value sql_variant)
 
INSERT INTO ##configs(name,target_value)
SELECT 'access check cache bucket count','0'
UNION ALL SELECT 'access check cache quota','0'
UNION ALL SELECT 'Ad Hoc Distributed Queries','0'
UNION ALL SELECT 'affinity I/O mask','0'
UNION ALL SELECT 'affinity mask','0'
UNION ALL SELECT 'affinity64 I/O mask','0'
UNION ALL SELECT 'affinity64 mask','0'
--UNION ALL SELECT 'Agent XPs','1' --default 0. ignore as set by SQL Agent Service
UNION ALL SELECT 'allow updates','0'
UNION ALL SELECT 'backup checksum default','0'
UNION ALL SELECT 'backup compression default','1' --default 0
UNION ALL SELECT 'blocked process threshold (s)','5' --default 0
UNION ALL SELECT 'c2 audit mode','0'
UNION ALL SELECT 'clr enabled','1' --default 0
UNION ALL SELECT 'common criteria compliance enabled','0'
UNION ALL SELECT 'contained database authentication','0'
UNION ALL SELECT 'cost threshold for parallelism','5'
UNION ALL SELECT 'cross db ownership chaining','0'
UNION ALL SELECT 'cursor threshold','-1'
UNION ALL SELECT 'Database Mail XPs','0' --default 0
UNION ALL SELECT 'default full-text language','1033'
UNION ALL SELECT 'default language','0'
UNION ALL SELECT 'default trace enabled','1'
UNION ALL SELECT 'disallow results from triggers','0'
UNION ALL SELECT 'EKM provider enabled','0'
UNION ALL SELECT 'filestream access level','1'
UNION ALL SELECT 'fill factor (%)','0'
UNION ALL SELECT 'ft crawl bandwidth (max)','100'
UNION ALL SELECT 'ft crawl bandwidth (min)','0'
UNION ALL SELECT 'ft notify bandwidth (max)','100'
UNION ALL SELECT 'ft notify bandwidth (min)','0'
UNION ALL SELECT 'index create memory (KB)','0'
UNION ALL SELECT 'in-doubt xact resolution','0'
UNION ALL SELECT 'lightweight pooling','0'
UNION ALL SELECT 'locks','0'
UNION ALL SELECT 'max degree of parallelism',@CpuPhysicalCores --default 0
UNION ALL SELECT 'max full-text crawl range','4'
UNION ALL SELECT 'max server memory (MB)',@MemSqlRamMb --default 2147483647
UNION ALL SELECT 'max text repl size (B)','65536'
UNION ALL SELECT 'max worker threads','0'
UNION ALL SELECT 'media retention','0'
UNION ALL SELECT 'min memory per query (KB)','1024'
UNION ALL SELECT 'min server memory (MB)','0'--consider @MinimumSQLRamMb
UNION ALL SELECT 'nested triggers','1'
UNION ALL SELECT 'network packet size (B)','4096'
UNION ALL SELECT 'Ole Automation Procedures','0'
UNION ALL SELECT 'open objects','0'
UNION ALL SELECT 'optimize for ad hoc workloads','1' --default 0
UNION ALL SELECT 'PH timeout (s)','60'
UNION ALL SELECT 'precompute rank','0'
UNION ALL SELECT 'priority boost','0'
UNION ALL SELECT 'query governor cost limit','0'
UNION ALL SELECT 'query wait (s)','-1'
UNION ALL SELECT 'recovery interval (min)','0'
UNION ALL SELECT 'remote access','1'
UNION ALL SELECT 'remote admin connections','1' --default 0
UNION ALL SELECT 'remote login timeout (s)','10'
UNION ALL SELECT 'remote proc trans','0'
UNION ALL SELECT 'remote query timeout (s)','600'
UNION ALL SELECT 'Replication XPs','0'
UNION ALL SELECT 'scan for startup procs','1'
UNION ALL SELECT 'server trigger recursion','1'
UNION ALL SELECT 'set working set size','0'
UNION ALL SELECT 'show advanced options','1' --default 0
UNION ALL SELECT 'SMO and DMO XPs','1'
UNION ALL SELECT 'transform noise words','0'
UNION ALL SELECT 'two digit year cutoff','2049'
UNION ALL SELECT 'user connections','0'
UNION ALL SELECT 'user options','0'
UNION ALL SELECT 'xp_cmdshell','0'

IF @MajorVersion < 10
EXEC sp_executesql
	N'SELECT s.name
	,sc.value as Value
	,s.low as Minimum
	,s.High as Maximum
	,s.name as [Description]
	,cast(NULL as bit) as is_dynamic
	,cast(NULL as bit) as is_advanced
	,c.target_value as target_value
FROM master.dbo.spt_values as s
	INNER JOIN master.dbo.sysconfigures sc
		ON s.number = sc.config
	INNER JOIN master.dbo.syscurconfigs r
		ON s.number = r.config
    INNER JOIN ##configs as c
		ON s.name = c.name
WHERE sc.Value <> c.target_value
AND s.type = ''C''
ORDER BY LOWER(s.name)'

ELSE
EXEC sp_executesql
N'SELECT s.Name
        ,s.Value
        ,s.Minimum
        ,s.Maximum
        ,s.[Description]
        ,s.is_dynamic
        ,s.is_advanced
        ,c.target_value
FROM sys.configurations as s
    INNER JOIN ##configs as c
		ON s.name = c.name
WHERE s.Value <> c.target_value'
DROP TABLE ##configs

--24 proxy accounts
IF @MajorVersion >= 10
EXEC sp_executesql
	N'SELECT p.name as ProxyName, c.name as CredentialName
FROM msdb.dbo.sysproxies as p
	LEFT OUTER JOIN sys.credentials as c
		ON p.credential_id = c.credential_id'
ELSE
SELECT CAST(NULL as sysname) as ProxyName, CAST(NULL as sysname) as CredentialName
WHERE 1=2

--28 Database Mail settings
IF @MajorVersion >= 10
EXEC sp_executesql
	N'SELECT p.name AS ProfileName, a.name as AccountName
FROM msdb.dbo.sysmail_profile as p
	JOIN msdb.dbo.sysmail_profileaccount as pa
		ON p.profile_id = pa.profile_id
	JOIN msdb.dbo.sysmail_account as a
		ON pa.account_id = a.account_id'
ELSE 
SELECT CAST(NULL as sysname) as ProfileName, CAST(NULL as sysname) as AccountName
WHERE 1=2

--29 data collector & MDW
IF @MajorVersion >= 10
EXEC sp_executesql
	N'SELECT parameter_name, parameter_value
FROM msdb.dbo.syscollector_config_store'
ELSE 
SELECT CAST(NULL as nvarchar(128)) as parameter_name, CAST(NULL as sql_variant) as parameter_value
WHERE 1=2


--30 Server level triggers
IF @MajorVersion >= 11
EXEC sp_executesql
	N'SELECT name as ServerTrigger
FROM master.[sys].[server_triggers]'
ELSE
SELECT CAST(NULL as sysname) as name
WHERE 1=2

--31 certificates
IF @MajorVersion >= 11
EXEC sp_executesql
	N'SELECT name
FROM master.sys.certificates
WHERE name NOT LIKE ''##%''
UNION 
SELECT ''check Windows certificate store'''
ELSE
SELECT CAST(NULL as sysname) as name
WHERE 1=2

--32 system database objects
IF @MajorVersion < 10
EXEC sp_executesql N'SELECT DatabaseName,
	name,
	CASE xtype
		WHEN ''AF'' THEN ''Aggregate function (CLR)''
		WHEN ''C'' THEN ''CHECK constraint''
		WHEN ''D'' THEN ''Default or DEFAULT constraint''
		WHEN ''F'' THEN ''FOREIGN KEY constraint''
		WHEN ''FN'' THEN ''Scalar function''
		WHEN ''FS'' THEN ''Assembly (CLR) scalar-function''
		WHEN ''FT'' THEN ''Assembly (CLR) table-valued function''
		WHEN ''IF'' THEN ''In-lined table-function''
		WHEN ''IT'' THEN ''Internal table''
		WHEN ''L'' THEN ''Log''
		WHEN ''P'' THEN ''Stored procedure''
		WHEN ''PC'' THEN ''Assembly (CLR) stored-procedure''
		WHEN ''PK'' THEN ''PRIMARY KEY constraint (type is K)''
		WHEN ''RF'' THEN ''Replication filter stored procedure''
		WHEN ''S'' THEN ''System table''
		WHEN ''SN'' THEN ''Synonym''
		WHEN ''SQ'' THEN ''Service queue''
		WHEN ''TA'' THEN ''Assembly (CLR) DML trigger''
		WHEN ''TF'' THEN ''Table function''
		WHEN ''TR'' THEN ''SQL DML Trigger''
		WHEN ''TT'' THEN ''Table type''
		WHEN ''U'' THEN ''User table''
		WHEN ''UQ'' THEN ''UNIQUE constraint (type is K)''
		WHEN ''V'' THEN ''View''
		WHEN ''X'' THEN ''Extended stored procedure''
	END as type_desc
FROM (
SELECT ''master'' as DatabaseName, name, xtype FROM master.dbo.sysobjects WHERE OBJECTPROPERTY(id, ''IsMSShipped'') = 0 
UNION ALL
SELECT ''msdb'' as DatabaseName, name, xtype FROM msdb.dbo.sysobjects WHERE OBJECTPROPERTY(id, ''IsMSShipped'') = 0 AND name NOT IN (''sysdtslog90'')
UNION ALL
SELECT ''model'' as DatabaseName, name, xtype FROM model.dbo.sysobjects WHERE OBJECTPROPERTY(id, ''IsMSShipped'') = 0 
) as t'
ELSE
EXEC sp_executesql
	N'SELECT ''master'' as DatabaseName, name, type_desc FROM master.sys.objects WHERE is_ms_shipped = 0
UNION ALL
SELECT ''msdb'' as DatabaseName, name, type_desc FROM msdb.sys.objects WHERE is_ms_shipped = 0 AND name NOT IN (''sysdtslog90'')
UNION ALL
SELECT ''model'' as DatabaseName, name, type_desc FROM model.sys.objects WHERE is_ms_shipped = 0'

--33 SQL Agent Properties
--unreliable. doesnt work on sqlexpress or if the security is locked down.
--exec msdb.dbo.sp_get_sqlagent_properties

--34 SQL agent jobs
SELECT j.job_id
	,j.name
	,SUM(CASE WHEN js.subsystem ='ActiveScripting' THEN 1 ELSE 0 END) AS ActiveX
	,SUM(CASE WHEN js.subsystem ='CmdExec' THEN 1 ELSE 0 END) AS CmdExec
	,SUM(CASE WHEN js.subsystem ='SSIS' THEN 1 ELSE 0 END) AS SSIS
	,SUM(CASE WHEN js.subsystem ='TSQL' THEN 1 ELSE 0 END) AS [TSQL]
	,SUM(CASE WHEN js.subsystem ='ANALYSISCOMMAND' THEN 1 ELSE 0 END) AS ANALYSISCOMMAND
	,SUM(CASE WHEN js.subsystem ='ANALYSISQUERY' THEN 1 ELSE 0 END) AS ANALYSISQUERY
	,SUM(CASE WHEN js.subsystem Like 'Repl%' THEN 1 ELSE 0 END) AS [Replication]
FROM msdb.dbo.sysjobs as j
	left outer join
	msdb.dbo.sysjobsteps as js
		ON j.job_id = js.job_id
WHERE j.enabled = 1
AND j.category_id <> 3
GROUP BY j.job_id, j.name
ORDER BY j.name


--35 Resource Governor
IF @MajorVersion >= 10
EXEC sp_executesql N'SELECT SUM(CAST(is_enabled as int)) as is_enabled FROM sys.resource_governor_configuration'
ELSE
SELECT CAST(0 as int) as is_enabled


--36 Maintenance Plans
IF @MajorVersion < 10
exec sp_executesql N'select plan_name as name, plan_name as [description],[owner] from msdb.dbo.sysdbmaintplans'
ELSE
exec sp_executesql N'select name as MaintenancePlan ,[description] ,[owner] from msdb.dbo.sysmaintplan_plans'


--37 PBM
IF @MajorVersion >= 11 --table exists in 2008 but has no is_system column
exec sp_executesql N'
SELECT ''Condition'' AS PBM, Name
FROM msdb.dbo.syspolicy_conditions where is_system = 0
UNION
SELECT ''Policy'' AS PBM, Name 
FROM msdb.dbo.syspolicy_policies where is_system = 0'
ELSE
SELECT '' as PBM, CAST(NULL as sysname) as Name
WHERE 1 = 2

--38 server collation
IF @MajorVersion < 10
exec sp_executesql N'SELECT name
	,''Instance is ''+(SELECT TOP 1 COLLATION_NAME
	FROM master.INFORMATION_SCHEMA.COLUMNS
	WHERE COLUMN_NAME=''name''
	AND TABLE_NAME=''syslogins''
	) as collation_name, 0 as is_trustworthy_on, 0 as is_cdc_enabled, 0 as is_encrypted
FROM master.dbo.sysdatabases'
ELSE
exec sp_executesql N'SELECT name, collation_name, is_trustworthy_on, is_cdc_enabled, is_encrypted
FROM sys.databases'


--42 Server authentication
--& 43 login auditing
DECLARE @LoginMode INT
DECLARE @AuditLevel INT
EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, @LoginMode OUTPUT, N'no_output'
EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel', REG_DWORD, @AuditLevel OUTPUT, N'no_output'

SELECT CASE @LoginMode
		WHEN 0 THEN 'None'
		WHEN 2 THEN 'Failed logins only (default)'
		WHEN 1 THEN 'Successful logins only'
		WHEN 3 THEN 'Both failed and successful logins'
		END as LoginMode
	,CASE @AuditLevel
		WHEN 0 THEN 'Windows authentication mode (default)'
		WHEN 1 THEN 'SQL Server and Windows authentication mode'
	END as AuditLevel

--44 Server proxy enabled
IF @MajorVersion < 10
SELECT CAST(NULL as sysname) as CmdshellProxyAccount
WHERE 1=2
ELSE
exec sp_executesql N'
SELECT credential_identity as CmdshellProxyAccount
FROM sys.credentials
WHERE name = ''##xp_cmdshell_proxy_account##'''

--57 server audits
IF @MajorVersion < 11
SELECT CAST(NULL as sysname) as AuditSpecificationName
WHERE 1=2
ELSE
exec sp_executesql N'SELECT name as AuditSpecificationName FROM msdb.sys.server_audit_specifications'

IF @MajorVersion < 11
SELECT CAST(NULL as sysname) as AuditName
WHERE 1=2
ELSE
exec sp_executesql N'SELECT name as AuditName FROM msdb.sys.server_audits'

--58 trace flags
DBCC TRACESTATUS

--59 model database changes
IF @MajorVersion >= 10
exec sp_executesql N'SELECT d.file_id
	,d.physical_name
	,d.type_desc
	,LTRIM(CASE WHEN d.size = -1 THEN ''Unlimited'' ELSE str(d.size/128.0) END) AS [File Size (MB)]
	,LTRIM(CASE WHEN d.max_size = -1 THEN ''Unlimited'' ELSE str(d.max_size/128.0) END) AS [Max File Size (MB)]
	,LTRIM(CASE WHEN d.is_percent_growth = 1 THEN STR(d.growth)+''%'' ELSE STR(d.growth/128.0)+''MB'' END) [File Size (MB)]
	,DATABASEPROPERTYEX(''model'',''Recovery'') as RecoveryModel
	,CASE WHEN isnull(defaultsettings.size,536) = d.size THEN 0 ELSE 1 END as size_difference
	,CASE WHEN isnull(defaultsettings.max_size,-1) = d.max_size  THEN 0 ELSE 1 END as maxSize_difference
	,CASE WHEN isnull(defaultsettings.name,-1) = d.name THEN 0 ELSE 1 END as LogicalName_difference
	,CASE WHEN isnull(defaultsettings.growth,131072) = d.growth THEN 0 ELSE 1 END as GrowthValue_difference
	,CASE WHEN isnull(defaultsettings.is_percent_growth,0) = d.is_percent_growth THEN 0 ELSE 1 END as MBvPercentGrowth_difference
	,CASE WHEN isnull(defaultsettings.RecoveryModel,'''') = DATABASEPROPERTYEX(''model'',''Recovery'') THEN 0 ELSE 1 END as RecoveryModel_difference
FROM model.sys.database_files as d
	LEFT OUTER JOIN
	(SELECT 1 as file_id, 536 as size, -1 as max_size, ''modeldev'' as name, 131072 as growth, 0 as is_percent_growth, ''FULL'' as RecoveryModel
	UNION ALL
	SELECT 2 as file_id, 536 as size, -1 as max_size, ''modellog'' as name, 131072 as growth, 0 as is_percent_growth, ''FULL'' as RecoveryModel
	) as defaultsettings
		ON d.file_id = defaultsettings.file_id
WHERE isnull(defaultsettings.size,536) <> d.size
OR	  isnull(defaultsettings.max_size,-1) <> d.max_size
OR	  isnull(defaultsettings.name,-1) <> d.name
OR	  isnull(defaultsettings.growth,131072) <> d.growth
OR	  isnull(defaultsettings.is_percent_growth,0) <> d.is_percent_growth
OR	  isnull(defaultsettings.RecoveryModel,'''') <> DATABASEPROPERTYEX(''model'',''Recovery'')'
ELSE
exec sp_executesql N'SELECT d.fileid
	,d.filename as physical_name
	,CASE WHEN d.groupid=0 THEN ''LOG'' ELSE ''DATA'' END as type_desc
	,LTRIM(CASE WHEN d.size = -1 THEN ''Unlimited'' ELSE str(d.size/128.0) END) AS [File Size (MB)]
	,LTRIM(CASE WHEN d.maxsize = -1 THEN ''Unlimited'' ELSE str(d.maxsize/128.0) END) AS [Max File Size (MB)]
	,LTRIM(CASE WHEN d.growth BETWEEN 0 AND 100 THEN STR(d.growth)+''%'' ELSE STR(d.growth/128.0)+''MB'' END) [File Size (MB)]
	,DATABASEPROPERTYEX(''model'',''Recovery'') as RecoveryModel
	,CASE WHEN isnull(defaultsettings.size,536) = d.size THEN 0 ELSE 1 END as size_difference
	,CASE WHEN isnull(defaultsettings.max_size,-1) = d.maxsize  THEN 0 ELSE 1 END as maxSize_difference
	,CASE WHEN isnull(defaultsettings.name,-1) = d.name THEN 0 ELSE 1 END as LogicalName_difference
	,CASE WHEN isnull(defaultsettings.growth,131072) = d.growth THEN 0 ELSE 1 END as GrowthValue_difference
	,0 as MBvPercentGrowth_difference
	,CASE WHEN isnull(defaultsettings.RecoveryModel,'''') = DATABASEPROPERTYEX(''model'',''Recovery'') THEN 0 ELSE 1 END as RecoveryModel_difference
FROM model.dbo.sysfiles as d
	LEFT OUTER JOIN
	(SELECT 1 as fileid, 536 as size, -1 as max_size, ''modeldev'' as name, 131072 as growth, 0 as is_percent_growth, ''FULL'' as RecoveryModel
	UNION ALL
	SELECT 2 as fileid, 536 as size, -1 as max_size, ''modellog'' as name, 131072 as growth, 0 as is_percent_growth, ''FULL'' as RecoveryModel
	) as defaultsettings
		ON d.fileid = defaultsettings.fileid
WHERE isnull(defaultsettings.size,536) <> d.size
OR	  isnull(defaultsettings.max_size,-1) <> d.maxsize
OR	  isnull(defaultsettings.name,-1) <> d.name
OR	  isnull(defaultsettings.growth,131072) <> d.growth
--OR	  isnull(defaultsettings.is_percent_growth,0) <> d.is_percent_growth
OR	  isnull(defaultsettings.RecoveryModel,'''') <> DATABASEPROPERTYEX(''model'',''Recovery'')'

