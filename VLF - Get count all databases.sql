--NOT A SOURCE but useful link: https://www.sqlskills.com/blogs/kimberly/transaction-log-vlfs-too-many-or-too-few/


-- Log history  : 
--                  2019-08-01  RAG - Added TRY-CATCH to ignore databases where LOGINFO can't run
--                                  - Replaced @vlfcounts for @loginfo, which also gets file size in MB

-- =========================
-- Get VLF count for all dbs
-- =========================

DECLARE 
       @query varchar(1000),
       @dbname sysname,
       @vlfs int,
       @MajorVersion tinyint;
  
DECLARE @databases	TABLE (dbname sysname);  
--DECLARE @vlfcounts	TABLE (dbname sysname,  vlfcount int);  
DECLARE @loginfo	TABLE (dbname sysname,  vlfcount int, size_mb int);  

INSERT INTO @databases  
SELECT [name] FROM sys.databases WHERE [state] = 0;

SET @MajorVersion = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)))-1);

IF (@MajorVersion < 11) -- pre-SQL2012 
BEGIN 
    DECLARE @dbccloginfo TABLE  
    (  
        fileid tinyint,  
        file_size bigint,  
        start_offset bigint,  
        fseqno int,  
        [status] tinyint,  
        parity tinyint,  
        create_lsn numeric(25,0)  
    );  
  
    WHILE EXISTS(SELECT TOP 1 dbname FROM @databases)  
    BEGIN  
        SET @dbname = (SELECT TOP 1 dbname FROM @databases);
        SET @query = 'DBCC LOGINFO (' + '''' + @dbname + ''') ';  
  
		DELETE @dbccloginfo

        BEGIN TRY
			INSERT INTO @dbccloginfo  
			EXEC (@query);  
						
			INSERT @loginfo  
			SELECT @dbname, COUNT(*), CEILING(SUM(file_size) / 1024. / 1024)
			FROM @dbccloginfo
		END TRY
		BEGIN CATCH
		END CATCH
  
        DELETE FROM @databases WHERE dbname = @dbname; 
    END 
END 
ELSE 
BEGIN 
    DECLARE @dbccloginfo2012 TABLE  
    (  
        RecoveryUnitId int, 
        fileid tinyint,  
        file_size bigint,  
        start_offset bigint,  
        fseqno int,  
        [status] tinyint,  
        parity tinyint,  
        create_lsn numeric(25,0)  
    );
  
    WHILE EXISTS(SELECT TOP 1 dbname FROM @databases)  
    BEGIN  
        SET @dbname = (SELECT TOP 1 dbname FROM @databases);  
        SET @query = 'DBCC LOGINFO (' + '''' + @dbname + ''') ';  
	
		DELETE @dbccloginfo2012
	
        BEGIN TRY
			INSERT INTO @dbccloginfo2012  
			EXEC (@query);  

			SET @vlfs = @@ROWCOUNT;  
  
			INSERT @loginfo  
			SELECT @dbname, COUNT(*), CEILING(SUM(file_size) / 1024. / 1024)
			FROM @dbccloginfo2012
		END TRY
		BEGIN CATCH
		END CATCH
  
  
        DELETE FROM @databases WHERE dbname = @dbname;  
    END
END 
  
SELECT 
       dbname, 
       vlfcount,
	   size_mb
FROM @loginfo  
ORDER BY vlfcount DESC;
