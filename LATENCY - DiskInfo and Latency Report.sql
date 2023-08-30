-- ======================
-- Show disk file latency
-- ======================

/*           
http://www.sqlskills.com/BLOGS/PAUL/category/IO-Subsystems.aspx
*/

SELECT 
    --virtual file latency
    ReadLatency = CASE WHEN num_of_reads = 0
        THEN 0 ELSE (io_stall_read_ms / num_of_reads) END,
    WriteLatency = CASE WHEN num_of_writes = 0 
        THEN 0 ELSE (io_stall_write_ms / num_of_writes) END,
    Latency = CASE WHEN (num_of_reads = 0 AND num_of_writes = 0)
        THEN 0 ELSE (io_stall / (num_of_reads + num_of_writes)) END,
    --avg bytes per IOP
    AvgBPerRead = CASE WHEN num_of_reads = 0 
        THEN 0 ELSE (num_of_bytes_read / num_of_reads) END,
    AvgBPerWrite = CASE WHEN io_stall_write_ms = 0 
        THEN 0 ELSE (num_of_bytes_written / num_of_writes) END,
    AvgBPerTransfer = CASE WHEN (num_of_reads = 0 AND num_of_writes = 0)
        THEN 0 ELSE ((num_of_bytes_read + num_of_bytes_written) / 
            (num_of_reads + num_of_writes)) END,  
                                  num_of_reads,
                                  num_of_writes,
    LEFT (mf.physical_name, 2) AS Drive,
    DB_NAME (vfs.database_id) AS DB,
    mf.physical_name
FROM sys.dm_io_virtual_file_stats (NULL,NULL) AS vfs
JOIN sys.master_files AS mf
    ON vfs.database_id = mf.database_id
    AND vfs.file_id = mf.file_id
--WHERE vfs.file_id = 2 -- log files
ORDER BY DB DESC;

GO

SELECT 
                DB_NAME(f.database_id) AS [Database],              
                CASE m.type_desc WHEN 'ROWS' THEN 'DATA' ELSE 'LOG' END AS [File type],
                CASE WHEN num_of_reads = 0 THEN 0 ELSE CAST(((io_stall_read_ms * 1.0) / num_of_reads) AS decimal(16,4)) END AS [Read Latency ms],
                CASE WHEN num_of_writes = 0 THEN 0 ELSE CAST(((io_stall_write_ms * 1.0)/ num_of_writes) AS decimal(16,4)) END AS [Write Latency ms],
                num_of_reads AS [Reads],
                num_of_writes AS [Writes],
                m.physical_name AS [Filename]
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS f
JOIN sys.master_files AS m
    ON f.database_id = m.database_id
    AND f.file_id = m.file_id
WHERE DB_NAME(f.database_id) = 'WriteLogDemo'
ORDER BY f.database_id;
