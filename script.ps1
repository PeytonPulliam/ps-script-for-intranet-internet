# Install Speedtest CLI by Ookla if not already installed
$SpeedtestPath = "$env:ProgramFiles\Speedtest\speedtest.exe"
if (!(Test-Path $SpeedtestPath)) {
    Invoke-WebRequest -Uri https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip -OutFile "$env:TEMP\speedtest.zip"
    Expand-Archive -Path "$env:TEMP\speedtest.zip" -DestinationPath "$env:ProgramFiles\Speedtest" -Force
}


}

# Run Speedtest CLI and process the result
$SpeedtestResultRaw = & "$SpeedtestPath" --format=json | ConvertFrom-Json

# Convert bandwidth from bytes to megabits (Mbps)
$DownloadMbps = [math]::round(($SpeedtestResultRaw.download.bandwidth * 8) / 1MB, 2)
$UploadMbps = [math]::round(($SpeedtestResultRaw.upload.bandwidth * 8) / 1MB, 2)
$Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'


Write-Host "Speedtest result appended to Google Sheets"
