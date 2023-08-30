SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Description:	Healthcheck: Check if there are databases that use enterprise features
--
-- Parameters:
--
-- Log History:	
--
-- =============================================

CREATE TABLE #features(
		database_id		INT
		, feature_name	SYSNAME
	)

EXEC sp_MSforeachdb N'
	USE [?];

	INSERT INTO #features
		SELECT DB_ID() AS database_id, feature_name FROM sys.dm_db_persisted_sku_features;
';

SELECT d.database_id, d.name
		, STUFF((SELECT ', ' + feature_name FROM #features AS f
					WHERE f.database_id = d.database_id
					FOR XML PATH('')),1,2,'') AS EE_Features
	FROM sys.databases AS d
	WHERE EXISTS (SELECT 1 FROM #features WHERE database_id = d.database_id);
GO
