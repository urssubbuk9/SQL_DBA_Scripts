--Query to display recent Data and TLog file autogrowth and autoshrink events
--for all databases on the instance. Based on query used by the SSMS Standard
--Report named "Disk Usage" which has a section that displays this data. Data
--is retrieved from the default trace.

--Works for SQL 2005 and above.

-- https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-trace-setevent-transact-sql?view=sql-server-2017

-- https://docs.microsoft.com/en-us/sql/relational-databases/event-classes/objecttype-trace-event-column?view=sql-server-ver15

--

USE [master]
GO

BEGIN TRY
    IF (SELECT CONVERT(INT,value_in_use) FROM sys.configurations WHERE NAME = 'default trace enabled') = 1
    BEGIN
        DECLARE @curr_tracefilename VARCHAR(500);
        DECLARE @base_tracefilename VARCHAR(500);
        DECLARE @indx INT;

        SELECT @curr_tracefilename = path FROM sys.traces WHERE is_default = 1;
        SET @curr_tracefilename = REVERSE(@curr_tracefilename);
        SELECT @indx  = PATINDEX('%\%', @curr_tracefilename) ;
        SET @curr_tracefilename = REVERSE(@curr_tracefilename) ;
        SET @base_tracefilename = LEFT( @curr_tracefilename,LEN(@curr_tracefilename) - @indx) + '\log.trc'; 
        SELECT
            --(DENSE_RANK() OVER (ORDER BY StartTime DESC))%2 AS l1,
            ServerName AS [SQL_Instance],
            --CONVERT(INT, EventClass) AS EventClass,
            DatabaseName AS [Database_Name],
            Filename AS [Logical_File_Name],
            (Duration/1000) AS [Duration_MS],
            CONVERT(VARCHAR(50),StartTime, 100) AS [Start_Time],
            --EndTime,
            CAST((IntegerData*8.0/1024) AS DECIMAL(19,2)) AS [Change_In_Size_MB],
    		LoginName,
    		SPID

        FROM ::fn_trace_gettable(@base_tracefilename, default)
        WHERE
            EventClass >=  92
            AND EventClass <=  95
            --AND ServerName = @@SERVERNAME
            --AND DatabaseName = 'myDBName'  
        ORDER BY DatabaseName, StartTime DESC;  
    END    
    ELSE   
        SELECT -1 AS l1,
        0 AS EventClass,
        0 DatabaseName,
        0 AS Filename,
        0 AS Duration,
        0 AS StartTime,
        0 AS EndTime,
        0 AS ChangeInSize 
END TRY 
BEGIN CATCH 
    SELECT -100 AS l1,
    ERROR_NUMBER() AS EventClass,
    ERROR_SEVERITY() DatabaseName,
    ERROR_STATE() AS Filename,
    ERROR_MESSAGE() AS Duration,
    1 AS StartTime, 
    1 AS EndTime,
    1 AS ChangeInSize 
END CATCH
