use ssisdb
set nocount on

-- select * from catalog.catalog_properties where property_name = 'RETENTION_WINDOW'

declare @target int = 14
declare @current int

select @current = property_value
from catalog.catalog_properties
where property_name = 'RETENTION_WINDOW'

while @current > @target
begin
	set @current -= 1

	raiserror('Reducing retention to %d', 0, 1, @current) with nowait

	exec catalog.configure_catalog 'RETENTION_WINDOW', @current
	exec internal.cleanup_server_retention_window
end
