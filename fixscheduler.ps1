# Step 1: Install Speedtest CLI by Ookla
$SpeedtestPath = "$env:ProgramFiles\Speedtest\speedtest.exe"
if (!(Test-Path $SpeedtestPath)) {
    Write-Host "Downloading and installing Speedtest CLI..."
    Invoke-WebRequest -Uri https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip -OutFile "$env:TEMP\speedtest.zip"
    Expand-Archive -Path "$env:TEMP\speedtest.zip" -DestinationPath "$env:ProgramFiles\Speedtest" -Force
    Write-Host "Speedtest CLI installed at $SpeedtestPath"
}

# Step 2: Add Speedtest to the system PATH if not already present
if ($env:Path -notlike "*$env:ProgramFiles\Speedtest*") {
    $env:Path += ";$env:ProgramFiles\Speedtest"
    [Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Machine)
}

# Step 3: Create a directory for Speedtest results if it doesn't exist
$ResultsDirectory = "$env:USERPROFILE\SpeedtestResults"
if (!(Test-Path $ResultsDirectory)) {
    New-Item -ItemType Directory -Path $ResultsDirectory
    Write-Host "Created results directory: $ResultsDirectory"
}

# Step 4: Create the PowerShell script to run Speedtest and save results
$SpeedtestScriptContent = @"
`$SpeedtestPath = '$SpeedtestPath'
`$ResultsDirectory = '$ResultsDirectory'
`$Timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
`$SpeedtestResultRaw = & `$SpeedtestPath --format=json | ConvertFrom-Json

# Convert bytes to megabits for download and upload speeds
`$SpeedtestResultRaw.download.bandwidth = [math]::round((`$SpeedtestResultRaw.download.bandwidth * 8) / 1MB, 2)
`$SpeedtestResultRaw.upload.bandwidth = [math]::round((`$SpeedtestResultRaw.upload.bandwidth * 8) / 1MB, 2)

# Convert ping to milliseconds
`$SpeedtestResultRaw.ping.latency = [math]::round(`$SpeedtestResultRaw.ping.latency, 2)

# Add or overwrite timestamp to the results
`$SpeedtestResultRaw | Add-Member -MemberType NoteProperty -Name Timestamp -Value `$Timestamp -Force

# Save the result as a JSON file
`$SpeedtestResultRaw | ConvertTo-Json | Set-Content -Path "`$ResultsDirectory\SpeedtestResult_`$Timestamp.json"
"@

$SpeedtestScriptPath = "$ResultsDirectory\RunSpeedtest.ps1"
Set-Content -Path $SpeedtestScriptPath -Value $SpeedtestScriptContent
Write-Host "Speedtest script created at $SpeedtestScriptPath"

# Step 5: Create a Scheduled Task to run the Speedtest script every minute

# Clear existing task if it exists
if (Get-ScheduledTask -TaskName "SpeedtestEveryMinute" -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName "SpeedtestEveryMinute" -Confirm:$false
    Write-Host "Existing scheduled task cleared."
}

# Create the new scheduled task
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$SpeedtestScriptPath`""
$Trigger = New-ScheduledTaskTrigger -AtStartup -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-TimeSpan -Days 365)
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopOnIdleEnd -StartIfIdle

# Register the scheduled task
Register-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -TaskName "SpeedtestEveryMinute" -Description "Run Speedtest every minute and save results as JSON" -User "SYSTEM" -RunLevel Highest

Write-Host "Scheduled task created to run every minute."
