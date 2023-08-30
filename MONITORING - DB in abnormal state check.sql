-- ===========================================================================
-- Description:	Script to check DB statuses
-- ===========================================================================

SELECT name
	,state_desc
FROM sys.databases
WHERE state_desc = 'OFFLINE'

IF (@@ROWCOUNT > 0)
BEGIN
	RAISERROR (
			'A DB is currently OFFLINE or in a abnormal state, please investigate.'
			,16
			,1
			)
END
ELSE
	SELECT name
		,state_desc
	FROM sys.databases
	WHERE state_desc = 'RESTORING'

IF (@@ROWCOUNT > 0)
BEGIN
	RAISERROR (
			'A DB is currently RESTORING or in a abnormal state, please investigate.'
			,16
			,1
			)
END
ELSE
	SELECT name
		,state_desc
	FROM sys.databases
	WHERE state_desc = 'RECOVERING'

IF (@@ROWCOUNT > 0)
BEGIN
	RAISERROR (
			'A DB is currently RECOVERING or in a abnormal state, please investigate.'
			,16
			,1
			)
END
ELSE
	SELECT name
		,state_desc
	FROM sys.databases
	WHERE state_desc = 'RECOVERY PENDING'

IF (@@ROWCOUNT > 0)
BEGIN
	RAISERROR (
			'A DB is currently RECOVERY PENDING or in a abnormal state, please investigate.'
			,16
			,1
			)
END
ELSE
	SELECT name
		,state_desc
	FROM sys.databases
	WHERE state_desc = 'SUSPECT'

IF (@@ROWCOUNT > 0)
BEGIN
	RAISERROR (
			'A DB is currently SUSPECT or in an abnormal state, please investigate.'
			,16
			,1
			)
END
ELSE
	SELECT name
		,state_desc
	FROM sys.databases
	WHERE state_desc = 'EMERGENCY'

IF (@@ROWCOUNT > 0)
BEGIN
	RAISERROR (
			'A DB is currently in EMERGENCY or in an abnormal state, please investigate.'
			,16
			,1
			)
END
ELSE
	SELECT name
		,state_desc
	FROM sys.databases
	WHERE state_desc NOT IN (
			'EMERGENCY'
			,'SUSPECT'
			,'RECOVERY PENDING'
			,'RECOVERING'
			,'RESTORING'
			,'OFFLINE'
			,'ONLINE'
			)

IF (@@ROWCOUNT > 0)
BEGIN
	RAISERROR (
			'A DB is currently in an unknown state, please investigate.'
			,16
			,1
			)
END
