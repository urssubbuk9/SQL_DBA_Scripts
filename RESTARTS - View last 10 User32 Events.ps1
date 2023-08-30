<# Title/Name: Query Restarts
Creation Date:
Description:
Notes:Show the last 10 restarts of the server
#>
Get-EventLog System -Newest 10 -Source User32 | Select-Object TimeGenerated, Message | Format-Table -AutoSize -Wrap
