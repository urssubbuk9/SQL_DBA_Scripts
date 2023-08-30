SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--=============================================
-- Copyright (C) 2019 Raul Gonzalez, @SQLDoubleG
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
-- Author:		Raul Gonzalez
-- Create date: 21/12/2019
-- Description:	Returns events from the system trace
--
-- Remarks:		This script is based on SPACE - Recent autogrowth and autoshrink events.sql
--				Values for temp table #events 
--					https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-trace-setevent-transact-sql?view=sql-server-2017
--				Values for temp table #objTypes
--					https://docs.microsoft.com/en-us/sql/relational-databases/event-classes/objecttype-trace-event-column?view=sql-server-ver15
--
-- Log History:	
--				21/12/2019 RAG - Created
--
-- =============================================

IF OBJECT_ID('tempdb..#events')		IS NOT NULL DROP TABLE #events
IF OBJECT_ID('tempdb..#objTypes')	IS NOT NULL DROP TABLE #objTypes

-- =============================================
-- DO NOT CHANGE THIS BLOCK
-- =============================================

CREATE TABLE #events (EventClass INT NOT NULL, EventName VARCHAR(128) NOT NULL, EventDescription VARCHAR(1000) NULL)

INSERT INTO #events (EventClass, EventName, EventDescription) VALUES
(0, 'Reserved','')
, (1, 'Reserved','')
, (2, 'Reserved','')
, (3, 'Reserved','')
, (4, 'Reserved','')
, (5, 'Reserved','')
, (6, 'Reserved','')
, (7, 'Reserved','')
, (8, 'Reserved','')
, (9, 'Reserved','Reserved')
, (10, 'RPC:Completed','Occurs when a remote procedure call (RPC) has completed.')
, (11, 'RPC:Starting','Occurs when an RPC has started.')
, (12, 'SQL:BatchCompleted','Occurs when a Transact-SQL batch has completed.')
, (13, 'SQL:BatchStarting','Occurs when a Transact-SQL batch has started.')
, (14, 'Audit Login','Occurs when a user successfully logs in to SQL Server.')
, (15, 'Audit Logout','Occurs when a user logs out of SQL Server.')
, (16, 'Attention','Occurs when attention events, such as client-interrupt requests or broken client connections, happen.')
, (17, 'ExistingConnection','Detects all activity by users connected to SQL Server before the trace started.')
, (18, 'Audit Server Starts and Stops','Occurs when the SQL Server service state is modified.')
, (19, 'DTCTransaction','Tracks Microsoft Distributed Transaction Coordinator (MS DTC) coordinated transactions between two or more databases.')
, (20, 'Audit Login Failed','Indicates that a login attempt to SQL Server from a client failed.')
, (21, 'EventLog','Indicates that events have been logged in the Windows application log.')
, (22, 'ErrorLog','Indicates that error events have been logged in the SQL Server error log.')
, (23, 'Lock:Released','Indicates that a lock on a resource, such as a page, has been released.')
, (24, 'Lock:Acquired','Indicates acquisition of a lock on a resource, such as a data page.')
, (25, 'Lock:Deadlock','Indicates that two concurrent transactions have deadlocked each other by trying to obtain incompatible locks on resources the other transaction owns.')
, (26, 'Lock:Cancel','Indicates that the acquisition of a lock on a resource has been canceled (for example, due to a deadlock).')
, (27, 'Lock:Timeout','Indicates that a request for a lock on a resource, such as a page, has timed out due to another transaction holding a blocking lock on the required resource. Time-out is determined by the @@LOCK_TIMEOUT function, and can be set with the SET LOCK_TIMEOUT statement.')
, (28, 'Degree of Parallelism Event (7.0 Insert)','Occurs before a SELECT, INSERT, or UPDATE statement is executed.')
, (29, 'Reserved','')
, (30, 'Reserved','')
, (31, 'Reserved','Use Event 28 instead.')
, (32, 'Reserved','Reserved')
, (33, 'Exception','Indicates that an exception has occurred in SQL Server.')
, (34, 'SP:CacheMiss','Indicates when a stored procedure is not found in the procedure cache.')
, (35, 'SP:CacheInsert','Indicates when an item is inserted into the procedure cache.')
, (36, 'SP:CacheRemove','Indicates when an item is removed from the procedure cache.')
, (37, 'SP:Recompile','Indicates that a stored procedure was recompiled.')
, (38, 'SP:CacheHit','Indicates when a stored procedure is found in the procedure cache.')
, (39, 'Deprecated','Deprecated')
, (40, 'SQL:StmtStarting','Occurs when the Transact-SQL statement has started.')
, (41, 'SQL:StmtCompleted','Occurs when the Transact-SQL statement has completed.')
, (42, 'SP:Starting','Indicates when the stored procedure has started.')
, (43, 'SP:Completed','Indicates when the stored procedure has completed.')
, (44, 'SP:StmtStarting','Indicates that a Transact-SQL statement within a stored procedure has started executing.')
, (45, 'SP:StmtCompleted','Indicates that a Transact-SQL statement within a stored procedure has finished executing.')
, (46, 'Object:Created','Indicates that an object has been created, such as for CREATE INDEX, CREATE TABLE, and CREATE DATABASE statements.')
, (47, 'Object:Deleted','Indicates that an object has been deleted, such as in DROP INDEX and DROP TABLE statements.')
, (48, 'Reserved','')
, (49, 'Reserved','')
, (50, 'SQL Transaction','Tracks Transact-SQL BEGIN, COMMIT, SAVE, and ROLLBACK TRANSACTION statements.')
, (51, 'Scan:Started','Indicates when a table or index scan has started.')
, (52, 'Scan:Stopped','Indicates when a table or index scan has stopped.')
, (53, 'CursorOpen','Indicates when a cursor is opened on a Transact-SQL statement by ODBC, OLE DB, or DB-Library.')
, (54, 'TransactionLog','Tracks when transactions are written to the transaction log.')
, (55, 'Hash Warning','Indicates that a hashing operation (for example, hash join, hash aggregate, hash union, and hash distinct) that is not processing on a buffer partition has reverted to an alternate plan. This can occur because of recursion depth, data skew, trace flags, or bit counting.')
, (56, 'Reserved','')
, (57, 'Reserved','')
, (58, 'Auto Stats','Indicates an automatic updating of index statistics has occurred.')
, (59, 'Lock:Deadlock Chain','Produced for each of the events leading up to the deadlock.')
, (60, 'Lock:Escalation','Indicates that a finer-grained lock has been converted to a coarser-grained lock (for example, a page lock escalated or converted to a TABLE or HoBT lock).')
, (61, 'OLE DB Errors','Indicates that an OLE DB error has occurred.')
, (62, 'Reserved','')
, (63, 'Reserved','')
, (64, 'Reserved','')
, (65, 'Reserved','')
, (66, 'Reserved','')
, (67, 'Execution Warnings','Indicates any warnings that occurred during the execution of a SQL Server statement or stored procedure.')
, (68, 'Showplan Text (Unencoded)','Displays the plan tree of the Transact-SQL statement executed.')
, (69, 'Sort Warnings','Indicates sort operations that do not fit into memory. Does not include sort operations involving the creating of indexes; only sort operations within a query (such as an ORDER BY clause used in a SELECT statement).')
, (70, 'CursorPrepare','Indicates when a cursor on a Transact-SQL statement is prepared for use by ODBC, OLE DB, or DB-Library.')
, (71, 'Prepare SQL','ODBC, OLE DB, or DB-Library has prepared a Transact-SQL statement or statements for use.')
, (72, 'Exec Prepared SQL','ODBC, OLE DB, or DB-Library has executed a prepared Transact-SQL statement or statements.')
, (73, 'Unprepare SQL','ODBC, OLE DB, or DB-Library has unprepared (deleted) a prepared Transact-SQL statement or statements.')
, (74, 'CursorExecute','A cursor previously prepared on a Transact-SQL statement by ODBC, OLE DB, or DB-Library is executed.')
, (75, 'CursorRecompile','A cursor opened on a Transact-SQL statement by ODBC or DB-Library has been recompiled either directly or due to a schema change.Triggered for ANSI and non-ANSI cursors."')
, (76, 'CursorImplicitConversion','A cursor on a Transact-SQL statement is converted by SQL Server from one type to another.Triggered for ANSI and non-ANSI cursors."')
, (77, 'CursorUnprepare','A prepared cursor on a Transact-SQL statement is unprepared (deleted) by ODBC, OLE DB, or DB-Library.')
, (78, 'CursorClose','A cursor previously opened on a Transact-SQL statement by ODBC, OLE DB, or DB-Library is closed.')
, (79, 'Missing Column Statistics','Column statistics that could have been useful for the optimizer are not available.')
, (80, 'Missing Join Predicate','Query that has no join predicate is being executed. This could result in a long-running query.')
, (81, 'Server Memory Change','SQL Server memory usage has increased or decreased by either 1 megabyte (MB) or 5 percent of the maximum server memory, whichever is greater.')
, (82, 'User Configurable (0-9)','Event data defined by the user.')
, (83, 'User Configurable (0-9)','Event data defined by the user.')
, (84, 'User Configurable (0-9)','Event data defined by the user.')
, (85, 'User Configurable (0-9)','Event data defined by the user.')
, (86, 'User Configurable (0-9)','Event data defined by the user.')
, (87, 'User Configurable (0-9)','Event data defined by the user.')
, (88, 'User Configurable (0-9)','Event data defined by the user.')
, (89, 'User Configurable (0-9)','Event data defined by the user.')
, (90, 'User Configurable (0-9)','Event data defined by the user.')
, (91, 'User Configurable (0-9)','Event data defined by the user.')
, (92, 'Data File Auto Grow','Indicates that a data file was extended automatically by the server.')
, (93, 'Log File Auto Grow','Indicates that a log file was extended automatically by the server.')
, (94, 'Data File Auto Shrink','Indicates that a data file was shrunk automatically by the server.')
, (95, 'Log File Auto Shrink','Indicates that a log file was shrunk automatically by the server.')
, (96, 'Showplan Text','Displays the query plan tree of the SQL statement from the query optimizer. Note that the TextData column does not contain the Showplan for this event.')
, (97, 'Showplan All','Displays the query plan with full compile-time details of the SQL statement executed. Note that the TextData column does not contain the Showplan for this event.')
, (98, 'Showplan Statistics Profile','Displays the query plan with full run-time details of the SQL statement executed. Note that the TextData column does not contain the Showplan for this event.')
, (99, 'Reserved','')
, (100, 'RPC Output Parameter','Produces output values of the parameters for every RPC.')
, (101, 'Reserved','')
, (102, 'Audit Database Scope GDR','Occurs every time a GRANT, DENY, REVOKE for a statement permission is issued by any user in SQL Server for database-only actions such as granting permissions on a database.')
, (103, 'Audit Object GDR Event','Occurs every time a GRANT, DENY, REVOKE for an object permission is issued by any user in SQL Server.')
, (104, 'Audit AddLogin Event','Occurs when a SQL Server login is added or removed; for sp_addlogin and sp_droplogin.')
, (105, 'Audit Login GDR Event','Occurs when a Windows login right is added or removed; for sp_grantlogin, sp_revokelogin, and sp_denylogin.')
, (106, 'Audit Login Change Property Event','Occurs when a property of a login, except passwords, is modified; for sp_defaultdb and sp_defaultlanguage.')
, (107, 'Audit Login Change Password Event','Occurs when a SQL Server login password is changed.Passwords are not recorded.')
, (108, 'Audit Add Login to Server Role Event','Occurs when a login is added or removed from a fixed server role; for sp_addsrvrolemember, and sp_dropsrvrolemember.')
, (109, 'Audit Add DB User Event','Occurs when a login is added or removed as a database user (Windows or SQL Server) to a database; for sp_grantdbaccess, sp_revokedbaccess, sp_adduser, and sp_dropuser.')
, (110, 'Audit Add Member to DB Role Event','Occurs when a login is added or removed as a database user (fixed or user-defined) to a database; for sp_addrolemember, sp_droprolemember, and sp_changegroup.')
, (111, 'Audit Add Role Event','Occurs when a login is added or removed as a database user to a database; for sp_addrole and sp_droprole.')
, (112, 'Audit App Role Change Password Event','Occurs when a password of an application role is changed.')
, (113, 'Audit Statement Permission Event','Occurs when a statement permission (such as CREATE TABLE) is used.')
, (114, 'Audit Schema Object Access Event','Occurs when an object permission (such as SELECT) is used, both successfully or unsuccessfully.')
, (115, 'Audit Backup/Restore Event','Occurs when a BACKUP or RESTORE command is issued.')
, (116, 'Audit DBCC Event','Occurs when DBCC commands are issued.')
, (117, 'Audit Change Audit Event','Occurs when audit trace modifications are made.')
, (118, 'Audit Object Derived Permission Event','Occurs when a CREATE, ALTER, and DROP object commands are issued.')
, (119, 'OLEDB Call Event','Occurs when OLE DB provider calls are made for distributed queries and remote stored procedures.')
, (120, 'OLEDB QueryInterface Event','Occurs when OLE DB QueryInterface calls are made for distributed queries and remote stored procedures.')
, (121, 'OLEDB DataRead Event','Occurs when a data request call is made to the OLE DB provider.')
, (122, 'Showplan XML','Occurs when an SQL statement executes. Include this event to identify Showplan operators. Each event is stored in a well-formed XML document. Note that the Binary column for this event contains the encoded Showplan. Use SQL Server Profiler to open the trace and view the Showplan.')
, (123, 'SQL:FullTextQuery','Occurs when a full text query executes.')
, (124, 'Broker:Conversation','Reports the progress of a Service Broker conversation.')
, (125, 'Deprecation Announcement','Occurs when you use a feature that will be removed from a future version of SQL Server.')
, (126, 'Deprecation Final Support','Occurs when you use a feature that will be removed from the next major release of SQL Server.')
, (127, 'Exchange Spill Event','Occurs when communication buffers in a parallel query plan have been temporarily written to the tempdb database.')
, (128, 'Audit Database Management Event','Occurs when a database is created, altered, or dropped.')
, (129, 'Audit Database Object Management Event','Occurs when a CREATE, ALTER, or DROP statement executes on database objects, such as schemas.')
, (130, 'Audit Database Principal Management Event','Occurs when principals, such as users, are created, altered, or dropped from a database.')
, (131, 'Audit Schema Object Management Event','Occurs when server objects are created, altered, or dropped.')
, (132, 'Audit Server Principal Impersonation Event','Occurs when there is an impersonation within server scope, such as EXECUTE AS LOGIN.')
, (133, 'Audit Database Principal Impersonation Event','Occurs when an impersonation occurs within the database scope, such as EXECUTE AS USER or SETUSER.')
, (134, 'Audit Server Object Take Ownership Event','Occurs when the owner is changed for objects in server scope.')
, (135, 'Audit Database Object Take Ownership Event','Occurs when a change of owner for objects within database scope occurs.')
, (136, 'Broker:Conversation Group','Occurs when Service Broker creates a new conversation group or drops an existing conversation group.')
, (137, 'Blocked Process Report','Occurs when a process has been blocked for more than a specified amount of time. Does not include system processes or processes that are waiting on non deadlock-detectable resources. Use sp_configure to configure the threshold and frequency at which reports are generated.')
, (138, 'Broker:Connection','Reports the status of a transport connection managed by Service Broker.')
, (139, 'Broker:Forwarded Message Sent','Occurs when Service Broker forwards a message.')
, (140, 'Broker:Forwarded Message Dropped','Occurs when Service Broker drops a message that was intended to be forwarded.')
, (141, 'Broker:Message Classify','Occurs when Service Broker determines the routing for a message.')
, (142, 'Broker:Transmission','Indicates that errors have occurred in the Service Broker transport layer. The error number and state values indicate the source of the error.')
, (143, 'Broker:Queue Disabled','Indicates a poison message was detected because there were five consecutive transaction rollbacks on a Service Broker queue. The event contains the database ID and queue ID of the queue that contains the poison message.')
, (144, 'Reserved','')
, (145, 'Reserved','')
, (146, 'Showplan XML Statistics Profile','Occurs when an SQL statement executes. Identifies the Showplan operators and displays complete, compile-time data. Note that the Binary column for this event contains the encoded Showplan. Use SQL Server Profiler to open the trace and view the Showplan.')
, (148, 'Deadlock Graph','Occurs when an attempt to acquire a lock is canceled because the attempt was part of a deadlock and was chosen as the deadlock victim. Provides an XML description of a deadlock.')
, (149, 'Broker:Remote Message Acknowledgement','Occurs when Service Broker sends or receives a message acknowledgement.')
, (150, 'Trace File Close','Occurs when a trace file closes during a trace file rollover.')
, (151, 'Reserved','')
, (152, 'Audit Change Database Owner','Occurs when ALTER AUTHORIZATION is used to change the owner of a database and permissions are checked to do that.')
, (153, 'Audit Schema Object Take Ownership Event','Occurs when ALTER AUTHORIZATION is used to assign an owner to an object and permissions are checked to do that.')
, (154, 'Reserved','')
, (155, 'FT:Crawl Started','Occurs when a full-text crawl (population) starts. Use to check if a crawl request is picked up by worker tasks.')
, (156, 'FT:Crawl Stopped','Occurs when a full-text crawl (population) stops. Stops occur when a crawl completes successfully or when a fatal error occurs.')
, (157, 'FT:Crawl Aborted','Occurs when an exception is encountered during a full-text crawl. Usually causes the full-text crawl to stop.')
, (158, 'Audit Broker Conversation','Reports audit messages related to Service Broker dialog security.')
, (159, 'Audit Broker Login','Reports audit messages related to Service Broker transport security.')
, (160, 'Broker:Message Undeliverable','Occurs when Service Broker is unable to retain a received message that should have been delivered to a service.')
, (161, 'Broker:Corrupted Message','Occurs when Service Broker receives a corrupted message.')
, (162, 'User Error Message','Displays error messages that users see in the case of an error or exception.')
, (163, 'Broker:Activation','Occurs when a queue monitor starts an activation stored procedure, sends a QUEUE_ACTIVATION notification, or when an activation stored procedure started by a queue monitor exits.')
, (164, 'Object:Altered','Occurs when a database object is altered.')
, (165, 'Performance statistics','Occurs when a compiled query plan has been cached for the first time, recompiled, or removed from the plan cache.')
, (166, 'SQL:StmtRecompile','Occurs when a statement-level recompilation occurs.')
, (167, 'Database Mirroring State Change','Occurs when the state of a mirrored database changes.')
, (168, 'Showplan XML For Query Compile','Occurs when an SQL statement compiles. Displays the complete, compile-time data. Note that the Binary column for this event contains the encoded Showplan. Use SQL Server Profiler to open the trace and view the Showplan.')
, (169, 'Showplan All For Query Compile','Occurs when an SQL statement compiles. Displays complete, compile-time data. Use to identify Showplan operators.')
, (170, 'Audit Server Scope GDR Event','Indicates that a grant, deny, or revoke event for permissions in server scope occurred, such as creating a login.')
, (171, 'Audit Server Object GDR Event','Indicates that a grant, deny, or revoke event for a schema object, such as a table or function, occurred.')
, (172, 'Audit Database Object GDR Event','Indicates that a grant, deny, or revoke event for database objects, such as assemblies and schemas, occurred.')
, (173, 'Audit Server Operation Event','Occurs when Security Audit operations such as altering settings, resources, external access, or authorization are used.')
, (175, 'Audit Server Alter Trace Event','Occurs when a statement checks for the ALTER TRACE permission.')
, (176, 'Audit Server Object Management Event','Occurs when server objects are created, altered, or dropped.')
, (177, 'Audit Server Principal Management Event','Occurs when server principals are created, altered, or dropped.')
, (178, 'Audit Database Operation Event','Occurs when database operations occur, such as checkpoint or subscribe query notification.')
, (180, 'Audit Database Object Access Event','Occurs when database objects, such as schemas, are accessed.')
, (181, 'TM: Begin Tran starting','Occurs when a BEGIN TRANSACTION request starts.')
, (182, 'TM: Begin Tran completed','Occurs when a BEGIN TRANSACTION request completes.')
, (183, 'TM: Promote Tran starting','Occurs when a PROMOTE TRANSACTION request starts.')
, (184, 'TM: Promote Tran completed','Occurs when a PROMOTE TRANSACTION request completes.')
, (185, 'TM: Commit Tran starting','Occurs when a COMMIT TRANSACTION request starts.')
, (186, 'TM: Commit Tran completed','Occurs when a COMMIT TRANSACTION request completes.')
, (187, 'TM: Rollback Tran starting','Occurs when a ROLLBACK TRANSACTION request starts.')
, (188, 'TM: Rollback Tran completed','Occurs when a ROLLBACK TRANSACTION request completes.')
, (189, 'Lock:Timeout (timeout > 0)','Occurs when a request for a lock on a resource, such as a page, times out.')
, (190, 'Progress Report: Online Index Operation','Reports the progress of an online index build operation while the build process is running.')
, (191, 'TM: Save Tran starting','Occurs when a SAVE TRANSACTION request starts.')
, (192, 'TM: Save Tran completed','Occurs when a SAVE TRANSACTION request completes.')
, (193, 'Background Job Error','Occurs when a background job terminates abnormally.')
, (194, 'OLEDB Provider Information','Occurs when a distributed query runs and collects information corresponding to the provider connection.')
, (195, 'Mount Tape','Occurs when a tape mount request is received.')
, (196, 'Assembly Load','Occurs when a request to load a CLR assembly occurs.')
, (197, 'Reserved','')
, (198, 'XQuery Static Type','Occurs when an XQuery expression is executed. This event class provides the static type of the XQuery expression.')
, (199, 'QN: subscription','Occurs when a query registration cannot be subscribed. The TextData column contains information about the event.')
, (200, 'QN: parameter table','Information about active subscriptions is stored in internal parameter tables. This event class occurs when a parameter table is created or deleted. Typically, these tables are created or deleted when the database is restarted. The TextData column contains information about the event.')
, (201, 'QN: template','A query template represents a class of subscription queries. Typically, queries in the same class are identical except for their parameter values. This event class occurs when a new subscription request falls into an already existing class of (Match), a new class (Create), or a Drop class, which indicates cleanup of templates for query classes without active subscriptions. The TextData column contains information about the event.')
, (202, 'QN: dynamics','Tracks internal activities of query notifications. The TextData column contains information about the event.')
, (212, 'Bitmap Warning','Indicates when bitmap filters have been disabled in a query.')
, (213, 'Database Suspect Data Page','Indicates when a page is added to the suspect_pages table in msdb.')
, (214, 'CPU threshold exceeded','Indicates when the Resource Governor detects a query has exceeded the CPU threshold value (REQUEST_MAX_CPU_TIME_SEC).')
, (215, 'PreConnect:Starting','Indicates when a LOGON trigger or Resource Governor classifier function starts execution.')
, (216, 'PreConnect:Completed','Indicates when a LOGON trigger or Resource Governor classifier function completes execution.')
, (217, 'Plan Guide Successful','Indicates that SQL Server successfully produced an execution plan for a query or batch that contained a plan guide.')
, (218, 'Plan Guide Unsuccessful','Indicates that SQL Server could not produce an execution plan for a query or batch that contained a plan guide. SQL Server attempted to generate an execution plan for this query or batch without applying the plan guide. An invalid plan guide may be the cause of this problem. You can validate the plan guide by using the sys.fn_validate_plan_guide system function.')
, (235, 'Audit Fulltext','')



