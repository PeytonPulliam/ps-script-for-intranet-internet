	<#
	.SYNOPSIS
	Schedules a program to run automatically every 30 minutes.
	 
	.DESCRIPTION
	This function uses the Windows Task Scheduler to create a task that runs a specified program at a defined interval.
	 
	.PARAMETER programPath
	The full path to the executable or script that needs to be scheduled.
	 
	.PARAMETER taskName
	The name of the scheduled task.
	 
	.PARAMETER taskDescription
	A description for the scheduled task.
	 
	.EXAMPLE
	Schedule-Program "C:\Path\To\YourProgram.exe" "MyScheduledTask" "This task runs my program every 30 minutes."
	Creates a scheduled task named "MyScheduledTask" that runs "YourProgram.exe" every 30 minutes.
	 
	.NOTES
	Requires administrative privileges to create a scheduled task.
	#>
	function SchedulizerTask {
	    param (
	        [string]$programPath,
	        [string]$taskName,
	        [string]$taskDescription
	    )
	 
	    # Validate the program path
	    if (-Not (Test-Path $programPath)) {
	        Write-Output "The specified program path does not exist: $programPath"
	        return
	    }
	 
	    # Define the action for the scheduled task
	    $action = New-ScheduledTaskAction -Execute $programPath
	 
	    # Define the trigger for the scheduled task to run every 30 minutes
	    $trigger = New-ScheduledTaskTrigger -AtStartup -RepeatInterval (New-TimeSpan -Minutes 30) -RepeatIndefinitely
	 
	    # Define the principal for the scheduled task (run with highest privileges)
	    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
	 
	    # Create the scheduled task
	    $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Description $taskDescription -TaskName $taskName
	 
	    # Register the scheduled task in the Task Scheduler
	    Register-ScheduledTask -InputObject $task
	 
	    Write-Output "Scheduled task '$taskName' has been created to run '$programPath' every 30 minutes."
	}
	 
	# Example usage of the Schedule-Program function
	# Schedule-Program "C:\Path\To\YourProgram.exe" "MyScheduledTask" "This task runs my program every 30 minutes."