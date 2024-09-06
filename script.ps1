# Install Speedtest CLI by Ookla if not already installed
$SpeedtestPath = "$env:ProgramFiles\Speedtest\speedtest.exe"
if (!(Test-Path $SpeedtestPath)) {
    Invoke-WebRequest -Uri https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip -OutFile "$env:TEMP\speedtest.zip"
    Expand-Archive -Path "$env:TEMP\speedtest.zip" -DestinationPath "$env:ProgramFiles\Speedtest" -Force
}

# Import Google Sheets API libraries (ensure these are installed)
Import-Module Google.Apis.Sheets.v4
Import-Module Google.Apis.Auth

# Define Google API credentials and Spreadsheet info
$serviceAccountFile = "C:\path\to\your\service-account-file.json"
$spreadsheetId = "your-spreadsheet-id"  # Replace with your Spreadsheet ID
$range = "Sheet1!A:C"  # Replace with your desired sheet and range

# Load the Google credentials
$credentials = [Google.Apis.Auth.OAuth2.GoogleCredential]::FromFile($serviceAccountFile).CreateScoped("https://www.googleapis.com/auth/spreadsheets")

# Initialize the Sheets API service
$initializer = New-Object Google.Apis.Services.BaseClientService+Initializer
$initializer.HttpClientInitializer = $credentials
$initializer.ApplicationName = "Speedtest Results"
$service = New-Object Google.Apis.Sheets.v4.SheetsService($initializer)

# Function to append data to Google Sheets
function Append-SpeedtestResultToGoogleSheets {
    param (
        [string]$Timestamp,
        [double]$DownloadMbps,
        [double]$UploadMbps
    )

    $values = New-Object 'Collections.Generic.List[Object[]]'
    $values.Add((@($Timestamp, $DownloadMbps, $UploadMbps)))

    $requestBody = New-Object Google.Apis.Sheets.v4.Data.ValueRange
    $requestBody.Values = $values

    $request = $service.Spreadsheets.Values.Append($requestBody, $spreadsheetId, $range)
    $request.ValueInputOption = "RAW"
    $request.Execute() | Out-Null
}

# Run Speedtest CLI and process the result
$SpeedtestResultRaw = & "$SpeedtestPath" --format=json | ConvertFrom-Json

# Convert bandwidth from bytes to megabits (Mbps)
$DownloadMbps = [math]::round(($SpeedtestResultRaw.download.bandwidth * 8) / 1MB, 2)
$UploadMbps = [math]::round(($SpeedtestResultRaw.upload.bandwidth * 8) / 1MB, 2)
$Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

# Append the result to Google Sheets
Append-SpeedtestResultToGoogleSheets -Timestamp $Timestamp -DownloadMbps $DownloadMbps -UploadMbps $UploadMbps

Write-Host "Speedtest result appended to Google Sheets"