CREATE TABLE #objTypes ( ObjectType INT NOT NULL, ObjectDefinition VARCHAR(128) NULL)
INSERT INTO #objTypes (ObjectType, ObjectDefinition) VALUES(8259,'Check Constraint')
, (8260,'Default (constraint or standalone)')
, (8262,'Foreign-key Constraint')
, (8272,'Stored Procedure')
, (8274,'Rule')
, (8275,'System Table')
, (8276,'Trigger on Server')
, (8277,'(User-defined) Table')
, (8278,'View')
, (8280,'Extended Stored Procedure')
, (16724,'CLR Trigger')
, (16964,'Database')
, (16975,'Object')
, (17222,'FullText Catalog')
, (17232,'CLR Stored Procedure')
, (17235,'Schema')
, (17475,'Credential')
, (17491,'DDL Event')
, (17741,'Management Event')
, (17747,'Security Event')
, (17749,'User Event')
, (17985,'CLR Aggregate Function')
, (17993,'Inline Table-valued SQL Function')
, (18000,'Partition Function')
, (18002,'Replication Filter Procedure')
, (18004,'Table-valued SQL Function')
, (18259,'Server Role')
, (18263,'Microsoft Windows Group')
, (19265,'Asymmetric Key')
, (19277,'Master Key')
, (19280,'Primary Key')
, (19283,'ObfusKey')
, (19521,'Asymmetric Key Login')
, (19523,'Certificate Login')
, (19538,'Role')
, (19539,'SQL Login')
, (19543,'Windows Login')
, (20034,'Remote Service Binding')
, (20036,'Event Notification on Database')
, (20037,'Event Notification')
, (20038,'Scalar SQL Function')
, (20047,'Event Notification on Object')
, (20051,'Synonym')
, (20307,'Sequence')
, (20549,'End Point')
, (20801,'Adhoc Queries which may be cached')
, (20816,'Prepared Queries which may be cached')
, (20819,'Service Broker Service Queue')
, (20821,'Unique Constraint')
, (21057,'Application Role')
, (21059,'Certificate')
, (21075,'Server')
, (21076,'Transact-SQL Trigger')
, (21313,'Assembly')
, (21318,'CLR Scalar Function')
, (21321,'Inline scalar SQL Function')
, (21328,'Partition Scheme')
, (21333,'User')
, (21571,'Service Broker Service Contract')
, (21572,'Trigger on Database')
, (21574,'CLR Table-valued Function')
, (21577,'Internal Table (For example, XML Node Table, Queue Table.)')
, (21581,'Service Broker Message Type')
, (21586,'Service Broker Route')
, (21587,'Statistics')
, (21825,'User')
, (21827,'User')
, (21831,'User')
, (21843,'User')
, (21847,'User')
, (22099,'Service Broker Service')
, (22601,'Index')
, (22604,'Certificate Login')
, (22611,'XMLSchema')
, (22868,'Type')


