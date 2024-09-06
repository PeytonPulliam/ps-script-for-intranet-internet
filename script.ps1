# Install Speedtest CLI by Ookla
Invoke-WebRequest -Uri https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip -OutFile "$env:TEMP\speedtest.zip"
Expand-Archive -Path "$env:TEMP\speedtest.zip" -DestinationPath "$env:ProgramFiles\Speedtest" -Force
$SpeedtestPath = "$env:ProgramFiles\Speedtest\speedtest.exe"

# Add Speedtest to the system PATH
$env:Path += ";$env:ProgramFiles\Speedtest"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Machine)

# Create a directory for the Speedtest results
$ResultsDirectory = "$env:USERPROFILE\SpeedtestResults"
if (!(Test-Path $ResultsDirectory)) {
    New-Item -ItemType Directory -Path $ResultsDirectory
}

# PowerShell script to run Speedtest and save the output with timestamp, converting bytes to megabytes
$ScriptContent = @"
`$SpeedtestPath = '$SpeedtestPath'
`$ResultsDirectory = '$ResultsDirectory'
`$Timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
`$SpeedtestResultRaw = & `$SpeedtestPath --format=json | ConvertFrom-Json

# Convert bytes to megabits for download and upload speeds
`$SpeedtestResultRaw.download.bandwidth = [math]::round((`$SpeedtestResultRaw.download.bandwidth * 8) / 1MB, 2)
`$SpeedtestResultRaw.upload.bandwidth = [math]::round((`$SpeedtestResultRaw.upload.bandwidth * 8) / 1MB, 2)

# Convert ping to milliseconds
`$SpeedtestResultRaw.ping.latency = [math]::round(`$SpeedtestResultRaw.ping.latency, 2)

# Add timestamp to the results
`$SpeedtestResultRaw | Add-Member -MemberType NoteProperty -Name Timestamp -Value `$Timestamp

# Save the result as a JSON file
`$SpeedtestResultRaw | ConvertTo-Json | Set-Content -Path "`$ResultsDirectory\SpeedtestResult_`$Timestamp.json"
"@

# Save the script to a .ps1 file
$SpeedtestScript = "$ResultsDirectory\RunSpeedtest.ps1"
Set-Content -Path $SpeedtestScript -Value $ScriptContent

# Create a Scheduled Task to run the script every minute
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -File `"$SpeedtestScript`""
$Trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 1) -RepeatIndefinitely -At (Get-Date).AddMinutes(1)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -TaskName "SpeedtestEveryMinute" -Description "Run Speedtest every minute and save results as JSON"

Write-Host "Speedtest CLI installed, scheduled task created, and results will be saved in $ResultsDirectory"
