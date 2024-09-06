
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
	 
	# Schedule-Program "C:\Path\To\YourProgram.exe" "MyScheduledTask" "This task runs my program every 30 minutes."
