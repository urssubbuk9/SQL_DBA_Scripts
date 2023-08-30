-- =======================
-- Virtual Log Files (VLF)
-- =======================
-- Uses Template Parameters (Ctrl-Shift-M)
-- Check db first to find the logical filename and current size you want to shrink

EXEC sp_helpdb [];

USE [<Database_Name, sysname, >];

DBCC LOGINFO;

DBCC SHRINKFILE (N'<Logical_File, sysname, >' , 0, TRUNCATEONLY)
GO

DECLARE 
       @StartingSize int = <Initial_size_MB, int, 4000>,
       @FinalSize    int = <Final_size_MB, int, >,
       @Growth       int = <Growth_increment_MB, int, 8000>,
       @Msg          varchar(500)

WHILE (@StartingSize < @FinalSize)
BEGIN
       PRINT 'ALTER DATABASE [<Database_Name, sysname, >] MODIFY FILE ( NAME = N''<Logical_File, sysname, >'', SIZE = ' + CONVERT(varchar(11), @StartingSize) + 'MB)';
       SET @Msg = 'increased size to ' + CONVERT(varchar(11), @StartingSize) + 'MB';
       PRINT 'PRINT ''' + @Msg + '''';
       PRINT 'WAITFOR DELAY ''00:00:10''';
       PRINT 'GO';
       PRINT '';
       SET @StartingSize = @StartingSize + @Growth; 
END

-- Final
IF (@StartingSize <> @FinalSize)
BEGIN
       PRINT 'ALTER DATABASE [<Database_Name, sysname, >] MODIFY FILE ( NAME = N''<Logical_File, sysname, >'', SIZE = ' + CONVERT(varchar(11), @FinalSize) + 'MB)';
       SET @Msg = 'increased size to ' + CONVERT(varchar(11), @FinalSize) + 'MB';
       PRINT 'PRINT ''' + @Msg + '''';
       PRINT 'GO';
END