-- =============================================
-- Edit from here
-- =============================================

USE [master]
GO

IF OBJECT_ID('tempdb..#trace')		IS NOT NULL DROP TABLE #trace

BEGIN TRY
    IF (SELECT CONVERT(INT,value_in_use) FROM sys.configurations WHERE NAME = 'default trace enabled') = 1
    BEGIN
        
		DECLARE @EventClass INT = NULL
		DECLARE @ObjectType INT = NULL
		DECLARE @DatabaseName SYSNAME --= 'party'
		
		
		DECLARE @curr_tracefilename VARCHAR(500);
        DECLARE @base_tracefilename VARCHAR(500);
        DECLARE @indx INT;

        SELECT @curr_tracefilename = path FROM sys.traces WHERE is_default = 1;
        SET @curr_tracefilename = REVERSE(@curr_tracefilename);
        SELECT @indx  = PATINDEX('%\%', @curr_tracefilename) ;
        SET @curr_tracefilename = REVERSE(@curr_tracefilename) ;
        SET @base_tracefilename = LEFT( @curr_tracefilename,LEN(@curr_tracefilename) - @indx) + '\log.trc'; 
        
		SELECT * 
		INTO #trace
		FROM ::fn_trace_gettable(@base_tracefilename, default)  AS t
		WHERE t.ServerName = @@SERVERNAME
			AND (t.EventClass = @EventClass OR @EventClass IS NULL)
			AND (t.ObjectType = @ObjectType OR @ObjectType IS NULL)
			AND (t.DatabaseName = @DatabaseName OR @DatabaseName IS NULL)
		
		SELECT t.ServerName AS [SQL_Instance]
				, CONVERT(VARCHAR(50),t.StartTime, 100) AS [Start_Time]
				, t.EventClass
				, e.EventName
				, t.ObjectType
				, t.ObjectName
				, t.DatabaseId
				, t.DatabaseName
				, e.EventDescription
				, o.ObjectDefinition
				, t.LoginName
				, t.ApplicationName
				, t.HostName
				, t.TextData
				--, *
        FROM #trace AS t
		LEFT JOIN #events AS e
		ON e.EventClass = t.EventClass	
		LEFT JOIN #objTypes AS o
			ON o.ObjectType = t.ObjectType        

        ORDER BY t.StartTime DESC;  
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
