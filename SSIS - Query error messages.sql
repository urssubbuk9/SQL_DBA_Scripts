/* =========================================
		Date: 12/11/2017
	Last Modified: 31/05/2018
	Queries SSIS to return error messages from package executions.
   ========================================= */

USE SSISDB;
SELECT OPR.object_name
            , MSG.message_time
            , MSG.message

FROM catalog.operation_messages  AS MSG
    INNER JOIN catalog.operations          AS OPR
    ON      OPR.operation_id            = MSG.operation_id
WHERE       MSG.message_type            = 120
order by message_time desc
